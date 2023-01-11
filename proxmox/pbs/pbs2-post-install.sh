#!/usr/bin/env bash

echo -e "\e[1;33m This script will Disable the Enterprise Repos, Add & Enable the No-Subscription Repos. \e[0m"

while true; do
  read -p "Do you wish to start the PBS 2 Post-Installation Script (y/n)?" yn
  case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer (y)es or (n)o." ;;
  esac
done

sed -i "s/^deb/#deb/g" /etc/apt/sources.list.d/pbs-enterprise.list

cat << EOF > /etc/apt/sources.list
deb http://ftp.debian.org/debian bullseye main contrib
deb http://ftp.debian.org/debian bullseye-updates main contrib
deb http://security.debian.org/debian-security bullseye-security main contrib
deb http://download.proxmox.com/debian/pbs bullseye pbs-no-subscription
EOF

echo -e "\e[1;33m Repos updated. ProxmoxBS will update and upgrades itself now. \e[0m"

apt update && apt full-upgrade -y && apt autoremove -y && apt autoclean

echo -e "\e[1;33m Done! ProxmoxBS is good to go! \e[0m"
