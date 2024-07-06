# HNG11 Task 1: User Creation Script

This project is a dive into the world of User management on a Linux enviroment as a SysOps Engineer

## Features

- Creates users with personal groups.
- Assigns users to multiple groups.
- Sets up home directories with appropriate permissions.
- Generates random passwords for users.
- Logs all actions to `/var/log/user_management.log`.
- Stores passwords securely in `/var/secure/user_passwords.csv`.

## Requirements

- The script must be run as root.
- The input file should be formatted with each line containing a username and groups separated by a semicolon (`;`). Multiple groups should be separated by commas (`,`).

### Example Input File

## Usage

1. Clone the repository:
    ```sh
    git clone <repository-url>
    cd <repository-name>
    ```

2. Ensure the script is executable:
    ```sh
    chmod +x create_users.sh
    ```

3. Run the script with the input file as an argument:
    ```sh
    sudo ./create_users.sh <user-file>
    ```

## Script Details

### Log and Password Files

- **Log File**: `/var/log/user_management.log`
    - Contains logs of all actions performed by the script.
- **Password File**: `/var/secure/user_passwords.csv`
    - Stores usernames and generated passwords. Only accessible by the root user.

### Error Handling

- The script checks if it is run as root.
- It verifies that an input file is provided.
- It handles cases where a user already exists and logs appropriate messages.

### Logging Function

```bash
log_message() {
    local MESSAGE=$1
    echo "$(date "+%Y-%m-%d %H:%M:%S") : $MESSAGE" >> /var/log/user_management.log
}
