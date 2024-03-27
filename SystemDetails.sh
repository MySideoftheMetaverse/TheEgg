#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Clear the screen
clear

# Check if the system is Arch or Debian based
if command_exists "pacman"; then
  distro="Arch"
elif command_exists "apt"; then
  distro="Debian"
else
  distro="Unknown"
fi

# Get CPU architecture
cpu_arch=$(uname -m)

# Get number of CPU cores
cpu_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}')

# Get amount of RAM
ram=$(free -h | awk '/^Mem:/ {print $2}')

# Get amount of storage space on the main disk
disk_info=$(df -h / | awk 'NR==2 {print $4"/"$2}')

# Get name of active internet network
network_name=$(nmcli -t -f NAME connection show --active | grep -vE '^(tun0|br-[0-9a-f]+|docker0|lo)$')
if [ -z "$network_name" ]; then
  network_name="No network connected"
fi

# Get network speed
if command_exists "ethtool"; then
  network_speed=$(ethtool $(ip route show default | awk '/default/ {print $5}') 2>/dev/null | awk '/Speed:/ {print $2}')
else
  network_speed="Not available"
fi

# Get GPU specs
gpu_info=$(lspci -v | grep -A 10 -iE 'VGA|3D controller')
gpu_name=$(echo "$gpu_info" | grep -oP '(?<=Device: ).*' | awk -F'[' '{print "[" $2}')
if [ -z "$gpu_name" ]; then
  gpu_name=$(echo "$gpu_info" | grep -oP '(?<=Subsystem: )[^)]+' | head -n 1)
fi







# Function to determine if the system is running on a Raspberry Pi
is_raspberry_pi() {
  if [ -f "/proc/device-tree/model" ]; then
    model=$(tr -d '\0' </proc/device-tree/model)
    if [[ $model == *"Raspberry Pi"* ]]; then
      return 0 # Raspberry Pi detected
    fi
  fi
  return 1 # Not a Raspberry Pi
}

# Get VRAM (Video RAM) size
vram=$(lspci -v | grep -i "VGA" -A 12 | grep " prefetchable" | awk '{print $2}')

# Get kernel version
kernel_version=$(uname -r)

# Get system uptime
uptime=$(uptime -p)

# Get filesystem type
filesystem_type=$(df -T / | awk 'NR==2 {print $2}')

# Get GPU driver
if command_exists "lspci"; then
  gpu_driver=$(lspci -k | grep -A 2 -E "(VGA|3D controller)" | grep -i "kernel driver")
else
  gpu_driver="Not available"
fi

# Get processor information
get_processor_model=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)

# Get computer name
computer_name=$(hostname)

# Get list of users
users=$(who | awk '{print $1}' | sort | uniq)

# Check if it's the first boot
first_boot=$(test -f /var/log/syslog && echo "No" || echo "Yes")

# Check if SSH is running
ssh_status=$(systemctl is-active ssh)

# Check if connected to a display
display_status=$(DISPLAY=:0 xrandr >/dev/null 2>&1 && echo "Connected" || echo "Not connected")


# Print the gathered information
echo "---------------------------------------------"
echo "        System Information"
echo "---------------------------------------------"
echo "Distribution: $distro"
echo "Computer Name: $computer_name"
echo "Active Network: $network_name (Network Speed: $network_speed)"
echo "SSH Status: $ssh_status"
echo "Display Status: $display_status"
echo "System Uptime: $uptime"
echo "Kernel Version: $kernel_version"
echo "---------------------------------------------"
echo "Processor Model: $get_processor_model ($cpu_arch)"
echo "RAM: $ram"
echo "Disk Space: $disk_info ($filesystem_type) "
if [ -n "$gpu_name" ]; then
  echo "GPU Specs: $gpu_name"
else
  echo "GPU Specs: No GPU detected"
fi
echo "---------------------------------------------"

# Check if the system is running on a Raspberry Pi
if is_raspberry_pi; then
  echo "Raspberry Pi Config Engaged"
else
  echo "Standard System Config Engaged"
fi
echo "Is first boot? $first_boot"
echo "---------------------------------------------"
