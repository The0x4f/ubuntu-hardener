#!/bin/bash
if [[ $UID -ne 0 ]]; then
 echo "This script needs to be run as root."
 exit 1
fi

echo "Let's harden your Ubuntu-install!"

#updating system
apt-get update -y
apt-get dist-upgrade -y

apt remove -y popularity-contest

#automatic updates/upgrade
echo "Turning on automatic updates/upgrades."
EXISTS=$(grep "APT::Periodic::Update-Package-Lists \"1\"" /etc/apt/apt.conf.d/20auto-upgrades)
if [ -z "$EXISTS" ]; then
	echo "APT::Periodic::Update-Package-Lists \"1\";" >> /etc/apt/apt.conf.d/20auto-upgrades
fi

EXISTS=$(grep "APT::Periodic::Unattended-Upgrade \"1\"" /etc/apt/apt.conf.d/20auto-upgrades)
if [ -z "$EXISTS" ]; then
	echo "APT::Periodic::Unattended-Upgrade \"1\";" >> /etc/apt/apt.conf.d/20auto-upgrades
fi

EXISTS=$(grep "APT::Periodic::AutocleanInterval \"7\"" /etc/apt/apt.conf.d/10periodic)
if [ -z "$EXISTS" ]; then
	echo "APT::Periodic::AutocleanInterval \"7\";" >> /etc/apt/apt.conf.d/10periodic
fi

chmod 644 /etc/apt/apt.conf.d/20auto-upgrades
chmod 644 /etc/apt/apt.conf.d/10periodic

#disable error-reporting services

echo "Turning off error-reporting software."
systemctl stop apport.service
systemctl disable apport.service
systemctl mask apport.service

systemctl stop whoopsie.service
systemctl disable whoopsie.service
systemctl mask whoopsie.service

#disabling apport (error-reporter)
sed -ie '/^enabled=1$/ s/1/0/' /etc/default/apport
sed -ie '/^enabled=1$/ s/1/0/' /etc/default/whoopsie

sudo -H -u "$USER" dbus-launch gsettings set com.ubuntu.update-notifier show-apport-crashes false

#fixing permissions in var
echo "Fixing /var permissions"
chmod o-w /var/crash
chmod o-w /var/metrics
chmod o-w /var/tmp

#disabling privacy-leaking from Unity
EXISTS=$(grep "user-db:user" /etc/dconf/profile/user)
if [ -z "$EXISTS" ]; then
	echo "user-db:user" >> /etc/dconf/profile/user
fi

EXISTS=$(grep "system-db:local" /etc/dconf/profile/user)
if [ -z "$EXISTS" ]; then
	echo "system-db:local" >> /etc/dconf/profile/user
fi
dconf update

#setting up firewall without rules
ufw enable

echo "Hardening complete."
read -p "Want to reboot now? [y/n]: " CONFIRM
if [ "$CONFIRM" == "y" ]; then
	reboot
fi

