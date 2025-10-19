# Compressed Backup System

A comprehensive backup solution that creates **compressed archives** of your system with **automatic naming based on date and file size**.

## Features

- **Maximum Compression**: Uses XZ compression (level 9 by default) for smallest file sizes
- **Smart Naming**: Archives named with date and final compressed size (e.g., `20251019_home-eduardoneville_1523MB.tar.xz`)
- **Comprehensive Backup**: Backs up home directory and critical system configurations
- **Space Efficient**: Excludes cache, trash, node_modules, and other temporary files
- **Progress Tracking**: Shows compression progress and statistics
- **Easy Management**: Scripts to check status and clean up old backups

## Scripts Overview

### 1. `backup-system.sh` - Main Backup Script

Creates compressed tar.xz archives of your system.

**Usage:**
```bash
# Maximum compression (level 9, slowest but smallest)
sudo ./backup-system.sh

# Custom destination
sudo ./backup-system.sh /mnt/external/backups

# Faster compression (level 6, faster but larger files)
sudo ./backup-system.sh /mnt/external/backups 6
```

**What it backs up:**
- `/home/eduardoneville` - Your home directory
- `/etc` - System configuration files
- `/root` - Root user home
- `/boot` - Boot configuration
- `/usr/local` - Custom installed software
- Package lists (dpkg, xbps, flatpak, snap)
- System information

**Smart exclusions:**
- `.cache`, `.local/share/Trash`
- `node_modules`, `.npm`
- `.cargo/registry`, `.cargo/git`
- Browser caches
- Temporary files

**Output structure:**
```
/mnt/HD_Eduardo/system-backup/
├── 20251019/
│   ├── 20251019_home-eduardoneville_1523MB.tar.xz
│   ├── 20251019_etc_45MB.tar.xz
│   ├── 20251019_boot_12MB.tar.xz
│   ├── 20251019_root_8MB.tar.xz
│   ├── 20251019_package-info.tar.gz
│   └── backup_20251019_143022.log
├── 20251020/
│   ├── 20251020_home-eduardoneville_1524MB.tar.xz
│   ├── 20251020_etc_45MB.tar.xz
│   └── backup_20251020_091533.log
└── 20251021/
    └── ...
```

**Benefits of date-based folders:**
- Easy to identify and locate specific backup dates
- Simple to delete entire backup sessions (just remove the folder)
- Better organization when you have multiple backups
- Can easily copy/move entire backup sets
- Cleanup script can work with whole directories

### 2. `backup-info.sh` - Status Checker

View backup status, disk space, and compression statistics without root access.

**Usage:**
```bash
./backup-info.sh

# Or check custom location
./backup-info.sh /mnt/external/backups
```

**Shows:**
- Available disk space
- Backups grouped by date
- Most recent backup details
- Compression statistics
- All archive files with sizes

### 3. `backup-cleanup.sh` - Cleanup Old Backups

Remove old backups while keeping the N most recent ones.

**Usage:**
```bash
# Keep 3 most recent backups (default)
sudo ./backup-cleanup.sh

# Keep 5 most recent backups
sudo ./backup-cleanup.sh /mnt/HD_Eduardo/system-backup 5

# Keep only 1 most recent backup
sudo ./backup-cleanup.sh /mnt/HD_Eduardo/system-backup 1
```

**Features:**
- Shows what will be deleted before confirming
- Calculates space to be freed
- Safe confirmation prompt
- Deletes both archives and logs

## Compression Details

### XZ Compression
- **Level 9** (default): Maximum compression, slowest
  - Best for: Regular scheduled backups where time isn't critical
  - Typical compression: 60-80% space savings

- **Level 6**: Good compression, faster
  - Best for: Quick backups or large datasets
  - Typical compression: 50-70% space savings

- **Level 1**: Fastest, less compression
  - Best for: Emergency backups or time-critical situations
  - Typical compression: 30-50% space savings

### File Naming Convention
```
<DATE>_<COMPONENT>_<SIZE>MB.tar.xz
```

Examples:
- `20251019_home-eduardoneville_1523MB.tar.xz`
- `20251019_etc_45MB.tar.xz`
- `20251019_boot_12MB.tar.xz`

## Restore Operations

### Restore Entire Home Directory
```bash
# Navigate to the backup date folder
cd /mnt/HD_Eduardo/system-backup/20251019

# List contents first (recommended)
tar -tJf 20251019_home-eduardoneville_1523MB.tar.xz | less

# Restore to original location
sudo tar -xJf 20251019_home-eduardoneville_1523MB.tar.xz -C /

# Or restore to custom location
sudo tar -xJf 20251019_home-eduardoneville_1523MB.tar.xz -C /tmp/restore
```

### Restore Specific Files
```bash
# List archive contents to find the file
tar -tJf /mnt/HD_Eduardo/system-backup/20251019/20251019_home-eduardoneville_1523MB.tar.xz | grep "myfile"

# Extract specific file
tar -xJf /mnt/HD_Eduardo/system-backup/20251019/20251019_home-eduardoneville_1523MB.tar.xz -C /tmp eduardoneville/.bashrc
```

### Restore System Configuration
```bash
# Restore /etc
sudo tar -xJf /mnt/HD_Eduardo/system-backup/20251019/20251019_etc_45MB.tar.xz -C /

# Restore /boot
sudo tar -xJf /mnt/HD_Eduardo/system-backup/20251019/20251019_boot_12MB.tar.xz -C /
```

### Restore Packages
```bash
# Extract package info
tar -xzf /mnt/HD_Eduardo/system-backup/20251019/20251019_package-info.tar.gz

# Debian/Ubuntu - restore packages
sudo dpkg --set-selections < package-info/dpkg-selections.txt
sudo apt-get dselect-upgrade

# Void Linux - restore packages
xargs -a package-info/xbps-packages.txt sudo xbps-install -y
```

## Typical Workflow

### Weekly Backup
```bash
# Mount external drive
sudo mount /dev/sdX1 /mnt/HD_Eduardo

# Run backup
sudo ./backup-system.sh

# Check results
./backup-info.sh

# Unmount
sudo umount /mnt/HD_Eduardo
```

### Monthly Cleanup
```bash
# Check current backups
./backup-info.sh

# Keep only 3 most recent
sudo ./backup-cleanup.sh /mnt/HD_Eduardo/system-backup 3
```

## Space Requirements

Typical compressed sizes (varies based on your data):
- Home directory (~100GB): **~15-30GB** compressed
- /etc: **~30-50MB** compressed
- /boot: **~10-20MB** compressed
- /root: **~5-10MB** compressed

**Recommendation**: Have at least 50GB free on your backup drive.

## Troubleshooting

### "Not enough space" error
- Check available space: `df -h /mnt/HD_Eduardo`
- Clean up old backups: `sudo ./backup-cleanup.sh`
- Use lower compression level for faster, less temporary space usage

### Backup is very slow
- XZ level 9 is slow on large directories (this is normal)
- Use level 6 for faster backups: `sudo ./backup-system.sh /path 6`
- Install `pv` for progress bars: `sudo apt install pv`

### Archive is corrupted
- Verify archive: `xz -t 20251019_home-*.tar.xz`
- Check log file for errors during backup

### Restore doesn't work
- Ensure you're using correct flags: `-xJf` for .tar.xz files
- Check archive contents first: `tar -tJf archive.tar.xz`
- Make sure target directory exists

## Advanced Usage

### Backup to Remote Server via SSH
```bash
# Stream backup directly to remote server
sudo tar -cf - /home/eduardoneville | xz -9 | \
  ssh user@remote "cat > backup_$(date +%Y%m%d).tar.xz"
```

### Backup with Encryption
```bash
# Encrypt backup with GPG
sudo tar -cf - /home/eduardoneville | xz -9 | \
  gpg --symmetric --cipher-algo AES256 -o backup_$(date +%Y%m%d).tar.xz.gpg
```

### Scheduled Automatic Backups
```bash
# Add to root's crontab: sudo crontab -e
# Run every Sunday at 2 AM
0 2 * * 0 /home/eduardoneville/dotfiles/backup-system.sh >> /var/log/backup.log 2>&1
```

## Files Created

- `backup-system.sh` - Main backup script
- `backup-info.sh` - Status checker
- `backup-cleanup.sh` - Cleanup utility
- `BACKUP_README.md` - This documentation

## Comparison with Previous System

### Old System (`bkp-lenovo.sh`)
- Used rsync (no compression)
- Mirrored directories
- ~100GB for home directory backup

### New System
- Uses tar + XZ compression
- ~15-30GB for same data (60-70% savings)
- Date + size in filename
- Better organization
- Easier to transfer/store

## Notes

- Backups are **full backups**, not incremental
- First backup will take longest (calculating sizes + compression)
- Subsequent backups will be similar in size
- XZ provides better compression than gzip/bzip2 but is slower
- Archives are portable - can be extracted on any Linux system with tar and xz
