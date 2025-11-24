#!/bin/bash

echo "Starting cron container..."
echo "Cron jobs configured:"
crontab -l

# Start cron in foreground
echo "Starting cron daemon..."
cron

# Keep container running and tail logs
echo "Container ready. Tailing logs..."
touch /var/log/cron/cron.log
tail -f /var/log/cron/cron.log
