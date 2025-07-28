# FiveM Server Update Scripts

Cross-platform scripts for automatically downloading and installing the latest FiveM server builds for Linux and Windows.

## Features

- 🔄 Automatic download of the latest FiveM server version
- �️ Cross-platform support (Linux + Windows)
- 📦 Multiple extraction methods with fallback support
- 🧹 Optional deletion of download files
- 🎯 Targeted version selection
- 🚀 Fully automated mode
- 🎨 Colored output with clear status messages
- ⚙️ Configurable paths
- 🛠️ Intelligent extraction method detection

## Installation

### Linux

1. Download the script:
```bash
wget https://github.com/JosefBernstein/fivem-server-updater/update_linux.sh
# or
curl -O https://github.com/JosefBernstein/fivem-server-updater/update_linux.sh
```

2. Make it executable:
```bash
chmod +x update_linux.sh
```

### Windows

1. Download the PowerShell script:
```powershell
# Download to current directory
Invoke-WebRequest -Uri "https://github.com/JosefBernstein/fivem-server-updater/update_windows.ps1" -OutFile "update_windows.ps1"
```

2. Allow script execution (if needed):
```powershell
# Run as Administrator if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage

### Basic Syntax

**Linux:**
```bash
./update_linux.sh [OPTIONS]
```

**Windows:**
```powershell
.\update_windows.ps1 [OPTIONS]
```

### Command Line Arguments

#### Linux (Bash Script)

| Argument | Short | Long | Description |
|----------|-------|------|-------------|
| `-e` | `-e` | `--extract` | Auto-extract files without prompt |
| `-d` | `-d` | `--delete` | Auto-delete download file without prompt |
| `-f` | `-f` | `--force` | Force download (skip version check) |
| `-ep` | `-ep` | `--extractpath <path>` | Override target directory for extracted files |
| `-dp` | `-dp` | `--downloadpath <path>` | Override download directory |
| `-v` | `-v` | `--version <number>` | Download specific version number |
| `-h` | `-h` | `--help` | Show help message |

**Combined Flags:** `-e`, `-d`, and `-f` can be combined (e.g., `-fed`, `-ed`, `-ef`).  
**Individual Flags:** `-ep`, `-dp`, `-v`, `-h` must be used separately as they require arguments.

#### Windows (PowerShell Script)

| Parameter | Description |
|-----------|-------------|
| `-Extract` | Auto-extract files without prompt |
| `-Delete` | Auto-delete download file without prompt |
| `-Force` | Force download (skip version check) |
| `-ExtractPath <path>` | Set extract directory (default: `.\fivem_server`) |
| `-DownloadPath <path>` | Set download directory (default: `.\fivem_download`) |
| `-Version <number>` | Download specific version number |
| `-Help` | Show help message |

**Note:** PowerShell parameters can be combined: `-Extract -Delete -Force`

## Examples

### Interactive Mode (Default)

**Linux:**
```bash
./update_linux.sh
```

**Windows:**
```powershell
.\update_windows.ps1
```
The script will prompt for each action (extract, delete).

### Fully Automated Mode

**Linux:**
```bash
./update_linux.sh -ed
# or
./update_linux.sh -e -d
```

**Windows:**
```powershell
.\update_windows.ps1 -Extract -Delete
```
Downloads, extracts automatically, and deletes the download file.

### Fully Automated with Force

**Linux:**
```bash
./update_linux.sh -fed
# equivalent to: -f -e -d
```

**Windows:**
```powershell
.\update_windows.ps1 -Force -Extract -Delete
```
Forces download, extracts, and deletes automatically.

### Download Specific Version

**Linux:**
```bash
./update_linux.sh -v 17300
```

**Windows:**
```powershell
.\update_windows.ps1 -Version 17300
```
Downloads version 17300 specifically.

### Specific Version with Force

**Linux:**
```bash
./update_linux.sh -v 17300 -fed
# or
./update_linux.sh -v 17300 -f -e -d
```

**Windows:**
```powershell
.\update_windows.ps1 -Version 17300 -Force -Extract -Delete
```
Downloads version 17300 even if already present, extracts and deletes automatically.

### Custom Paths

**Linux:**
```bash
./update_linux.sh -ep /opt/fivem -dp /tmp/downloads
```

**Windows:**
```powershell
.\update_windows.ps1 -ExtractPath "C:\FiveM\Server" -DownloadPath "C:\Temp\Downloads"
```
Extracts to custom directory and uses custom download directory.

### Combination of Multiple Options

**Linux:**
```bash
./update_linux.sh -v 17346 -ep /home/user/fivem -fed
```
- Downloads version 17346
- Extracts to `/home/user/fivem`
- Auto-extract, auto-delete, and force download

**Windows:**
```powershell
.\update_windows.ps1 -Version 17346 -ExtractPath "C:\FiveM" -Force -Extract -Delete
```
- Downloads version 17346
- Extracts to `C:\FiveM`
- Auto-extract, auto-delete, and force download

### Linux Combined Flags Only
```bash
./update_linux.sh -ef    # Force + Extract
./update_linux.sh -ed    # Extract + Delete
./update_linux.sh -fd    # Force + Delete
./update_linux.sh -fed   # Force + Extract + Delete
```

## Archive Format Support

### Linux Script (`update_linux.sh`)
- **Format:** `fx.tar.xz` (LZMA2 compressed tar)
- **URL:** `https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/`
- **Extraction:** Uses `tar` with xz support

### Windows Script (`update_windows.ps1`)
- **Format:** `server.7z` (7-Zip LZMA compressed)
- **URL:** `https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/`
- **Extraction Methods (in order of preference):**
  1. **Windows built-in tar** (Windows 10 1903+) - Skipped for 7z format
  2. **PowerShell .NET compression** - Limited 7z support
  3. **7-Zip** - Full support (fallback)
  4. **Manual extraction** - User guidance if all methods fail

## Default Directories

### Linux
| Purpose | Default Path | Override with |
|---------|--------------|---------------|
| Download | `./fivem_download` | `-dp / --downloadpath` |
| Extraction | `./fivem_server` | `-ep / --extractpath` |
| Version file | `./fivem_download/.version` | automatically with download path |

### Windows
| Purpose | Default Path | Override with |
|---------|--------------|---------------|
| Download | `.\fivem_download` | `-DownloadPath` |
| Extraction | `.\fivem_server` | `-ExtractPath` |
| Version file | `.\fivem_download\.version` | automatically with download path |

## Output Format

The script uses colored tags for better overview:

- 🔴 `[ERROR]` - Error messages
- 🟢 `[OK]` - Success messages  
- 🔵 `[INFO]` - Information
- 🟡 `[PROMPT]` - User prompts
- 🔵 `[SKIP]` - Skipped actions
- 🔵 `[KEEP]` - Kept files

## System Requirements

### Linux
- Linux (Debian, Ubuntu, CentOS, etc.)
- `curl` - for downloading
- `tar` with xz support - for extraction (only when extracting)
- `bash` 4.0 or higher

### Windows
- Windows 10 version 1903+ or Windows 11
- PowerShell 5.1 or higher (built-in)
- **Optional for extraction:**
  - 7-Zip (recommended)
  - Windows built-in tar (limited format support)
  - PowerShell .NET compression (basic support)

### Installing Dependencies

**Linux - Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install curl tar xz-utils
```

**Linux - CentOS/RHEL:**
```bash
sudo yum install curl tar xz
# or for newer versions:
sudo dnf install curl tar xz
```

**Windows - 7-Zip (recommended):**
```powershell
# Using Chocolatey
choco install 7zip

# Using winget
winget install 7zip.7zip

# Manual download from: https://www.7-zip.org/
```

## Error Handling

Both scripts automatically check:
- ✅ Availability of required tools (`curl`/`tar` for Linux, PowerShell for Windows)
- ✅ Internet connection to FiveM website
- ✅ Successful downloads
- ✅ Multiple extraction methods (Windows only)
- ✅ Successful extraction
- ✅ Valid version numbers

On errors, the scripts exit with appropriate error messages and suggestions.

### Windows Extraction Fallback
If 7-Zip is not available, the Windows script will:
1. Try Windows built-in tar (limited 7z support)
2. Try PowerShell .NET compression
3. Provide manual extraction instructions

## Automation

### Linux Cron Job for Regular Updates
```bash
# Daily at 3:00 AM automatic update
0 3 * * * /path/to/update_linux.sh -ed >/dev/null 2>&1

# Only download, don't extract
0 3 * * * /path/to/update_linux.sh >/dev/null 2>&1
```

### Windows Task Scheduler
```powershell
# Create a scheduled task for daily updates at 3:00 AM
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Path\To\update_windows.ps1 -Extract -Delete"
$Trigger = New-ScheduledTaskTrigger -Daily -At 3:00AM
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "FiveM Server Update" -Action $Action -Trigger $Trigger -Principal $Principal
```

### Linux Systemd Service
Create `/etc/systemd/system/fivem-update.service`:
```ini
[Unit]
Description=FiveM Server Update
After=network.target

[Service]
Type=oneshot
ExecStart=/path/to/update_linux.sh -ed
User=fivem
Group=fivem

[Install]
WantedBy=multi-user.target
```

## License

These scripts are available under the MIT License.

```
MIT License

Copyright (c) 2025 FiveM Server Update Scripts

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Support

For issues or questions, please create an issue in the repository or contact the developer.

## Files in this Repository

- `update_linux.sh` - Linux Bash script for FiveM server updates
- `update_windows.ps1` - Windows PowerShell script for FiveM server updates  
- `README.md` - This documentation file

Both scripts provide equivalent functionality across their respective platforms with platform-specific optimizations.
