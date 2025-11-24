#!/bin/bash

LOG_FILE="/var/log/cron/cleanup.log"

echo "=== Cache cleanup started at $(date) ===" | tee -a "$LOG_FILE"

# Check if host home directory is mounted
if [ ! -d "/host/home" ]; then
    echo "ERROR: /host/home not mounted!" | tee -a "$LOG_FILE"
    exit 1
fi

TOTAL_FREED=0

# Clean cache for all users
for USER_HOME in /host/home/*; do
    if [ -d "$USER_HOME" ]; then
        USERNAME=$(basename "$USER_HOME")
        CACHE_DIR="$USER_HOME/.cache"
        
        if [ -d "$CACHE_DIR" ]; then
            # Calculate size before deletion
            SIZE_BEFORE=$(du -sb "$CACHE_DIR" 2>/dev/null | cut -f1)
            
            echo "Cleaning cache for user: $USERNAME" | tee -a "$LOG_FILE"
            
            # Remove cache contents but keep the directory
            find "$CACHE_DIR" -type f -delete 2>>"$LOG_FILE"
            find "$CACHE_DIR" -type d -empty -delete 2>>"$LOG_FILE"
            
            # Recreate the .cache directory if it was removed
            mkdir -p "$CACHE_DIR"
            
            # Calculate freed space
            SIZE_AFTER=$(du -sb "$CACHE_DIR" 2>/dev/null | cut -f1)
            FREED=$((SIZE_BEFORE - SIZE_AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED))
            
            echo "  Freed: $(numfmt --to=iec-i --suffix=B $FREED)" \
                | tee -a "$LOG_FILE"
        fi
    fi
done

echo "Total cache freed: $(numfmt --to=iec-i --suffix=B $TOTAL_FREED)" \
    | tee -a "$LOG_FILE"
echo "=== Cache cleanup finished at $(date) ===" | tee -a "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit 0
