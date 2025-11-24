# Docker Container for cron

Automated backup and cleanup tool that runs time-scheduled tasks.

## Requirements
- Install Docker Engine from https://docs.docker.com/engine/install/

## What It Does

- Backs up `/home/*/.config` and `/home/*/Documents` for all users daily
- Cleans up cache and old logs automatically
- Runs on a schedule via cron inside Docker
- Works across different Linux systems

## Quick Start

```bash
# Build the image
docker build -t cron:latest .

# Create backup directory
mkdir -p ~/backups

# Run it
docker run -d \
  --name cron \
  --restart unless-stopped \
  -v /home:/host/home:ro \
  -v ~/backups:/backups \
  -v cron-logs:/var/log/cron \
  cron:latest

# Check if it's working
docker logs -f cron
```

## File Structure

```
cron/
├── Dockerfile          # Container setup
├── scripts/
│   ├── backup.sh       # to back up 
│   ├── rm-cache.sh     # to clear cache files
│   └── rm-logs.sh      # to remove logs
├── crontab            # cron config file
└── entrypoint.sh      # container startup script
```

## Customization

### Change When Tasks Run

Edit `crontab`:

Check out this page for a guide to cusomtize this file https://cronitor.io/guides/cron-jobs

```cron
# Backup at 2 AM daily
0 2 * * * /usr/local/bin/backup.sh >> /var/log/cron/cron.log 2>&1
```

Then rebuild:
```bash
docker build -t cron:latest .
docker rm -f cron

# Change ~/backups to your custom backup directory path
docker run -d --name cron \
  -v /home:/host/home:ro \
  -v ~/backups:/backups \
  -v cron-logs:/var/log/cron \ 
  cron:latest
```

### Change What Gets Backed Up

Edit `scripts/backup.sh`. For example, to also backup `.local`:

```bash
if [ -d "$USER_HOME/.local" ]; then
    echo "Backing up .local for user: $USERNAME"
    rsync -a "$USER_HOME/.local/" \
        "${BACKUP_DIR}/local/${USERNAME}/" 2>>"$LOG_FILE"
fi
```

### Change Backup Retention

In `scripts/backup.sh`, find this line:

```bash
# Current: Keep 7 days
find "$BACKUP_BASE" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

# Change to 30 days:
find "$BACKUP_BASE" -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \;
```

### Use External Drive

```bash
docker run -d --name cron \
  -v /home:/host/home:ro \
  -v /mnt/external-drive/backups:/backups \
  -v cron-logs:/var/log/cron \
  cron:latest
```

## Common Commands

```bash
# View logs
docker logs -f cron

# Run backup script manually
docker exec cron /usr/local/bin/backup.sh

# Check backup size
du -sh ~/backups/

# List all backups
ls -lh ~/backups/

# Stop container
docker stop cron

# Remove container (to force stop and remove, use -f flag)
docker rm cron
```

## Crontab file Syntax Quick Reference

```
* * * * * command
│ │ │ │ │
│ │ │ │ └─ Day of week (0-6, 0=Sunday)
│ │ │ └─── Month (1-12)
│ │ └───── Day of month (1-31)
│ └─────── Hour (0-23)
└───────── Minute (0-59)

# Examples
0 2 * * *  = 2 AM daily
0 */6 * * * = Every 6 hours
*/30 * * * * = Every 30 minutes
0 9 * * 1-5 = 9 AM weekdays only
```
