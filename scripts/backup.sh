#!/bin/bash

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_BASE="/backups"
LOG_FILE="/var/log/cron/backup.log"

echo "=== Backup started at $(date) ===" | tee -a "$LOG_FILE"

# Check if host home directory is mounted
if [ ! -d "/host/home" ]; then
    echo "ERROR: /host/home not mounted!" | tee -a "$LOG_FILE"
    exit 1
fi

# Create backup directory with timestamp
BACKUP_DIR="${BACKUP_BASE}/${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}/configs" "${BACKUP_DIR}/documents"

# Counter for backed up items
CONFIG_COUNT=0
DOCS_COUNT=0

# Backup configs and documents for all users
for USER_HOME in /host/home/*; do
    if [ -d "$USER_HOME" ]; then
        USERNAME=$(basename "$USER_HOME")
        
        # Backup .config directory
        if [ -d "$USER_HOME/.config" ]; then
            echo "Backing up config for user: $USERNAME" | tee -a "$LOG_FILE"
            rsync -a "$USER_HOME/.config/" \
                "${BACKUP_DIR}/configs/${USERNAME}/" 2>>"$LOG_FILE"
            if [ $? -eq 0 ]; then
                CONFIG_COUNT=$((CONFIG_COUNT + 1))
            fi
        fi
        
        # Backup Documents directory
        if [ -d "$USER_HOME/Documents" ]; then
            echo "Backing up documents for user: $USERNAME" | tee -a "$LOG_FILE"
            rsync -a "$USER_HOME/Documents/" \
                "${BACKUP_DIR}/documents/${USERNAME}/" 2>>"$LOG_FILE"
            if [ $? -eq 0 ]; then
                DOCS_COUNT=$((DOCS_COUNT + 1))
            fi
        fi
    fi
done

# Calculate backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

echo "Backup completed: $CONFIG_COUNT configs, $DOCS_COUNT documents backed up" \
    | tee -a "$LOG_FILE"
echo "Backup location: $BACKUP_DIR (Size: $BACKUP_SIZE)" | tee -a "$LOG_FILE"
echo "=== Backup finished at $(date) ===" | tee -a "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Optional: Keep only last 7 days of backups
find "$BACKUP_BASE" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null

exit 0
