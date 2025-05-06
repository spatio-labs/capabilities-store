#!/bin/zsh

# Get the recipient phone number and message from input
RECIPIENT_PHONE="$1"
MESSAGE="$2"

# Log execution details to a file for debugging
LOG_FILE="/tmp/sendimessage_debug.log"
echo "[$(date)] Executing SendiMessage with phone: $RECIPIENT_PHONE, message: $MESSAGE" >> "$LOG_FILE"
echo "[$(date)] Current user: $(whoami)" >> "$LOG_FILE"
echo "[$(date)] Current directory: $(pwd)" >> "$LOG_FILE"
echo "[$(date)] Script path: $0" >> "$LOG_FILE"

# Run the AppleScript to send the message with error handling
RESULT=$(osascript <<EOF 2>&1
tell application "Messages"
    try
        set targetService to 1st service whose service type = iMessage
        set targetBuddy to buddy "$RECIPIENT_PHONE" of targetService
        send "$MESSAGE" to targetBuddy
        return "success"
    on error errMsg
        return "error: " & errMsg
    end try
end tell
EOF
)

# Log the result
echo "[$(date)] AppleScript result: $RESULT" >> "$LOG_FILE"

# Check if there was an error
if [[ $RESULT == error:* ]]; then
    echo "{\"status\": \"failed\", \"error\": \"$RESULT\", \"recipient\": \"$RECIPIENT_PHONE\"}" | tee -a "$LOG_FILE"
    exit 1
fi

# Output JSON with status and recipient as a single echo to ensure valid JSON
echo "{\"status\": \"$RESULT\", \"recipient\": \"$RECIPIENT_PHONE\"}" | tee -a "$LOG_FILE"