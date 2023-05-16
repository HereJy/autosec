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
        echo -e "\nsshd_config edition"
        read -p "custom port for ssh : " ssh_port
        cat base_conf/sshd_config | sed -e "s/Port 22/Port $ssh_port/g;s/?username?/$username/g" > /etc/ssh/sshd_config.d/custom_sshd_config
        chmod 600 /etc/ssh/sshd_config.d/custom_sshd_config

        # fail2ban configuration
        echo -e "\nfail2ban installation and configuration"

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

        # send email at connection
        read -p "Do you want to send an email at any connection to your account with informations about source IP ? (y/N)" check_mail
        if [[ $check_mail -eq "y" || $check_mail -eq "Y" ]]; then
            if [[ -z $(dpkg -l|grep sendmail ) ]]; then
                apt install sendmail
            fi
            read -p "email to sendmail mail : " usermail
            user_shell=$(grep "$username" /etc/passwd | cut -d ":" -f7 | cut -d "/" -f3)
            script_path=$(find /home -name has_connected.sh 2>/dev/null)
            cat $script_path|sed -e "s/?email?/$usermail/g" > "/home/${username}/has_connected.sh"
            echo -e "\nbash /home/${username}/has_connected.sh" >> "/home/${username}/.${user_shell}rc"
            echo -e "\n\n#SMTP\niptables -A OUPUT -p tcp --dport 5 -j ACCEPT" >> /etc/init.d/firewall-rules
        else
            continue
        fi


        chmod +x /etc/init.d/firewall-rules
        systemctl enable --now firewall-rules
    # stop the script if distro is not debian based
    else
        echo -e "\033[0;31mit's not debian based you can't use this script !\033[0m"
    fi
fi