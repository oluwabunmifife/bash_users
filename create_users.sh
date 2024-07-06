#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Check if an input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <user-file>"
    exit 1
fi

# Define log and password file paths
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create secure directory for storing passwords and set permissions
mkdir -p /var/secure
chmod 700 /var/secure

# Create log file if it doesn't exist and set permissions
touch $LOG_FILE
chmod 600 $LOG_FILE

# Create password file if it doesn't exist and set permissions
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Read the input file line by line
while IFS=';' read -r USER GROUPS; do
    # Remove whitespace from the username and groups
    USER=$(echo "$USER" | xargs)
    GROUPS=$(echo "$GROUPS" | xargs)

    # Check if the user already exists
    if id "$USER" &>/dev/null; then
        log_message "User $USER already exists."
        continue
    fi

    # Create the user with their personal group and home directory
    useradd -m -s /bin/bash "$USER"
    if [ $? -eq 0 ]; then
        log_message "User $USER created successfully."
    else
        log_message "Failed to create user $USER."
        continue
    fi

    # Generate a random password
    PASSWORD=$(openssl rand -base64 12)

    # Set the password for the user
    echo "$USER:$PASSWORD" | chpasswd
    if [ $? -eq 0 ]; then
        log_message "Password set for user $USER."
        # Store the username and password in the password file
        echo "$USER,$PASSWORD" >> $PASSWORD_FILE
    else
        log_message "Failed to set password for user $USER."
        continue
    fi

    # Add the user to additional groups if specified
    if [ -n "$GROUPS" ]; then
        IFS=',' read -r -a GROUP_ARRAY <<< "$GROUPS"
        for GROUP in "${GROUP_ARRAY[@]}"; do
            groupadd -f "$GROUP"
            usermod -aG "$GROUP" "$USER"
            log_message "User $USER added to group $GROUP."
        done
    fi

    # Set permissions for the user's home directory
    chmod 700 /home/"$USER"
    chown "$USER":"$USER" /home/"$USER"
    log_message "Permissions set for user $USER's home directory."

done < "$USER_FILE"
