#!/bin/bash

LOG_FILE="/var/log/cron/cleanup.log"

echo "=== Logs cleanup started at $(date) ===" | tee -a "$LOG_FILE"

# Check if host home directory is mounted
if [ ! -d "/host/home" ]; then
    echo "ERROR: /host/home not mounted!" | tee -a "$LOG_FILE"
    exit 1
fi

TOTAL_FREED=0

# Clean logs for all users
for USER_HOME in /host/home/*; do
    if [ -d "$USER_HOME" ]; then
        USERNAME=$(basename "$USER_HOME")
        LOGS_DIR="$USER_HOME/logs"
        
        if [ -d "$LOGS_DIR" ]; then
            # Calculate size before deletion
            SIZE_BEFORE=$(du -sb "$LOGS_DIR" 2>/dev/null | cut -f1)
            
            echo "Cleaning logs for user: $USERNAME" | tee -a "$LOG_FILE"
            
            # Remove log files older than 30 days
            find "$LOGS_DIR" -type f -name "*.log" -mtime +30 -delete \
                2>>"$LOG_FILE"
            
            # Remove empty log files
            find "$LOGS_DIR" -type f -name "*.log" -empty -delete \
                2>>"$LOG_FILE"
            
            # Remove empty directories
            find "$LOGS_DIR" -type d -empty -delete 2>>"$LOG_FILE"
            
            # Recreate logs directory if it was removed
            mkdir -p "$LOGS_DIR"
            
            # Calculate freed space
            SIZE_AFTER=$(du -sb "$LOGS_DIR" 2>/dev/null | cut -f1)
            FREED=$((SIZE_BEFORE - SIZE_AFTER))
            TOTAL_FREED=$((TOTAL_FREED + FREED))
            
            echo "  Freed: $(numfmt --to=iec-i --suffix=B $FREED)" \
                | tee -a "$LOG_FILE"
        fi
    fi
done

echo "Total logs freed: $(numfmt --to=iec-i --suffix=B $TOTAL_FREED)" \
    | tee -a "$LOG_FILE"
echo "=== Logs cleanup finished at $(date) ===" | tee -a "$LOG_FILE"
echo "" >> "$LOG_FILE"

exit 0
