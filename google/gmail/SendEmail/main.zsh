#!/bin/zsh

# SMTP Configuration
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT=587
SENDER_EMAIL="your-email@gmail.com"
SENDER_PASSWORD="your-email-password"
RECIPIENT_EMAIL="recipient@example.com"
SUBJECT="Test Email"
BODY="Hello, this is a test email sent from a Zsh script."

# Send email using msmtp
echo -e "From: ${SENDER_EMAIL}\nTo: ${RECIPIENT_EMAIL}\nSubject: ${SUBJECT}\n\n${BODY}" | \
    msmtp --host=${SMTP_SERVER} --port=${SMTP_PORT} --auth=on --tls=on \
          --user=${SENDER_EMAIL} --passwordeval "echo ${SENDER_PASSWORD}" ${RECIPIENT_EMAIL}

if [[ $? -eq 0 ]]; then
    echo "Email sent successfully!"
else
    echo "Failed to send email."
fi