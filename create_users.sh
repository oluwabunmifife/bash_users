#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

if [ $# -ne 1 ]; then
    echo "Usage: $0 <user-file>"
    exit 1
fi

LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

mkdir -p /var/secure
chmod 700 /var/secure

touch $LOG_FILE
chmod 600 $LOG_FILE

touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

while IFS=';' read -r USER GROUPS; do
    USER=$(echo "$USER" | xargs)
    GROUPS=$(echo "$GROUPS" | xargs)

    if id "$USER" &>/dev/null; then
        log_message "User $USER already exists."
        continue
    fi

    useradd -m -s /bin/bash "$USER"
    if [ $? -eq 0 ]; then
        log_message "User $USER created successfully."
    else
        log_message "Failed to create user $USER."
        continue
    fi

    PASSWORD=$(openssl rand -base64 12)

    echo "$USER:$PASSWORD" | chpasswd
    if [ $? -eq 0 ]; then
        log_message "Password set for user $USER."
        echo "$USER,$PASSWORD" >> $PASSWORD_FILE
    else
        log_message "Failed to set password for user $USER."
        continue
    fi

    if [ -n "$GROUPS" ]; then
        IFS=',' read -r -a GROUP_ARRAY <<< "$GROUPS"
        for GROUP in "${GROUP_ARRAY[@]}"; do
            groupadd -f "$GROUP"
            usermod -aG "$GROUP" "$USER"
            log_message "User $USER added to group $GROUP."
        done
    fi

    chmod 700 /home/"$USER"
    chown "$USER":"$USER" /home/"$USER"
    log_message "Permissions set for user $USER's home directory."

done < "$USER_FILE"
