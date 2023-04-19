#!/usr/bin/env bash

# check if launch as root
if [[ $EUID -ne "0" ]]; then
    echo "You have to execute this script as root !"
else
    # check if your distro is debian based
    if [[ -e /etc/debian_version ]]; then
        # user account creation
        echo "User account creation"
        read -p "username : " username
        read -s -p "user password : " password
        useradd -m -s /bin/bash -p $(echo "$password"|openssl passwd -6 -stdin) $username
        echo ""
    # stop the script if distro is not debian based
    else
        echo "it's not debian based you can't use this script !"
    fi
fi