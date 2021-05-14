#!/usr/bin/bash

ping -c3 -n -q www.ru 1>/dev/null
if [ $? -eq 0 ]; then
    apt -y install ssh net-tools jq postfix nmap linssid mc enscript ghostscript mailutils iptables-persistent vim curl imagemagick
else
    dpkg -y --recursive --force-depends --install DEB
    apt -y --fix-broken install
fi
