#!/bin/bash

# Define WiFi list
wifi_list=(
  "WIFI-BC36:follow3675event"
)

# Logging function
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S"): $1"
}

# Function to check internet connection
check_internet() {
  ping -c 1 google.com &>/dev/null
}

# Function to connect to WiFi network
connect_to_wifi() {
  local wifi_name="$1"
  local wifi_password="$2"

  nmcli device wifi connect "$wifi_name" password "$wifi_password"
}

# Main function to iterate over WiFi list and attempt connections
main() {
  log "Starting WiFi connection script"

  for wifi_info in "${wifi_list[@]}"; do
    wifi_name=$(echo "$wifi_info" | cut -d':' -f1)
    wifi_password=$(echo "$wifi_info" | cut -d':' -f2)

    log "Attempting to connect to WiFi: $wifi_name"
    if connect_to_wifi "$wifi_name" "$wifi_password"; then
      log "Connected to WiFi: $wifi_name"
      if check_internet; then
        log "Internet is connected"
        return 0  # Exit successfully
      else
        log "Connected to $wifi_name but internet is not reachable"
        # Retry connection or continue to next WiFi network
      fi
    else
      log "Failed to connect to WiFi: $wifi_name"
      # Retry connection or continue to next WiFi network
    fi
  done

  log "Failed to connect to any WiFi network"
  return 1  # Exit with failure
}

# Execute main function
main

