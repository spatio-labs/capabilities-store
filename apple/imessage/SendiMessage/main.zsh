#!/bin/zsh

# Get the recipient phone number and message from input
RECIPIENT_PHONE="$1"
MESSAGE="$2"

# Run the AppleScript to send the message (without the "Sending iMessage" message)
RESULT=$(osascript <<EOF
tell application "Messages"
    set targetService to 1st service whose service type = iMessage
    set targetBuddy to buddy "$RECIPIENT_PHONE" of targetService
    send "$MESSAGE" to targetBuddy
    return "success"
end tell
EOF
)

# Output JSON with status and recipient as a single echo to ensure valid JSON
echo "{\"status\": \"$RESULT\", \"recipient\": \"$RECIPIENT_PHONE\"}"