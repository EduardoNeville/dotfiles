#!/bin/bash

# Quick script to check compressed backup status and space
# Usage: ./backup-info.sh [backup_location]

DEFAULT_BACKUP_DEST="/mnt/HD_Eduardo/system-backup"
BACKUP_DEST="${1:-$DEFAULT_BACKUP_DEST}"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}=== Compressed Backup Information ===${NC}"
echo ""

# Check if backup location exists
if [ ! -d "$BACKUP_DEST" ]; then
    echo -e "${YELLOW}Warning:${NC} Backup location does not exist: $BACKUP_DEST"
    exit 1
fi

echo "Backup Location: $BACKUP_DEST"
echo ""

# Disk space information
echo -e "${BLUE}=== Disk Space ===${NC}"
df -h "$BACKUP_DEST" | awk 'NR==1 {print $0} NR==2 {printf "%-20s %10s %10s %10s %6s %s\n", $1, $2, $3, $4, $5, $6}'
echo ""

# Count archives by date
echo -e "${BLUE}=== Backup Archives by Date ===${NC}"
if ls -d "$BACKUP_DEST"/2*/ 1> /dev/null 2>&1; then
    # List date folders and show counts
    for date_dir in $(ls -d "$BACKUP_DEST"/2*/ 2>/dev/null | sort -r); do
        date_name=$(basename "$date_dir")
        count=$(ls "$date_dir"/*.tar.* 2>/dev/null | wc -l)
        total_size=$(du -ch "$date_dir"/*.tar.* 2>/dev/null | tail -1 | awk '{print $1}')
        echo "  $date_name: $count archives, Total: $total_size"
    done
else
    echo "No backup archives found"
fi
echo ""

# Most recent backup details
echo -e "${BLUE}=== Most Recent Backup ===${NC}"
LATEST_DIR=$(ls -dt "$BACKUP_DEST"/2*/ 2>/dev/null | head -1)
if [ -n "$LATEST_DIR" ]; then
    LATEST_DATE=$(basename "$LATEST_DIR")
    echo "Date: $LATEST_DATE"
    echo ""
    echo "Archives in $LATEST_DATE:"
    ls -lh "$LATEST_DIR"/*.tar.* 2>/dev/null | awk '{
        split($9, path, "/");
        filename = path[length(path)];
        printf "  %-60s %10s\n", filename, $5
    }'

    # Show total size for this date
    TOTAL_SIZE=$(du -ch "$LATEST_DIR"/*.tar.* 2>/dev/null | tail -1 | awk '{print $1}')
    echo ""
    echo "Total size of latest backup: $TOTAL_SIZE"
else
    echo "No backups found"
fi
echo ""

# Recent log files
echo -e "${BLUE}=== Recent Backup Logs ===${NC}"
if ls "$BACKUP_DEST"/*/backup_*.log 1> /dev/null 2>&1; then
    ls -lht "$BACKUP_DEST"/*/backup_*.log 2>/dev/null | head -5 | awk '{
        split($9, path, "/");
        filename = path[length(path)-1] "/" path[length(path)];
        printf "  %s %s %s  %-50s %8s\n", $6, $7, $8, filename, $5
    }'
    echo ""
    echo "View log: less $BACKUP_DEST/*/backup_*.log"
else
    echo "No log files found"
fi
echo ""

# All backup contents with sizes
echo -e "${BLUE}=== All Backup Archives ===${NC}"
if ls "$BACKUP_DEST"/*/*.tar.* 1> /dev/null 2>&1; then
    echo "Archive files by date:"
    for date_dir in $(ls -d "$BACKUP_DEST"/2*/ 2>/dev/null | sort -r); do
        date_name=$(basename "$date_dir")
        echo ""
        echo "  [$date_name]"
        ls -lh "$date_dir"/*.tar.* 2>/dev/null | awk '{
            split($9, path, "/");
            filename = path[length(path)];
            printf "    %-58s %10s  %s %s %s\n", filename, $5, $6, $7, $8
        }'
    done
    echo ""

    # Calculate total backup size
    TOTAL_BACKUP=$(du -sh "$BACKUP_DEST" 2>/dev/null | awk '{print $1}')
    ARCHIVE_TOTAL=$(du -ch "$BACKUP_DEST"/*/*.tar.* 2>/dev/null | tail -1 | awk '{print $1}')
    echo "Total archive size: $ARCHIVE_TOTAL"
    echo "Total directory size (including logs): $TOTAL_BACKUP"
else
    echo "No backup archives found"
fi
echo ""

# Compression statistics from latest log
echo -e "${BLUE}=== Latest Backup Compression Stats ===${NC}"
LATEST_LOG=$(ls -t "$BACKUP_DEST"/*/backup_*.log 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ]; then
    # Extract compression info from log
    if grep -q "Original total size:" "$LATEST_LOG"; then
        grep "Original total size:" "$LATEST_LOG" | sed 's/^/  /'
        grep "Compressed total size:" "$LATEST_LOG" | sed 's/^/  /'
        grep "Space saved:" "$LATEST_LOG" | sed 's/^/  /'
    else
        echo "  Compression statistics not available in log"
    fi
else
    echo "  No log files found"
fi
echo ""

# Quick restore examples
echo -e "${GREEN}=== Quick Commands ===${NC}"
echo "Run new backup:"
echo "  sudo ./backup-system.sh"
echo ""
echo "Run backup with faster compression (level 6):"
echo "  sudo ./backup-system.sh /mnt/HD_Eduardo/system-backup 6"
echo ""
echo "List contents of an archive:"
echo "  tar -tJf $BACKUP_DEST/[date]_home-eduardoneville_*MB.tar.xz | less"
echo ""
echo "Restore home directory:"
echo "  sudo tar -xJf $BACKUP_DEST/[date]_home-eduardoneville_*MB.tar.xz -C /"
echo ""
echo "View backup log:"
echo "  less $BACKUP_DEST/backup_*.log"
echo ""

# Warning about old backups
BACKUP_DATES_COUNT=$(ls -d "$BACKUP_DEST"/2*/ 2>/dev/null | wc -l)
if [ "$BACKUP_DATES_COUNT" -gt 5 ]; then
    echo -e "${YELLOW}Note:${NC} You have $BACKUP_DATES_COUNT backup dates. Consider cleaning up old backups to save space."
    echo "Run: sudo ./backup-cleanup.sh"
    echo ""
fi
