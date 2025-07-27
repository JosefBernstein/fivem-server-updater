# FiveM Server Update Script for Windows
# PowerShell version of the Linux update script

param(
    [switch]$Extract,
    [switch]$Delete,
    [switch]$Force,
    [string]$Version,
    [string]$ExtractPath = ".\fivem_server",
    [string]$DownloadPath = ".\fivem_download",
    [switch]$Help
)

# Color definitions for console output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Write-Error-Message {
    param([string]$Message)
    Write-Host "[ERROR]  " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Success-Message {
    param([string]$Message)
    Write-Host "[OK]     " -ForegroundColor Green -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Info-Message {
    param([string]$Message)
    Write-Host "[INFO]   " -ForegroundColor Blue -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Prompt-Message {
    param([string]$Message)
    Write-Host "[PROMPT] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message -ForegroundColor White -NoNewline
}

function Write-Skip-Message {
    param([string]$Message)
    Write-Host "[SKIP]   " -ForegroundColor Cyan -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Keep-Message {
    param([string]$Message)
    Write-Host "[KEEP]   " -ForegroundColor Cyan -NoNewline
    Write-Host $Message -ForegroundColor White
}

# Show help message
if ($Help) {
    Write-ColorOutput "FiveM Server Update Script for Windows" "Green"
    Write-ColorOutput ""
    Write-ColorOutput "Usage: .\update_windows.ps1 [OPTIONS]" "White"
    Write-ColorOutput ""
    Write-ColorOutput "Options:" "Yellow"
    Write-ColorOutput "  -Extract              Auto-extract files without prompt" "White"
    Write-ColorOutput "  -Delete               Auto-delete download file without prompt" "White"
    Write-ColorOutput "  -Force                Force download (skip version check)" "White"
    Write-ColorOutput "  -ExtractPath PATH     Set extract directory (default: .\fivem_server)" "White"
    Write-ColorOutput "  -DownloadPath PATH    Set download directory (default: .\fivem_download)" "White"
    Write-ColorOutput "  -Version VERSION      Download specific version number" "White"
    Write-ColorOutput "  -Help                 Show this help message" "White"
    Write-ColorOutput ""
    Write-ColorOutput "Examples:" "Yellow"
    Write-ColorOutput "  .\update_windows.ps1                           Interactive mode" "White"
    Write-ColorOutput "  .\update_windows.ps1 -Extract -Delete          Auto-extract and auto-delete" "White"
    Write-ColorOutput "  .\update_windows.ps1 -Force -Extract -Delete   Force, extract, and delete" "White"
    Write-ColorOutput "  .\update_windows.ps1 -Version 17300 -Force     Download version 17300 and force overwrite" "White"
    Write-ColorOutput "  .\update_windows.ps1 -ExtractPath C:\FiveM     Extract to C:\FiveM" "White"
    exit 0
}

# Configuration
$BaseURL = "https://runtime.fivem.net/artifacts/fivem/build_server_windows/master/"
$ArchiveName = "server.7z"
$VersionFile = Join-Path $DownloadPath ".version"

# Create download directory
if (-not (Test-Path $DownloadPath)) {
    New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
}

# Function to download with progress
function Download-WithProgress {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    
    try {
        Write-Info-Message "Downloading from: $Url"
        
        # Use Invoke-WebRequest with better error handling
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -ErrorAction Stop
        
        # Verify file was downloaded and has content
        if ((Test-Path $OutputPath) -and (Get-Item $OutputPath).Length -gt 0) {
            return $true
        } else {
            return $false
        }
    }
    catch {
        Write-Error-Message "Download error: $($_.Exception.Message)"
        return $false
    }
}

# Get HTML from website
try {
    Write-Info-Message "Fetching available versions..."
    $html = Invoke-WebRequest -Uri $BaseURL -UseBasicParsing -ErrorAction Stop
}
catch {
    Write-Error-Message "Error fetching website: $($_.Exception.Message)"
    exit 1
}

# Extract build links using regex
$buildPattern = 'href="\.\/(\d+-[a-f0-9]+)\/server\.7z'
$matches = [regex]::Matches($html.Content, $buildPattern)

if ($matches.Count -eq 0) {
    Write-Error-Message "No build links found!"
    exit 1
}

# Extract build numbers and sort them
$buildLines = @()
foreach ($match in $matches) {
    $buildLines += $match.Groups[1].Value
}

# Remove duplicates and sort
$buildLines = $buildLines | Sort-Object -Unique

# Sort by build number (numeric part before dash) and get latest
if ($Version) {
    # Find specific version
    $latestBuild = $buildLines | Where-Object { $_ -match "^$Version-" } | Select-Object -First 1
    if (-not $latestBuild) {
        Write-Error-Message "Version $Version not found!"
        Write-Info-Message "Available versions:"
        $availableVersions = $buildLines | ForEach-Object { ($_ -split '-')[0] } | Sort-Object { [int]$_ } -Descending | Select-Object -First 10
        $availableVersions | ForEach-Object { Write-ColorOutput "  $_" "White" }
        exit 1
    }
}
else {
    # Get latest version by sorting numerically by the build number
    $latestBuild = $buildLines | Sort-Object { [int]($_ -split '-')[0] } -Descending | Select-Object -First 1
}

if (-not $latestBuild) {
    Write-Error-Message "Could not determine build number!"
    exit 1
}

# Check current local version
$currentBuild = ""
if (Test-Path $VersionFile) {
    $currentBuild = (Get-Content $VersionFile -Raw).Trim()
}

# Extract version number (everything before first dash)
$latestVersion = ($latestBuild -split '-')[0]
$currentVersion = ""
if ($currentBuild) {
    $currentVersion = ($currentBuild -split '-')[0]
}

if ($latestBuild -eq $currentBuild -and -not $Force) {
    Write-Success-Message "Latest version ($latestVersion) already available."
    exit 0
}

# Build download link
$downloadUrl = "${BaseURL}${latestBuild}/${ArchiveName}"
$downloadPath = Join-Path $DownloadPath $ArchiveName

Write-Info-Message "Downloading version $latestVersion..."

# Delete existing file if present
if (Test-Path $downloadPath) {
    Remove-Item $downloadPath -Force
}

# Download file
$downloadSuccess = Download-WithProgress $downloadUrl $downloadPath

if (-not $downloadSuccess -or -not (Test-Path $downloadPath)) {
    Write-Error-Message "Download failed!"
    exit 1
}

# Save version
Set-Content -Path $VersionFile -Value $latestBuild

Write-Success-Message "Download completed: $latestVersion"

# User prompt for extraction
$extractChoice = "N"
if ($Extract) {
    $extractChoice = "Y"
}
else {
    Write-Host ""
    Write-Prompt-Message "Extract files and overwrite existing files? (Y/N): "
    $extractChoice = Read-Host
}

if ($extractChoice -match '^[Yy]$') {
    Write-Info-Message "Extracting files to $ExtractPath..."
    
    # Create target directory
    if (-not (Test-Path $ExtractPath)) {
        New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null
    }
    
    try {
        $extractionSuccessful = $false
        $absoluteZipPath = (Resolve-Path $downloadPath).Path
        $absoluteExtractPath = (New-Item -ItemType Directory -Path $ExtractPath -Force).FullName
        
        # Method 1: Try Windows built-in tar command (Windows 10 1903+)
        # Note: Windows tar doesn't support LZMA compression (7z format), skip for .7z files
        if ((Get-Command "tar" -ErrorAction SilentlyContinue) -and ($ArchiveName -notlike "*.7z")) {
            Write-Info-Message "Trying Windows built-in tar command..."
            
            $extractJob = Start-Job -ScriptBlock {
                param($zipPath, $extractPath)
                try {
                    & tar -xf $zipPath -C $extractPath 2>&1
                    return "SUCCESS"
                } catch {
                    return "FAILED: $($_.Exception.Message)"
                }
            } -ArgumentList $absoluteZipPath, $absoluteExtractPath
            
            # Show progress while extracting
            while ($extractJob.State -eq "Running") {
                Write-Host "." -NoNewline -ForegroundColor Blue
                Start-Sleep -Milliseconds 500
            }
            
            $result = Receive-Job $extractJob -Wait
            Remove-Job $extractJob
            
            if ($result -eq "SUCCESS") {
                $extractionSuccessful = $true
                Write-Host ""
                Write-Success-Message "Files successfully extracted using Windows tar to: $ExtractPath"
            } else {
                Write-Host ""
                Write-Info-Message "Windows tar failed, trying next method..."
            }
        } else {
            Write-Info-Message "Windows tar doesn't support 7z format, trying other methods..."
        }
        
        # Method 2: Try PowerShell with System.IO.Compression (limited 7z support)
        if (-not $extractionSuccessful) {
            Write-Info-Message "Trying PowerShell compression libraries..."
            
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                Add-Type -AssemblyName System.IO.Compression
                
                $extractJob = Start-Job -ScriptBlock {
                    param($zipPath, $extractPath)
                    try {
                        Add-Type -AssemblyName System.IO.Compression.FileSystem
                        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath, $true)
                        return "SUCCESS"
                    } catch {
                        return "FAILED: $($_.Exception.Message)"
                    }
                } -ArgumentList $absoluteZipPath, $absoluteExtractPath
                
                # Show progress while extracting
                while ($extractJob.State -eq "Running") {
                    Write-Host "." -NoNewline -ForegroundColor Blue
                    Start-Sleep -Milliseconds 500
                }
                
                $result = Receive-Job $extractJob -Wait
                Remove-Job $extractJob
                
                if ($result -eq "SUCCESS") {
                    $extractionSuccessful = $true
                    Write-Host ""
                    Write-Success-Message "Files successfully extracted using PowerShell to: $ExtractPath"
                } else {
                    Write-Host ""
                    Write-Info-Message "PowerShell extraction failed, trying 7-Zip..."
                }
            } catch {
                Write-Info-Message "PowerShell compression not available, trying 7-Zip..."
            }
        }
        
        # Method 3: Try 7-Zip as fallback
        if (-not $extractionSuccessful) {
            $7zipPath = $null
            $possiblePaths = @(
                "${env:ProgramFiles}\7-Zip\7z.exe",
                "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
                "7z.exe"  # If 7z is in PATH
            )
            
            foreach ($path in $possiblePaths) {
                if (Get-Command $path -ErrorAction SilentlyContinue) {
                    $7zipPath = $path
                    break
                }
            }
            
            if ($7zipPath) {
                Write-Info-Message "Using 7-Zip for extraction..."
                
                $extractJob = Start-Job -ScriptBlock {
                    param($zipPath, $extractPath, $sevenZipPath)
                    try {
                        & $sevenZipPath x $zipPath "-o$extractPath" -y 2>&1
                        return "SUCCESS"
                    } catch {
                        return "FAILED: $($_.Exception.Message)"
                    }
                } -ArgumentList $absoluteZipPath, $absoluteExtractPath, $7zipPath
                
                # Show progress while extracting
                while ($extractJob.State -eq "Running") {
                    Write-Host "." -NoNewline -ForegroundColor Blue
                    Start-Sleep -Milliseconds 500
                }
                
                $result = Receive-Job $extractJob -Wait
                Remove-Job $extractJob
                
                if ($result -eq "SUCCESS") {
                    $extractionSuccessful = $true
                    Write-Host ""
                    Write-Success-Message "Files successfully extracted using 7-Zip to: $ExtractPath"
                } else {
                    Write-Host ""
                    Write-Error-Message "7-Zip extraction failed!"
                }
            }
        }
        
        # If all methods failed
        if (-not $extractionSuccessful) {
            Write-Error-Message "All extraction methods failed!"
            Write-Info-Message "Please try one of the following:"
            Write-Info-Message "1. Install 7-Zip from: https://www.7-zip.org/"
            Write-Info-Message "2. Update Windows to version 1903+ for built-in tar support"
            Write-Info-Message "3. Extract manually using Windows Explorer (right-click > Extract All)"
            Write-Info-Message "Archive is available at: $downloadPath"
        }
    }
    catch {
        Write-Host ""
        Write-Error-Message "Error extracting files: $($_.Exception.Message)"
        exit 1
    }
}
else {
    Write-Skip-Message "Extraction skipped. Archive available at: $downloadPath"
}

# User prompt for deleting download file
$deleteChoice = "N"
if ($Delete) {
    $deleteChoice = "Y"
}
else {
    Write-Host ""
    Write-Prompt-Message "Delete download file? (Y/N): "
    $deleteChoice = Read-Host
}

if ($deleteChoice -match '^[Yy]$') {
    try {
        Remove-Item $downloadPath -Force
        Write-Success-Message "Download file deleted."
    }
    catch {
        Write-Error-Message "Error deleting download file: $($_.Exception.Message)"
    }
}
else {
    Write-Keep-Message "Download file kept: $downloadPath"
}
