#!/bin/sh
set -eu

# Configuration
CHECK_INTERVAL_SECONDS=${CHECK_INTERVAL_SECONDS:-1800} # default: 30 minutes
REBOOT_WINDOW_HOUR=${REBOOT_WINDOW_HOUR:-4}             # default: 4 AM

echo "Starting NVIDIA driver/library mismatch reboot daemon..."
echo "Configured to check at hour: $REBOOT_WINDOW_HOUR (local time), checking every $CHECK_INTERVAL_SECONDS seconds."

while true; do
  CURRENT_HOUR=$(date +%H)
  # Strip leading zero to avoid octal interpretation issues in shell arithmetic
  CURRENT_HOUR=${CURRENT_HOUR#0}
  CURRENT_HOUR=${CURRENT_HOUR:-0}
  
  if [ "$CURRENT_HOUR" -eq "$REBOOT_WINDOW_HOUR" ]; then
    echo "Current hour is $CURRENT_HOUR, running nvidia-smi check on the host..."
    
    # Run nvidia-smi in the host's namespaces.
    # We redirect stderr to check if it contains the version mismatch string.
    if ! ERROR_MSG=$(nsenter -t 1 -m -u -i -n -p -- nvidia-smi 2>&1); then
      echo "nvidia-smi check failed: $ERROR_MSG"
      if echo "$ERROR_MSG" | grep -qi "version mismatch"; then
        echo "CRITICAL: NVIDIA Driver/Library Version Mismatch detected on host!"
        echo "Rebooting host node in 10 seconds..."
        sleep 10
        nsenter -t 1 -m -u -i -n -p -- reboot
        # Sleep for a long time to prevent reboot loop if reboot takes time
        sleep 3600
      else
        echo "nvidia-smi failed, but not due to a version mismatch. Skipping reboot."
      fi
    else
      echo "NVIDIA driver is healthy. nvidia-smi succeeded."
    fi
  else
    echo "Current hour is $CURRENT_HOUR. Reboot window is $REBOOT_WINDOW_HOUR:00. Skipping check."
  fi
  
  sleep "$CHECK_INTERVAL_SECONDS"
done
