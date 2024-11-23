#!/bin/bash

# Exit on any error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Configuration variables
MOUNT_UNIT_PATH="/etc/systemd/system/juicefs.mount"
MOUNT_POINT="${FOMO_MOUNT_SHR}"

# Create mount point directory if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
    echo "Created mount point directory: $MOUNT_POINT"
fi

# Create the mount unit file
cat > "$MOUNT_UNIT_PATH" << 'EOL'
[Unit]
Description=Juicefs
Before=docker.service

[Mount]
Environment="AWS_ACCESS_KEY_ID=${FOMO_AWS_ACCESS_KEY_ID}" "AWS_SECRET_ACCESS_KEY=${FOMO_AWS_SECRET_ACCESS_KEY}" "META_PASSWORD=${FOMO_REDIS_PW}"
What=redis://172.31.27.164:6379
Where=${FOMO_MOUNT_SHR}
Type=juicefs
Options=_netdev,allow_other,writeback_cache

[Install]
WantedBy=remote-fs.target
WantedBy=multi-user.target
EOL

# Set proper permissions
chmod 644 "$MOUNT_UNIT_PATH"

ln -s /usr/local/bin/juicefs /sbin/mount.juicefs

# Reload systemd to recognize new unit file
systemctl daemon-reload

# Enable and start the mount unit
systemctl enable juicefs.mount
systemctl start juicefs.mount

# Verify mount status
if systemctl is-active juicefs.mount > /dev/null; then
    echo "JuiceFS mount successfully configured and started"
    echo "Mount point: $MOUNT_POINT"
    echo "Unit file: $MOUNT_UNIT_PATH"
else
    echo "Error: JuiceFS mount failed to start"
    echo "Please check logs with: journalctl -u juicefs.mount"
    exit 1
fi