# Команда для запуску: powershell -ExecutionPolicy Bypass -File "D:\Scripts\Backup_1C.ps1"

# --- ПАРАМЕТРИ, ЯКІ МОЖНА ЗМІНЮВАТИ ---
$OneCExePath      = "C:\Program Files\BAF\8.3.18.1627\bin\1cv8.exe"    # шлях до 1cv8.exe
$BasePath         = "D:\1C\Aristo"                                    # шлях до файлової бази
$BackupDir        = "D:\TMP"                                          # куди зберігати копії
$LogFile          = "D:\TMP\backup_log.txt"                           # шлях до лог-файлу
$UserAccount      = "Master"                                          # користувач, від якого запускається (для 1С не використовується, але залишено)
$KeepDays         = 7                                                 # скільки днів зберігати резерви
$TimeoutSeconds   = 60                                                # час очікування завершення користувачів
$EnableArchive    = $true                                             # true = стискати у ZIP
$RemoveOriginal   = $true                                             # true = видалити .dt після архівації
$MinFreeSpaceMB   = 2000                                              # мінімальний вільний простір у MB
# ----------------------------

# --- СЛУЖБОВІ ЗМІННІ ---
$DateStamp      = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile     = Join-Path $BackupDir "Aristo_$DateStamp.dt"
$ZipFile        = "$BackupFile.zip"
$OneCTempLog    = Join-Path $env:TEMP "1c_temp_log_$DateStamp.txt" # Тимчасовий лог для виводу 1С
$LogHeader      = "==== $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss') - Початок резервного копіювання ===="
Add-Content -Path $LogFile -Value "`r`n$LogHeader"

# Функція для логування виводу 1С та очищення тимчасового лога
function Log-OneCOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TempLogPath,
        [Parameter(Mandatory=$true)]
        [string]$MainLogPath
    )
    if (Test-Path $TempLogPath) {
        Add-Content -Path $MainLogPath -Value "--- Вивід 1С: ---"
        Add-Content -Path $MainLogPath -Value (Get-Content $TempLogPath) -ErrorAction SilentlyContinue
        Remove-Item $TempLogPath -Force -ErrorAction SilentlyContinue
    }
}

# --- Перевірка наявності достатнього місця на диску ---
Add-Content -Path $LogFile -Value "Перевірка вільного місця..."
$drive = Get-PSDrive -Name ($BackupDir.Substring(0,1)) -ErrorAction Stop
$freeMB = [math]::Round($drive.Free / 1MB)
if ($freeMB -lt $MinFreeSpaceMB) {
    Add-Content -Path $LogFile -Value "КРИТИЧНА ПОМИЛКА: Недостатньо місця на диску ($freeMB MB, потрібно $MinFreeSpaceMB MB)"
    exit 1
}
Add-Content -Path $LogFile -Value "Достатньо місця ($freeMB MB)."

# --- Створення каталогу для резервів, якщо його немає ---
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Add-Content -Path $LogFile -Value "Створено каталог резервів: $BackupDir"
}

# 1. --- Завершення роботи користувачів ---
Add-Content -Path $LogFile -Value "Завершення сеансів користувачів (таймаут $TimeoutSeconds сек)..."
$argumentsStop = @("DESIGNER", "/F", $BasePath, "/ForceShutdown", $TimeoutSeconds, "/DisableStartupDialogs", "/Out", $OneCTempLog)
& $OneCExePath $argumentsStop
Log-OneCOutput -TempLogPath $OneCTempLog -MainLogPath $LogFile

if ($LASTEXITCODE -ne 0) {
    Add-Content -Path $LogFile -Value "ПОМИЛКА: Команда ForceShutdown завершилась з кодом $LASTEXITCODE. Продовження..."
    # Продовжуємо, оскільки ForceShutdown може повернути помилку, якщо були активні сеанси.
}

# 2. --- Вивантаження бази (.dt) ---
Add-Content -Path $LogFile -Value "Початок вивантаження бази (.dt)..."
$argumentsBackup = @("DESIGNER", "/F", $BasePath, "/DumpIB", $BackupFile, "/DisableStartupDialogs", "/Out", $OneCTempLog)
& $OneCExePath $argumentsBackup
Log-OneCOutput -TempLogPath $OneCTempLog -MainLogPath $LogFile

# --- Перевірка результату вивантаження ---
if ($LASTEXITCODE -ne 0) {
    Add-Content -Path $LogFile -Value "КРИТИЧНА ПОМИЛКА: Вивантаження бази 1С завершилося з кодом помилки: $LASTEXITCODE."
    exit 2
}
if (Test-Path $BackupFile) {
    $FileSizeMB = [math]::Round((Get-Item $BackupFile).Length / 1MB)
    Add-Content -Path $LogFile -Value "Резервна копія створена успішно: $BackupFile ($FileSizeMB MB)."
} else {
    Add-Content -Path $LogFile -Value "КРИТИЧНА ПОМИЛКА: Файл резервної копії не знайдено, незважаючи на успішний код завершення 1С."
    exit 3
}

# 3. --- Дозвіл роботи користувачів після копіювання ---
Add-Content -Path $LogFile -Value "Дозвіл роботи користувачів..."
$argumentsStart = @("DESIGNER", "/F", $BasePath, "/AllowStartup", "/DisableStartupDialogs", "/Out", $OneCTempLog)
& $OneCExePath $argumentsStart
Log-OneCOutput -TempLogPath $OneCTempLog -MainLogPath $LogFile

if ($LASTEXITCODE -ne 0) {
    Add-Content -Path $LogFile -Value "ПОПЕРЕДЖЕННЯ: Команда AllowStartup завершилась з кодом $LASTEXITCODE."
}

# 4. --- Архівація резервної копії ---
if ($EnableArchive -eq $true -and (Test-Path $BackupFile)) {
    Add-Content -Path $LogFile -Value "Стискання резервної копії..."
    try {
        Compress-Archive -Path $BackupFile -DestinationPath $ZipFile -Force
        $ZipSizeMB = [math]::Round((Get-Item $ZipFile).Length / 1MB)
        Add-Content -Path $LogFile -Value "Створено архів: $ZipFile ($ZipSizeMB MB)"

        if ($RemoveOriginal -eq $true) {
            Remove-Item $BackupFile -Force
            Add-Content -Path $LogFile -Value "Видалено оригінальний файл: $BackupFile"
        }
    } catch {
        Add-Content -Path $LogFile -Value "ПОМИЛКА архівації: $($_.Exception.Message)"
    }
}

# 5. --- Видалення старих резервних копій ---
#Add-Content -Path $LogFile -Value "Очищення старих резервів (старше $KeepDays днів)..."
#$Limit = (Get-Date).AddDays(-$KeepDays)

#$OldFiles = Get-ChildItem -Path $BackupDir -Include *.dt, *.zip -File -ErrorAction SilentlyContinue |
#    Where-Object { $_.LastWriteTime -lt $Limit }

#if ($OldFiles.Count -gt 0) {
#    $OldFiles | ForEach-Object {
#        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
#        Add-Content -Path $LogFile -Value "Видалено старий файл: $($_.Name)"
#    }
#} else {
#    Add-Content -Path $LogFile -Value "Старих файлів для видалення не знайдено."
#}


# --- Завершення ---
$LogFooter = "==== $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss') - Резервне копіювання завершено ===="
Add-Content -Path $LogFile -Value $LogFooter

Write-Host "Резервне копіювання завершено. Лог: $LogFile"
