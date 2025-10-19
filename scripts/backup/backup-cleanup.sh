#!/bin/bash

# Script to clean up old compressed backups
# Keeps only the most recent N backups by date
# Usage: sudo ./backup-cleanup.sh [backup_location] [keep_count]

DEFAULT_BACKUP_DEST="/mnt/HD_Eduardo/system-backup"
BACKUP_DEST="${1:-$DEFAULT_BACKUP_DEST}"
KEEP_COUNT="${2:-3}"  # Keep the 3 most recent backups by default

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Backup Cleanup Tool ===${NC}"
echo ""

# Check if backup location exists
if [ ! -d "$BACKUP_DEST" ]; then
    echo -e "${RED}Error:${NC} Backup location does not exist: $BACKUP_DEST"
    exit 1
fi

# Check for backup directories
if ! ls -d "$BACKUP_DEST"/2*/ 1> /dev/null 2>&1; then
    echo "No backup directories found in $BACKUP_DEST"
    exit 0
fi

echo "Backup Location: $BACKUP_DEST"
echo "Will keep the $KEEP_COUNT most recent backups"
echo ""

# Get backup date directories, sorted newest first
BACKUP_DATES=($(ls -d "$BACKUP_DEST"/2*/ 2>/dev/null | xargs -n1 basename | sort -r))

echo -e "${BLUE}=== Current Backups ===${NC}"
for i in "${!BACKUP_DATES[@]}"; do
    date="${BACKUP_DATES[$i]}"
    count=$(ls "$BACKUP_DEST/$date"/*.tar.* 2>/dev/null | wc -l)
    size=$(du -sh "$BACKUP_DEST/$date" 2>/dev/null | awk '{print $1}')

    if [ $i -lt $KEEP_COUNT ]; then
        echo -e "  $date: $count archives, $size ${GREEN}[KEEP]${NC}"
    else
        echo -e "  $date: $count archives, $size ${RED}[DELETE]${NC}"
    fi
done
echo ""

# Calculate what will be deleted
DATES_TO_DELETE=("${BACKUP_DATES[@]:$KEEP_COUNT}")

if [ ${#DATES_TO_DELETE[@]} -eq 0 ]; then
    echo -e "${GREEN}No old backups to delete.${NC}"
    echo "You have ${#BACKUP_DATES[@]} backup(s), keeping $KEEP_COUNT most recent."
    exit 0
fi

# Show what will be deleted
echo -e "${YELLOW}=== Directories to be Deleted ===${NC}"
TOTAL_DELETE_SIZE=0
for date in "${DATES_TO_DELETE[@]}"; do
    echo "Backup date: $date"
    ls -lh "$BACKUP_DEST/$date"/* 2>/dev/null | awk '{
        split($9, path, "/");
        filename = path[length(path)];
        printf "  %-60s %10s\n", filename, $5
    }'

    # Calculate size to be freed
    DATE_SIZE=$(du -sb "$BACKUP_DEST/$date" 2>/dev/null | awk '{print $1}')
    TOTAL_DELETE_SIZE=$((TOTAL_DELETE_SIZE + DATE_SIZE))
done
echo ""

# Convert size to human readable
if [ $TOTAL_DELETE_SIZE -ge 1073741824 ]; then
    HUMAN_SIZE="$(awk "BEGIN {printf \"%.2f\", $TOTAL_DELETE_SIZE/1073741824}")GB"
elif [ $TOTAL_DELETE_SIZE -ge 1048576 ]; then
    HUMAN_SIZE="$(awk "BEGIN {printf \"%.2f\", $TOTAL_DELETE_SIZE/1048576}")MB"
else
    HUMAN_SIZE="$(awk "BEGIN {printf \"%.2f\", $TOTAL_DELETE_SIZE/1024}")KB"
fi

echo -e "${YELLOW}Total space to be freed: $HUMAN_SIZE${NC}"
echo ""

# Confirm deletion
read -p "Do you want to delete these backups? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}=== Deleting Old Backups ===${NC}"

# Delete old backups
for date in "${DATES_TO_DELETE[@]}"; do
    echo "Deleting backup directory: $date..."

    # Delete entire directory
    rm -rf "$BACKUP_DEST/$date" 2>/dev/null

    echo -e "  ${GREEN}Deleted${NC}"
done

echo ""
echo -e "${GREEN}=== Cleanup Complete ===${NC}"
echo "Kept ${#BACKUP_DATES[@]:0:$KEEP_COUNT} most recent backup(s)"
echo "Deleted ${#DATES_TO_DELETE[@]} old backup(s)"
echo "Freed approximately $HUMAN_SIZE"
echo ""

# Show current disk usage
echo -e "${BLUE}=== Updated Disk Space ===${NC}"
df -h "$BACKUP_DEST" | awk 'NR==1 {print $0} NR==2 {printf "%-20s %10s %10s %10s %6s\n", $1, $2, $3, $4, $5}'
echo ""
