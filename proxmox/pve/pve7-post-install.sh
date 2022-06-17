#!/usr/bin/env bash

echo -e "\e[1;33m This script will Disable the Enterprise Repos, Add & Enable the No-Subscription Repos and stops it from nagging. \e[0m"

while true; do
    read -p "Do you wish to start the PVE 7 Post-Installation Script (y/n)?" yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer (y)es or (n)o." ;;
    esac
done

sed -i "s/^deb/#deb/g" /etc/apt/sources.list.d/pve-enterprise.list

cat <<EOF >/etc/apt/sources.list
deb http://ftp.debian.org/debian bullseye main contrib
deb http://ftp.debian.org/debian bullseye-updates main contrib
deb http://security.debian.org/debian-security bullseye-security main contrib
deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription
EOF

sed -i.backup -z "s/res === null || res === undefined || \!res || res\n\t\t\t.data.status.toLowerCase() \!== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

echo -e "\e[1;33m Repos updated. ProxmoxVE will update and upgrades itself now. \e[0m"
systemctl restart pveproxy.service 

apt update && apt full-upgrade -y && apt autoremove -y && apt autoclean

echo -e "\e[1;33m Done! ProxmoxVE is good to go! \e[0m"
systemctl restart pveproxy.service