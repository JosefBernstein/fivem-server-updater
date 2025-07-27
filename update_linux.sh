#!/bin/bash

# Set locale for UTF-8
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
BASE_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
DOWNLOAD_DIR="./fivem_download"
VERSION_FILE="${DOWNLOAD_DIR}/.version"
ARCHIVE_NAME="fx.tar.xz"
EXTRACT_DIR="./fivem_server"  # Target directory for extracted files

# Command line arguments
AUTO_EXTRACT=false
AUTO_DELETE=false
FORCE_DOWNLOAD=false
TARGET_VERSION=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -*)
            # Handle combined short flags (e.g., -fed)
            if [[ ${#1} -gt 2 ]] && [[ $1 != --* ]] && [[ $1 != -ep ]] && [[ $1 != -dp ]]; then
                # Split combined flags into individual characters
                flags="${1#-}"
                for (( i=0; i<${#flags}; i++ )); do
                    flag="${flags:$i:1}"
                    case $flag in
                        e)
                            AUTO_EXTRACT=true
                            ;;
                        d)
                            AUTO_DELETE=true
                            ;;
                        f)
                            FORCE_DOWNLOAD=true
                            ;;
                        h)
                            echo "FiveM Server Update Script"
                            echo ""
                            echo "Usage: $0 [OPTIONS]"
                            echo ""
                            echo "Options:"
                            echo "  -e, --extract          Auto-extract files without prompt"
                            echo "  -d, --delete           Auto-delete download file without prompt"
                            echo "  -f, --force            Force download (skip version check)"
                            echo "  -ep, --extractpath     Set extract directory (default: ./fivem_server)"
                            echo "  -dp, --downloadpath    Set download directory (default: ./fivem_download)"
                            echo "  -v, --version VERSION  Download specific version number"
                            echo "  -h, --help             Show this help message"
                            echo ""
                            echo "Combined flags are supported: -fed (same as -f -e -d)"
                            echo ""
                            echo "Examples:"
                            echo "  $0                     Interactive mode"
                            echo "  $0 -ed                 Auto-extract and auto-delete"
                            echo "  $0 -fed                Force, extract, and delete"
                            echo "  $0 -v 17300 -f         Download version 17300 and force overwrite"
                            echo "  $0 -ep /opt/fivem      Extract to /opt/fivem"
                            exit 0
                            ;;
                        v)
                            echo -e "${RED}[ERROR]${NC}  -v requires an argument and cannot be combined with other flags"
                            echo "Use: $0 -v 17300 -ed  (separate -v from other flags)"
                            exit 1
                            ;;
                        *)
                            echo -e "${RED}[ERROR]${NC}  Unknown flag: -$flag"
                            echo "Use -h or --help for usage information."
                            exit 1
                            ;;
                    esac
                done
                shift
            else
                # Handle single flags and special cases
                case $1 in
                    -e|--extract)
                        AUTO_EXTRACT=true
                        shift
                        ;;
                    -d|--delete)
                        AUTO_DELETE=true
                        shift
                        ;;
                    -ep|--extractpath)
                        EXTRACT_DIR="$2"
                        shift 2
                        ;;
                    -dp|--downloadpath)
                        DOWNLOAD_DIR="$2"
                        VERSION_FILE="${DOWNLOAD_DIR}/.version"
                        shift 2
                        ;;
                    -f|--force)
                        FORCE_DOWNLOAD=true
                        shift
                        ;;
                    -v|--version)
                        TARGET_VERSION="$2"
                        shift 2
                        ;;
                    -h|--help)
                        echo "FiveM Server Update Script"
                        echo ""
                        echo "Usage: $0 [OPTIONS]"
                        echo ""
                        echo "Options:"
                        echo "  -e, --extract          Auto-extract files without prompt"
                        echo "  -d, --delete           Auto-delete download file without prompt"
                        echo "  -ep, --extractpath     Set extract directory (default: ./fivem_server)"
                        echo "  -dp, --downloadpath    Set download directory (default: ./fivem_download)"
                        echo "  -f, --force            Force download (skip version check)"
                        echo "  -v, --version VERSION  Download specific version number"
                        echo "  -h, --help             Show this help message"
                        echo ""
                        echo "Combined flags are supported: -fed (same as -f -e -d)"
                        echo ""
                        echo "Examples:"
                        echo "  $0                     Interactive mode"
                        echo "  $0 -ed                 Auto-extract and auto-delete"
                        echo "  $0 -fed                Force, extract, and delete"
                        echo "  $0 -v 17300 -f         Download version 17300 and force overwrite"
                        echo "  $0 -ep /opt/fivem      Extract to /opt/fivem"
                        exit 0
                        ;;
                    *)
                        echo -e "${RED}[ERROR]${NC}  Unknown option: $1"
                        echo "Use -h or --help for usage information."
                        exit 1
                        ;;
                esac
            fi
            ;;
        *)
            echo -e "${RED}[ERROR]${NC}  Unknown argument: $1"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

# Download-Verzeichnis erstellen
mkdir -p "$DOWNLOAD_DIR"

# Get HTML from website
if ! command -v curl &> /dev/null; then
    echo -e "${RED}[ERROR]${NC}  curl is not installed!"
    exit 1
fi

html=$(curl -s "$BASE_URL" 2>/dev/null)

if [[ $? -ne 0 ]] || [[ -z "$html" ]]; then
    echo -e "${RED}[ERROR]${NC}  Error fetching website!"
    exit 1
fi

# Extract build links
build_lines=$(echo "$html" | sed -n 's/.*href="\.\/\([0-9][0-9]*-[a-f0-9][a-f0-9]*\)\/fx\.tar\.xz.*/\1/p' | sort -u)

if [[ -z "$build_lines" ]]; then
    echo -e "${RED}[ERROR]${NC}  No build links found!"
    exit 1
fi

# Sort by build number and get latest
if [[ -n "$TARGET_VERSION" ]]; then
    # Find specific version
    latest_build=$(echo "$build_lines" | grep "^${TARGET_VERSION}-" | head -n 1)
    if [[ -z "$latest_build" ]]; then
        echo -e "${RED}[ERROR]${NC}  Version $TARGET_VERSION not found!"
        echo -e "${BLUE}[INFO]${NC}   Available versions:"
        echo "$build_lines" | cut -d'-' -f1 | sort -nr | head -10
        exit 1
    fi
else
    # Get latest version
    latest_build=$(echo "$build_lines" | sort -t '-' -k1,1nr | head -n 1)
fi

if [[ -z "$latest_build" ]]; then
    echo -e "${RED}[ERROR]${NC}  Could not determine build number!"
    exit 1
fi

# Check current local version
current_build=""
if [[ -f "$VERSION_FILE" ]]; then
    current_build=$(cat "$VERSION_FILE" | tr -d '\n\r' | tr -d ' ')
fi

# Extract version number (everything before first dash)
latest_version=$(echo "$latest_build" | cut -d'-' -f1)
current_version=""
if [[ -n "$current_build" ]]; then
    current_version=$(echo "$current_build" | cut -d'-' -f1)
fi

if [[ "$latest_build" == "$current_build" ]] && [[ "$FORCE_DOWNLOAD" == false ]]; then
    echo -e "${GREEN}[OK]${NC}     Latest version ($latest_version) already available."
    exit 0
fi

# Build download link
download_url="${BASE_URL}${latest_build}/${ARCHIVE_NAME}"
downloadPath="${DOWNLOAD_DIR}/${ARCHIVE_NAME}"

echo -e "${BLUE}[INFO]${NC}   Downloading version $latest_version..."

# Delete existing file if present
if [[ -f "$downloadPath" ]]; then
    rm -f "$downloadPath"
fi

# Download with curl
curl -L -o "$downloadPath" "$download_url" 2>/dev/null

if [[ $? -ne 0 ]] || [[ ! -f "$downloadPath" ]]; then
    echo -e "${RED}[ERROR]${NC}  Download failed!"
    exit 1
fi

# Save version
echo "$latest_build" > "$VERSION_FILE"

echo -e "${GREEN}[OK]${NC}     Download completed: $latest_version"

# User prompt for extraction
if [[ "$AUTO_EXTRACT" == true ]]; then
    extract_choice="Y"
else
    echo ""
    echo -ne "${YELLOW}[PROMPT]${NC} Extract files and overwrite existing files? (Y/N): "
    read -n 1 -r extract_choice
    echo ""
fi

if [[ $extract_choice =~ ^[Yy]$ ]]; then
    # Check if tar is available
    if ! command -v tar &> /dev/null; then
        echo -e "${RED}[ERROR]${NC}  tar is not installed!"
        exit 1
    fi
    
    echo -e "${BLUE}[INFO]${NC}   Extracting files to $EXTRACT_DIR..."
    
    # Create target directory
    mkdir -p "$EXTRACT_DIR"
    
    # Extract with tar and show simple progress
    tar -xJf "$downloadPath" -C "$EXTRACT_DIR" --strip-components=0 &
    tar_pid=$!
    
    # Show simple progress dots while tar is running
    while kill -0 $tar_pid 2>/dev/null; do
        echo -ne "."
        sleep 0.5
    done
    
    # Wait for tar to complete and get exit code
    wait $tar_pid
    tar_exit_code=$?
    
    if [[ $tar_exit_code -eq 0 ]]; then
        echo -e "\n${GREEN}[OK]${NC}     Files successfully extracted to: $EXTRACT_DIR"
    else
        echo -e "\n${RED}[ERROR]${NC}  Error extracting files!"
        exit 1
    fi
else
    echo -e "${CYAN}[SKIP]${NC}   Extraction skipped. Archive available at: $downloadPath"
fi

# User prompt for deleting download file
if [[ "$AUTO_DELETE" == true ]]; then
    delete_choice="Y"
else
    echo ""
    echo -ne "${YELLOW}[PROMPT]${NC} Delete download file? (Y/N): "
    read -n 1 -r delete_choice
    echo ""
fi

if [[ $delete_choice =~ ^[Yy]$ ]]; then
    rm -f "$downloadPath"
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}[OK]${NC}     Download file deleted."
    else
        echo -e "${RED}[ERROR]${NC}  Error deleting download file."
    fi
else
    echo -e "${CYAN}[KEEP]${NC}   Download file kept: $downloadPath"
fi
