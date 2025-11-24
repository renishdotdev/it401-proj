FROM ubuntu:22.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install cron and required utilities
RUN apt-get update && \
    apt-get install -y \
    cron \
    rsync \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directories for backups and logs
RUN mkdir -p /backups /var/log/cron

# Copy scripts
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Copy crontab file
COPY crontab /etc/cron.d/backup-cron
RUN chmod 0644 /etc/cron.d/backup-cron

# Apply cron job
RUN crontab /etc/cron.d/backup-cron

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create log file for cron
RUN touch /var/log/cron/cron.log

ENTRYPOINT ["/entrypoint.sh"]
