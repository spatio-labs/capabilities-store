#!/bin/zsh

echo "Fetching iMessage conversations..."

osascript <<EOF
tell application "Messages"
    set chatList to ""
    set allChats to every chat
    repeat with c in allChats
        set chatName to name of c
        set lastMessage to text of last message of c
        set chatList to chatList & chatName & ": " & lastMessage & "\n"
    end repeat
    return chatList
end tell
EOF

echo "Done!" 