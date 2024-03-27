#!/bin/bash

# Retrieve the script's directory path and name
SCRIPTPATH="$(cd "$(dirname "$0")" && pwd -P)"
SCRIPTNAME=$(basename "$0")

# Check if running as root, if not, rerun with sudo
if [ "$EUID" -ne 0 ]; then
    sudo "$SCRIPTPATH/$SCRIPTNAME"
    exit
fi

echo "Checking for available updates:"
apt list --upgradable

# Prompt to update package repositories and check again
read -p "Update package repositories and check again? (yes/no): " REPO_UPDATE
case "$REPO_UPDATE" in
    y|Y|yes|Yes)
        apt update && apt list --upgradable
        ;;
    *) : ;; # Continue without updating
esac

# Prompt to restart after updates
read -p "Restart after updates? (yes/no): " RESTART_CHOICE
case "$RESTART_CHOICE" in
    y|Y|yes|Yes)
        echo "Will restart after updates."
        ;;
    n|N|no|No)
        echo "Will not restart."
        ;;
    *) echo "Undefined input, not restarting."
        ;;
esac

# Update packages, clean up, and optionally reboot
apt update
apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt clean -y
apt autoremove -y
docker system prune -a

case "$RESTART_CHOICE" in
    y|Y|yes|Yes)
        reboot now
        ;;
esac

