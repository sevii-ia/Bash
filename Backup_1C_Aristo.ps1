# Команда для запуску: powershell -ExecutionPolicy Bypass -File "D:\Scripts\Backup_1C.ps1"

# --- ПАРАМЕТРИ, ЯКІ МОЖНА ЗМІНЮВАТИ ---
$OneCExePath      = "C:\Program Files\BAF\8.3.18.1627\bin\1cv8.exe"  # шлях до 1cv8.exe
$BasePath         = "D:\1C\Aristo"                                   # шлях до файлової бази
$BackupDir        = "D:\TMP"                                         # куди зберігати копії
$LogFile          = "D:\TMP\backup_log.txt"                          # шлях до лог-файлу
$UserAccount      = "Master"                                         # користувач, від якого запускається
$KeepDays         = 7                                                # скільки днів зберігати резерви
$TimeoutSeconds   = 60                                               # час очікування завершення користувачів
$EnableArchive    = $true                                            # true = стискати у ZIP
$RemoveOriginal   = $true                                            # true = видалити .dt після архівації
$MinFreeSpaceMB   = 2000                                             # мінімальний вільний простір у MB
# ----------------------------

# --- СЛУЖБОВІ ЗМІННІ ---
$DateStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = Join-Path $BackupDir "Aristo_$DateStamp.dt"
$ZipFile    = "$BackupFile.zip"
$LogHeader  = "==== $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss') - Початок резервного копіювання ===="
Add-Content -Path $LogFile -Value "`r`n$LogHeader"

# --- Перевірка наявності достатнього місця на диску ---
$drive = Get-PSDrive -Name ($BackupDir.Substring(0,1))
$freeMB = [math]::Round($drive.Free / 1MB)
if ($freeMB -lt $MinFreeSpaceMB) {
    Add-Content -Path $LogFile -Value "Недостатньо місця на диску ($freeMB MB, потрібно $MinFreeSpaceMB MB)"
    exit 1
}

# --- Створення каталогу для резервів, якщо його немає ---
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Add-Content -Path $LogFile -Value "Створено каталог резервів: $BackupDir"
}

# --- Завершення роботи користувачів ---
Add-Content -Path $LogFile -Value "Завершення сеансів користувачів..."
$cmdStop = "`"$OneCExePath`" DESIGNER /F `"$BasePath`" /ForceShutdown $TimeoutSeconds /DisableStartupDialogs /Out `"$LogFile`""
Invoke-Expression $cmdStop

# --- Вивантаження бази (.dt) ---
Add-Content -Path $LogFile -Value "Початок вивантаження бази..."
$cmdBackup = "`"$OneCExePath`" DESIGNER /F `"$BasePath`" /DumpIB `"$BackupFile`" /DisableStartupDialogs /Out `"$LogFile`""
Invoke-Expression $cmdBackup

# --- Перевірка результату вивантаження ---
if (Test-Path $BackupFile) {
    Add-Content -Path $LogFile -Value "Резервна копія створена: $BackupFile"
} else {
    Add-Content -Path $LogFile -Value "Помилка: резервна копія не створена."
    exit 2
}

# --- Дозвіл роботи користувачів після копіювання ---
Add-Content -Path $LogFile -Value "Дозвіл роботи користувачів..."
$cmdStart = "`"$OneCExePath`" DESIGNER /F `"$BasePath`" /AllowStartup /DisableStartupDialogs /Out `"$LogFile`""
Invoke-Expression $cmdStart

# --- Архівація резервної копії ---
if ($EnableArchive -eq $true) {
    Add-Content -Path $LogFile -Value "Стискання резервної копії..."
    try {
        Compress-Archive -Path $BackupFile -DestinationPath $ZipFile -Force
        Add-Content -Path $LogFile -Value "Створено архів: $ZipFile"

        if ($RemoveOriginal -eq $true) {
            Remove-Item $BackupFile -Force
            Add-Content -Path $LogFile -Value "Видалено оригінальний файл: $BackupFile"
        }
    } catch {
        Add-Content -Path $LogFile -Value "Помилка архівації: $_"
    }
}

# --- Видалення старих резервних копій ---
#Add-Content -Path $LogFile -Value "Очищення старих резервів (старше $KeepDays днів)..."
#Get-ChildItem -Path $BackupDir -Include *.dt, *.zip -File | 
#    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$KeepDays) } |
#    ForEach-Object {
#        Remove-Item $_.FullName -Force
#        Add-Content -Path $LogFile -Value "Видалено старий файл: $($_.Name)"
#    }

# --- Завершення ---
$LogFooter = "==== $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss') - Резервне копіювання завершено успішно ===="
Add-Content -Path $LogFile -Value $LogFooter

Write-Host "Резервне копіювання завершено. Лог: $LogFile"
