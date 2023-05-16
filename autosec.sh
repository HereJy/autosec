#!/usr/bin/env bash

# check if launch as root
if [[ $EUID -ne "0" ]]; then
    echo -e "\033[0;31mYou have to execute this script as root !\033[0m"
else
    # check if your distro is debian based
    if [[ -e /etc/debian_version ]]; then
        # user account creation
        echo "User account creation"
        read -p "username : " username
        read -s -p "user password : " password
        useradd -m -s /bin/bash -p $(echo "$password"|openssl passwd -6 -stdin) $username

        # sshd_config update
        echo "sshd_config edition"
        read -p "custom port for ssh : " ssh_port
        cat base_conf/sshd_config | sed -e "s/Port 22/Port $ssh_port/g;s/?username?/$username/g" > /etc/ssh/sshd_config.d/custom_sshd_config
        chmod 600 /etc/ssh/sshd_config.d/custom_sshd_config

        # fail2ban configuration
        echo "fail2ban installation and configuration"

        if [[ -z $(dpkg -l|grep fail2ban) ]]; then
            apt install fail2ban
        fi

        read -p "How many days do you want to ban IP ? : " ban_days
        read -p "How many ssh auth retry do you want ? : " ssh_maxretry
        cat base_conf/jail.local | sed -e "s/bantime  = 10m/bantime  = $ban_days\d/g;s/maxretry = 5/maxretry = $ssh_maxretry/g" > /etc/fail2ban/jail.d/jail.local

        # iptables configuration
        if [[ -z $(dpkg -l|grep iptables) ]]; then
            apt install iptables
        fi

        cat base_conf/firewall-rules | sed -e "s/--dport 22/--dport $ssh_port/g" > /etc/init.d/firewall-rules 
        chmod +x /etc/init.d/firewall-rules
        systemctl enable --now firewall-rules
    # stop the script if distro is not debian based
    else
        echo "it's not debian based you can't use this script !"
    fi
fi