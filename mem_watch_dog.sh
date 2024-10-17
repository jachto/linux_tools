#!/bin/bash

# Configuration
THRESHOLD_PERCENTAGE=80  # Percentage of memory usage to trigger alert
INTERVAL=60              # Check interval in seconds
EMAIL_TO="your_email@example.com"  # Recipient email address
EMAIL_FROM="monitor@yourdomain.com" # Sender email address (configure properly)
SUBJECT="High Memory Usage Alert"

# Function to send email alert
send_alert() {
  echo "High memory usage detected!" | mail -s "$SUBJECT" "$EMAIL_TO" -r "$EMAIL_FROM"
}

# Function to check memory usage
check_memory() {
  total_mem=$(free -m | awk '/Mem:/ {print $2}')
  used_mem=$(free -m | awk '/Mem:/ {print $3}')
  percentage=$(( (used_mem * 100) / total_mem ))

  echo "Total Memory: $total_mem MB, Used Memory: $used_mem MB ($percentage%)"

  if (( percentage >= THRESHOLD_PERCENTAGE )); then
    echo "Memory usage exceeds threshold ($THRESHOLD_PERCENTAGE%)."
    # Get processes consuming significant memory
    ps aux --sort=-%mem | head -n 15 | awk '{print $1","$2","$11}' | mail -s "$SUBJECT - Processes" "$EMAIL_TO" -r "$EMAIL_FROM"
    send_alert
  fi
}


# Main loop
while true; do
  check_memory
  sleep "$INTERVAL"
done
