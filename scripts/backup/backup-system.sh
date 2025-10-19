#!/bin/bash

# Enhanced compressed backup script for home directory and system configurations
# Creates compressed archives named with date and size
# Usage: sudo ./backup-system.sh [destination_path] [compression_level]

set -e  # Exit on error

# Configuration
DEFAULT_BACKUP_DEST="/mnt/HD_Eduardo/system-backup"
BACKUP_DEST_BASE="${1:-$DEFAULT_BACKUP_DEST}"
COMPRESSION_LEVEL="${2:-9}"  # 1-9, where 9 is maximum compression (default)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_ONLY=$(date +%Y%m%d)
BACKUP_DEST="$BACKUP_DEST_BASE/$DATE_ONLY"  # Create date-based subdirectory
TEMP_DIR="$BACKUP_DEST/.tmp_$TIMESTAMP"
LOG_FILE="$BACKUP_DEST/backup_${DATE_ONLY}_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Track total compression stats
TOTAL_ORIGINAL_SIZE=0
TOTAL_COMPRESSED_SIZE=0

# Logging functions
log() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Human-readable size conversion
human_size() {
    local size=$1
    if [ $size -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $size/1073741824}")GB"
    elif [ $size -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $size/1048576}")MB"
    elif [ $size -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $size/1024}")KB"
    else
        echo "${size}B"
    fi
}

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        log "Cleaning up temporary directory..."
        rm -rf "$TEMP_DIR"
    fi
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (sudo ./backup-system.sh)"
    exit 1
fi

# Create backup destination
mkdir -p "$BACKUP_DEST"
mkdir -p "$TEMP_DIR"

# Initialize log file
touch "$LOG_FILE"
log "=== Compressed Backup Started at $(date) ==="
log "Backup destination: $BACKUP_DEST"
log "Compression level: $COMPRESSION_LEVEL (1=fast/less, 9=slow/max)"
log "Using XZ compression for maximum space savings"
echo ""

# Check available space
log "Checking disk space..."
DEST_AVAIL=$(df -BG "$BACKUP_DEST_BASE" | awk 'NR==2 {print $4}' | sed 's/G//')
DEST_TOTAL=$(df -BG "$BACKUP_DEST_BASE" | awk 'NR==2 {print $2}' | sed 's/G//')
DEST_USED=$(df -BG "$BACKUP_DEST_BASE" | awk 'NR==2 {print $3}' | sed 's/G//')
DEST_PERCENT=$(df -h "$BACKUP_DEST_BASE" | awk 'NR==2 {print $5}')

echo "=== Backup Destination Space ==="
echo "Total:     ${DEST_TOTAL}G"
echo "Used:      ${DEST_USED}G ($DEST_PERCENT)"
echo "Available: ${DEST_AVAIL}G"
echo ""

if [ "$DEST_AVAIL" -lt 5 ]; then
    error "Less than 5GB available on backup destination. Aborting."
    exit 1
fi

# Tar exclusion patterns
TAR_EXCLUDE=(
    --exclude='.cache'
    --exclude='.local/share/Trash'
    --exclude='*.tmp'
    --exclude='node_modules'
    --exclude='.npm'
    --exclude='.cargo/registry'
    --exclude='.cargo/git'
    --exclude='.rustup'
    --exclude='.local/share/Steam'
    --exclude='.mozilla/firefox/*/Cache'
    --exclude='.config/Code/Cache'
    --exclude='.config/Code/CachedData'
    --exclude='*~'
    --exclude='.thumbnails'
    --exclude='.Trash'
)

# Backup function with compression
backup_compressed() {
    local src="$1"
    local archive_prefix="$2"
    local name="$3"

    if [ ! -d "$src" ]; then
        warning "$name source directory does not exist: $src"
        return 1
    fi

    log "=== Backing up $name ==="

    # Calculate original size
    info "Calculating original size..."
    local original_size=$(du -sb "$src" "${TAR_EXCLUDE[@]}" 2>/dev/null | awk '{print $1}')
    local original_human=$(human_size $original_size)
    info "Original size: $original_human"

    # Create temporary archive
    local temp_archive="$TEMP_DIR/${archive_prefix}_temp.tar.xz"
    info "Compressing (this may take a while)..."

    # Use pv if available for progress bar, otherwise use tar verbose
    if command -v pv &> /dev/null; then
        tar -cf - -C "$(dirname "$src")" $(basename "$src") "${TAR_EXCLUDE[@]}" 2>/dev/null | \
            pv -s "$original_size" | \
            xz -$COMPRESSION_LEVEL -c > "$temp_archive"
    else
        tar -cf - -C "$(dirname "$src")" $(basename "$src") "${TAR_EXCLUDE[@]}" 2>/dev/null | \
            xz -$COMPRESSION_LEVEL -c > "$temp_archive"
    fi

    # Check if compression succeeded
    if [ ! -f "$temp_archive" ] || [ ! -s "$temp_archive" ]; then
        error "$name backup failed - archive not created"
        return 1
    fi

    # Get compressed size
    local compressed_size=$(stat -c %s "$temp_archive" 2>/dev/null || stat -f %z "$temp_archive" 2>/dev/null)
    local compressed_human=$(human_size $compressed_size)
    local compressed_mb=$(awk "BEGIN {printf \"%.0f\", $compressed_size/1048576}")

    # Calculate compression ratio
    local ratio=$(awk "BEGIN {printf \"%.1f\", ($original_size-$compressed_size)*100/$original_size}")

    # Create final filename with date and size
    local final_archive="$BACKUP_DEST/${DATE_ONLY}_${archive_prefix}_${compressed_mb}MB.tar.xz"

    # Move to final location
    mv "$temp_archive" "$final_archive"

    # Update totals
    TOTAL_ORIGINAL_SIZE=$((TOTAL_ORIGINAL_SIZE + original_size))
    TOTAL_COMPRESSED_SIZE=$((TOTAL_COMPRESSED_SIZE + compressed_size))

    success "$name backup completed!"
    info "Compressed size: $compressed_human (${ratio}% reduction)"
    info "Saved as: $(basename "$final_archive")"
    echo ""

    return 0
}

# Backup home directory
log ">>> Starting backup of /home/eduardoneville <<<"
backup_compressed "/home/eduardoneville" "home-eduardoneville" "Home directory"

# Backup system configurations
log ">>> Starting backup of system configurations <<<"

# /etc
if [ -d "/etc" ]; then
    backup_compressed "/etc" "etc" "System configuration (/etc)"
fi

# /root (if exists and has content)
if [ -d "/root" ] && [ "$(ls -A /root 2>/dev/null)" ]; then
    backup_compressed "/root" "root" "Root home directory"
fi

# /boot (important for system recovery)
if [ -d "/boot" ]; then
    backup_compressed "/boot" "boot" "Boot configuration"
fi

# /usr/local (custom installed software)
if [ -d "/usr/local" ] && [ "$(du -s /usr/local 2>/dev/null | awk '{print $1}')" -gt 100 ]; then
    backup_compressed "/usr/local" "usr-local" "Custom software (/usr/local)"
fi

# Backup list of installed packages
log "=== Backing up package lists and system info ==="
PKG_DIR="$TEMP_DIR/package-info"
mkdir -p "$PKG_DIR"

# Debian/Ubuntu
if command -v dpkg &> /dev/null; then
    dpkg --get-selections > "$PKG_DIR/dpkg-selections.txt"
    apt-mark showauto > "$PKG_DIR/apt-auto.txt" 2>/dev/null || true
    apt-mark showmanual > "$PKG_DIR/apt-manual.txt" 2>/dev/null || true
    info "Debian package list saved"
fi

# Void Linux
if command -v xbps-query &> /dev/null; then
    xbps-query -l > "$PKG_DIR/xbps-packages.txt"
    info "Void Linux package list saved"
fi

# Flatpak
if command -v flatpak &> /dev/null; then
    flatpak list --app > "$PKG_DIR/flatpak-apps.txt" 2>/dev/null || true
fi

# Snap
if command -v snap &> /dev/null; then
    snap list > "$PKG_DIR/snap-packages.txt" 2>/dev/null || true
fi

# Save system information
cat > "$PKG_DIR/system-info.txt" << EOF
Backup Date: $(date)
Hostname: $(hostname)
Kernel: $(uname -r)
Distribution: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Architecture: $(uname -m)
Compression: XZ level $COMPRESSION_LEVEL
EOF

# Create manifest of backups
cat > "$PKG_DIR/backup-manifest.txt" << EOF
Compressed Backup Manifest
Generated: $(date)
Backup Location: $BACKUP_DEST

Archive Files:
EOF

ls -lh "$BACKUP_DEST"/${DATE_ONLY}_*.tar.xz 2>/dev/null >> "$PKG_DIR/backup-manifest.txt" || true

# Compress package info
info "Compressing package information..."
tar -czf "$BACKUP_DEST/${DATE_ONLY}_package-info.tar.gz" -C "$TEMP_DIR" package-info

success "Package lists and system info saved"
echo ""

# Final statistics
echo ""
log "=== Backup Summary ==="
echo ""

# Calculate totals
TOTAL_ORIGINAL_HUMAN=$(human_size $TOTAL_ORIGINAL_SIZE)
TOTAL_COMPRESSED_HUMAN=$(human_size $TOTAL_COMPRESSED_SIZE)
TOTAL_SAVED=$((TOTAL_ORIGINAL_SIZE - TOTAL_COMPRESSED_SIZE))
TOTAL_SAVED_HUMAN=$(human_size $TOTAL_SAVED)
TOTAL_RATIO=$(awk "BEGIN {printf \"%.1f\", $TOTAL_SAVED*100/$TOTAL_ORIGINAL_SIZE}")

echo "Original total size:    $TOTAL_ORIGINAL_HUMAN"
echo "Compressed total size:  $TOTAL_COMPRESSED_HUMAN"
echo "Space saved:            $TOTAL_SAVED_HUMAN (${TOTAL_RATIO}% reduction)"
echo ""

# Space check after backup
DEST_AVAIL_AFTER=$(df -BG "$BACKUP_DEST_BASE" | awk 'NR==2 {print $4}' | sed 's/G//')
DEST_USED_AFTER=$(df -BG "$BACKUP_DEST_BASE" | awk 'NR==2 {print $3}' | sed 's/G//')
DEST_PERCENT_AFTER=$(df -h "$BACKUP_DEST_BASE" | awk 'NR==2 {print $5}')

echo "Backup destination space after backup:"
echo "  Used:      ${DEST_USED_AFTER}G ($DEST_PERCENT_AFTER)"
echo "  Available: ${DEST_AVAIL_AFTER}G"
echo ""

# List created archives
echo "=== Created Archive Files ==="
ls -lh "$BACKUP_DEST"/${DATE_ONLY}_*.tar.* 2>/dev/null | awk '{printf "%-50s %10s\n", $9, $5}'
echo ""

success "Backup completed successfully!"
log "Log file: $LOG_FILE"
echo ""

# Restore instructions
echo "=== Quick Restore Reference ==="
echo "To restore individual archives:"
echo "  cd $BACKUP_DEST"
echo "  sudo tar -xJf ${DATE_ONLY}_home-eduardoneville_*MB.tar.xz -C /"
echo "  sudo tar -xJf ${DATE_ONLY}_etc_*MB.tar.xz -C /"
echo ""
echo "To list archive contents without extracting:"
echo "  tar -tJf $BACKUP_DEST/${DATE_ONLY}_home-*.tar.xz | less"
echo ""
echo "To extract specific files:"
echo "  tar -xJf $BACKUP_DEST/<archive-name.tar.xz> path/to/specific/file"
echo ""
