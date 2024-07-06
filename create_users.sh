#!/bin/bash

# Function to log messages
log_message() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") : $1" >> "$LOG_FILE"
}

# Function to trim leading/trailing whitespace
trim() {
    echo "$1" | xargs
}

# Function to create a user
create_user() {
    local user="$1"
    useradd -m -s /bin/bash "$user"
    if [ $? -eq 0 ]; then
        log_message "User $user created successfully"
        return 0
    else
        log_message "Failed to create user $user"
        return 1
    fi
}

# Function to set user password
set_user_password() {
    local user="$1"
    local password=$(openssl rand -base64 12)
    echo "$user:$password" | chpasswd
    if [ $? -eq 0 ]; then
        log_message "Password set for user $user"
        echo "$user,$password" >> "$PASSWORD_FILE"
    else
        log_message "Failed to set password for user $user"
        return 1
    fi
}

# Function to add user to groups
add_user_to_groups() {
    local user="$1"
    local groups="$2"
    IFS=',' read -r -a group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(trim "$group")
        groupadd -f "$group"
        usermod -aG "$group" "$user"
        log_message "User $user added to group $group"
    done
}

# Function to set home directory permissions
set_home_permissions() {
    local user="$1"
    chmod 700 /home/"$user"
    chown "$user":"$user" /home/"$user"
    log_message "Permissions set for user $user's home directory"
}

# Main script execution

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

USER_FILE="$1"

# Read the input file line by line
while IFS=';' read -r user groups; do
    user=$(trim "$user")
    groups=$(trim "$groups")

    if id "$user" &>/dev/null; then
        log_message "User $user already exists."
        add_user_to_groups "$user" "$groups"
    else
        if create_user "$user"; then
            if set_user_password "$user"; then
                add_user_to_groups "$user" "$groups"
                set_home_permissions "$user"
            fi
        fi
    fi
done < "$USER_FILE"

log_message "User creation process completed."
