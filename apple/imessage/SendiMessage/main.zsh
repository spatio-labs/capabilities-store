#!/bin/zsh

# Get the recipient phone number and message from input
RECIPIENT_PHONE="$1"
MESSAGE="$2"

echo "Sending iMessage to $RECIPIENT_PHONE..."

osascript <<EOF
tell application "Messages"
    set targetService to 1st service whose service type = iMessage
    set targetBuddy to buddy "$RECIPIENT_PHONE" of targetService
    send "$MESSAGE" to targetBuddy
    return "Message sent to $RECIPIENT_PHONE"
end tell
EOF

echo "Done!"