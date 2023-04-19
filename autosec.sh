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

        # sshd_config update
        echo "sshd_config edition"
        read -p "custom port for ssh : " ssh_port
        cat base_conf/sshd_config | sed -e "s/Port 22/Port $ssh_port/g;s/?username?/$username/g" > /etc/ssh/sshd_config.d/custom_sshd_config
        chmod 600 /etc/ssh/sshd_config.d/custom_sshd_config
    # stop the script if distro is not debian based
    else
        echo "it's not debian based you can't use this script !"
    fi
fi