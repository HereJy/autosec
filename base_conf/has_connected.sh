#!/bin/sh

# This script permit to send an email with informations about an IP that has connected to your account

IP=`who|tr -s " "|cut -d " " -f5|sed 's/[()]//g'`
echo "Subject: Someone has connected to herejy
Someone has connected to herejy from $IP\n
here is some informations of IP :\n
$(curl -s ipinfo.io/$IP)" > has_connected.txt

sendmail ?email? < has_connected.txt

rm has_connected.txt