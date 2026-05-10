# Bash Scripts

A collection of Bash scripts for Linux system administration, automation, and utility tasks.

## Table of Contents

* [Overview](#overview)
* [Repository Structure](#repository-structure)
* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Scripts](#scripts)
* [Examples](#examples)
* [Security Notes](#security-notes)
* [Contributing](#contributing)
* [License](#license)

---

## Overview

This repository contains a set of Bash scripts designed to simplify common Linux administration and automation tasks. The scripts focus on:

* IP address retrieval
* User management
* General Linux utility automation

The repository is intended for Linux users, system administrators, DevOps engineers, and anyone working frequently in terminal environments.

---

## Repository Structure

```bash
.
├── ip 24.04
├── ip.sh
├── usermanager
├── README.md
└── LICENSE
```

---

## Features

* Lightweight Bash utilities
* Simple command-line execution
* Linux-focused automation
* User management helpers
* Network/IP tools
* Easy to extend and customize

---

## Requirements

* Linux operating system
* Bash shell (`bash`)
* Standard GNU/Linux utilities

Optional:

* `curl`
* `iproute2`
* `sudo`

Install dependencies on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install bash curl iproute2
```

---

## Installation

Clone the repository:

```bash
git clone https://github.com/sevii-ia/Bash.git
```

Navigate into the project directory:

```bash
cd Bash
```

Make scripts executable:

```bash
chmod +x *.sh
chmod +x usermanager
```

---

## Usage

Run scripts directly from the terminal.

Example:

```bash
./ip.sh
```

Or:

```bash
bash ip.sh
```

---

## Scripts

### `ip.sh`

Utility script for retrieving and displaying IP-related information.

Possible functionality includes:

* Local IP detection
* Public IP retrieval
* Network interface inspection

Usage:

```bash
./ip.sh
```

---

### `ip 24.04`

Ubuntu 24.04 specific version or variant of the IP utility script.

Usage:

```bash
./"ip 24.04"
```

---

### `usermanager`

A user management utility script for Linux systems.

Potential features:

* Create users
* Delete users
* Modify user permissions
* Manage groups

Usage:

```bash
./usermanager
```

> Some operations may require `sudo` privileges.

---

## Examples

### Get Public IP

```bash
./ip.sh
```

Example output:

```bash
Public IP: 192.168.x.x
```

---

### Manage Users

```bash
sudo ./usermanager
```

---

## Security Notes

* Review scripts before executing them with elevated privileges.
* Avoid running unknown scripts as `root`.
* Validate user input in administrative scripts.

---

## Contributing

Contributions are welcome.

1. Fork the repository
2. Create a new feature branch

```bash
git checkout -b feature/my-feature
```

3. Commit your changes

```bash
git commit -m "Add new feature"
```

4. Push to your branch

```bash
git push origin feature/my-feature
```

5. Open a Pull Request

---

## License

This project is licensed under the MIT License.

See the [LICENSE](LICENSE) file for more information.
