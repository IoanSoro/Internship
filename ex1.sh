#!/bin/bash

check_privileges() {
  if [[ $EUID -ne 0 ]]; then
    echo "Error: This script requires root privileges."
    exit 1
  fi
}

process_passwd() {
  local filename="$1"

  if [[ "$filename" != "passwd" ]]; then
    echo "Error: This script is designed for the passwd file."
    return 1
  fi

  while IFS=: read -r username password userid groupid comment homedir shell; do
    true  
  done < /etc/passwd
}

print_home_directories() {
  process_passwd passwd || return 1
  cut -d: -f6 < /etc/passwd
}

list_usernames() {
  process_passwd passwd || return 1
  cut -d: -f1 < /etc/passwd
}

count_users() {
  process_passwd passwd || return 1
  wc -l < /etc/passwd
}

# Function to find user home directory
find_user_home() {
  process_passwd passwd || return 1
  local username="$1"
  grep -E "^$username:" /etc/passwd | cut -d: -f6
}

find_users_by_uid() {
  process_passwd passwd || return 1
  local min_uid="$1"
  local max_uid="$2"
  awk -v min="$min_uid" -v max="$max_uid" 'BEGIN { FS = ":" } { if ($3 >= min && $3 <= max) print $1 }' /etc/passwd
}

find_users_by_shell() {
  process_passwd passwd || return 1
  local shell1="$1"
  local shell2="$2"  
  awk -v shell1="$shell1" -v shell2="$shell2" 'BEGIN { FS = ":" } { if ($7 == shell1 || $7 == shell2) print $1 }' /etc/passwd
}

replace_in_passwd() {
  process_passwd passwd || return 1
  local old_char="$1"
  local new_char="$2"
  cp /etc/passwd /etc/passwd.bak || { echo "Error: Unable to create a backup of /etc/passwd."; return 1; }
  sed "s|$old_char|$new_char|g" /etc/passwd.bak > /etc/passwd || { echo "Error: Failed to replace characters in /etc/passwd."; return 1; }
  rm /etc/passwd.bak || { echo "Error: Unable to remove the backup file."; return 1; }
  echo "Modified passwd file saved."
}

get_ip_addresses() {
  hostname -I
}

get_public_ip() {
  public_ip=$(wget -qO- ifconfig.me)

  if [ -n "$public_ip" ]; then
    echo "Your public IP address is: $public_ip"
  else
    echo "Unable to retrieve the public IP address. Please check your internet connection."
  fi
}

switch_to_user() {
  read -p "Enter the username to switch to: " username
  su "$username"
}


check_privileges


echo "1. Print home directories"
echo "2. List all usernames"
echo "3. Count the number of users"
echo "4. Find home directory of a user"
echo "5. List users with specific UID range (e.g. 1000-1010)"
echo "6. Find users with standard shells (/bin/bash or /bin/sh)"
echo "7. Replace character in passwd"
echo "8. Print private IP "
echo "9. Print public IP"
echo "10. Switch to john user"
echo "Enter a number (or 0 to exit):"

read choice

case $choice in
  1) print_home_directories ;;
  2) list_usernames ;;
  3) count_users ;;
  4) read -p "Enter username: " user; find_user_home "$user" ;;
  5) read -p "Enter min UID: " min_uid; read -p "Enter max UID: " max_uid; find_users_by_uid "$min_uid" "$max_uid" ;;
  6) read -p "Enter shell 1: " shell1; read -p "Enter shell 2: " shell2; find_users_by_shell "$shell1" "$shell2" ;;
  7) read -p "Enter old character: " old_char; read -p "Enter new character: " new_char; replace_in_passwd "$old_char" "$new_char" ;;
  8) get_ip_addresses ;;
  9) get_public_ip ;;  # No separate tool for public IP provided
  10) switch_to_user ;;
  11) print_home_bonus ;;
  0) exit ;;
  *) echo "Invalid option. Please enter a valid number." ;;
esac