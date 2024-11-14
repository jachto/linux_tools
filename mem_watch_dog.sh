#!/bin/bash

# Memory watch dog
# This script exists due to Firefox leaking memory. Thereof the application
# filter only selects firefox threads to be killed at a too high memory usage.
#

# Configuration
FILTER_CMD=firefox-bin   # Kill only commands that match this pattern.
N_PIDS_TO_KILL=10        # Number of Pids to kill.
THRESHOLD_PERCENTAGE=90  # Percentage of memory usage to trigger killing
INTERVAL=60              # Check interval in seconds
EMAIL_TO="your_email@example.com"  # Recipient email address
EMAIL_FROM="monitor@yourdomain.com" # Sender email address (configure properly)
SUBJECT="High Memory Usage Alert"
LOG_FILE=mem_watch_dog.log


# Function to send email alert
send_alert() {
  echo "High memory usage detected!" | mail -s "$SUBJECT" "$EMAIL_TO" -r "$EMAIL_FROM"
}

# Function to check memory usage
check_memory() {
  total_mem=$(free -m | awk '/Mem:/ {print $2}')
  used_mem=$(free -m | awk '/Mem:/ {print $3}')
  percentage=$(( (used_mem * 100) / total_mem ))

   if (( percentage >= THRESHOLD_PERCENTAGE )); then
        echo "Memory usage exceeds threshold ($THRESHOLD_PERCENTAGE%)."
        echo "Total Memory: $total_mem MB, Used Memory: $used_mem MB ($percentage%)" | tee $LOG_FILE
        # Get processes consuming significant memory
        PIDS=`ps aux --sort=-%mem | grep $FILTER_CMD | grep -v "grep" | head -n $N_PIDS_TO_KILL | awk '{print $2","$4","$1","$11}' | tee -a $LOG_FILE | sed 's/,.*$//g' | tr "\n" " "`

        for pid in "${PIDS}" ; do
            kill -15 $pid
            result=$?
            echo "kill -15 $pid  returned: $result" | tee -a $LOG_FILE;
        done
        notify-send "Memory watch dog" "killed pids: $PIDS"
   fi
}

# Main start
rm -f $LOG_FILE

# Main loop
while true; do
  check_memory
  sleep "$INTERVAL"
done
