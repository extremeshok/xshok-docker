#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
#
# Script updates can be found at: https://github.com/extremeshok/xshok-docker
#
# Ubuntu to optimised docker host, will optimise and install utilities, docker, docker-composer
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
# Assumptions: Ubuntu installed
#
# Tested on KVM, VirtualBox and Dedicated Server
#
# Notes:
# to disable the MOTD banner, set the env NO_MOTD_BANNER to true (export NO_MOTD_BANNER=true)
#
# Usage:
# curl -O https://raw.githubusercontent.com/extremeshok/xshok-docker/master/ubuntu-optimised-docker-host.sh && chmod +x ubuntu-optimised-docker-host.sh
# ./ubuntu-optimised-docker-host.sh
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#
################################################################################

# Set the local
export LANG="en_US.UTF-8"
export LC_ALL="C"

## Force APT to use IPv4
echo -e "Acquire::ForceIPv4 \"true\";\\n" > /etc/apt/apt.conf.d/99force-ipv4

## Refresh the package lists
apt-get update > /dev/null

## Remove conflicting utilities
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' purge ntp openntpd snap lxd bind docker bluez docker docker-engine docker.io containerd runc

## Update
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' dist-upgrade

## Install common system utilities
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install \
aptitude \
apt-transport-https \
axel \
build-essential \
ca-certificates \
curl \
dialog \
dos2unix \
git \
gnupg-agent \
htop \
iotop \
iperf \
iptraf \
ipset \
iftop \
mlocate \
nano \
net-tools \
pigz \
whois \
software-properties-common \
sshpass \
tmux \
unzip zip \
vim \
vim-nox \
wget

## Remove no longer required packages and purge old cached updates
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' autoremove
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' autoclean

## Detect if virtual machine and install guest agent
if [ "$(dmidecode -s system-manufacturer | xargs)" == "QEMU" ] || [ "$(systemd-detect-virt | xargs)" == "kvm" ] ; then
  echo "QEMU Detected, installing guest agent"
  /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install qemu-guest-agent
elif [ "$(systemd-detect-virt | xargs)" == "vmware" ] ; then
  echo "VMware Detected, installing vm-tools"
  /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install open-vm-tools
elif [ "$(systemd-detect-virt | xargs)" == "oracle" ] ; then
  echo "Virtualbox Detected, installing guest-utils"
  /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install virtualbox-guest-utils
fi

## Detect cloud-init device and install cloud-init
if [ "$(systemd-detect-virt | xargs)" != "None" ] ; then
  if [ -r "/dev/sr0" ] ; then #sr0 = link for cdrom
    if [ "$(blkid -o export /dev/sr0 | grep "LABEL" | cut -d'=' -f 2 | xargs)" == "cidata" ] ; then
      echo "Cloud-init device Detected, installing cloud-init"
      /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install cloud-init
    fi
  fi
fi

## Disable portmapper / rpcbind (security)
systemctl disable rpcbind
systemctl stop rpcbind

## Set Timezone to UTC and enable NTP
timedatectl set-timezone UTC
cat <<'EOF' > /etc/systemd/timesyncd.conf
[Time]
NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
FallbackNTP=0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org
RootDistanceMaxSec=5
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOF
service systemd-timesyncd start
timedatectl set-ntp true

## Bugfix: high swap usage with low memory usage
echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl -p


## Pretty MOTD BANNER
if [ -z "${NO_MOTD_BANNER}" ] ; then
  if [ -d "/etc/update-motd.d/" ] ; then
    if [ ! -f "/etc/update-motd.d/99-extremeshok" ] ; then
      cat <<'EOF' > /etc/update-motd.d/99-extremeshok
   This system is optimised by:            https://eXtremeSHOK.com
     __   ___                            _____ _    _  ____  _  __
     \ \ / / |                          / ____| |  | |/ __ \| |/ /
  ___ \ V /| |_ _ __ ___ _ __ ___   ___| (___ | |__| | |  | | ' /
 / _ \ > < | __| '__/ _ \ '_ ` _ \ / _ \\___ \|  __  | |  | |  <
|  __// . \| |_| | |  __/ | | | | |  __/____) | |  | | |__| | . \
 \___/_/ \_\\__|_|  \___|_| |_| |_|\___|_____/|_|  |_|\____/|_|\_\
EOF
    fi
  fi
fi

## Increase max user watches
# BUG FIX : No space left on device
echo 1048576 > /proc/sys/fs/inotify/max_user_watches
echo "fs.inotify.max_user_watches=1048576" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
## Increase max FD limit / ulimit
cat <<'EOF' >> /etc/security/limits.conf
# eXtremeSHOK.com Increase max FD limit / ulimit
* soft     nproc          256000
* hard     nproc          256000
* soft     nofile         256000
* hard     nofile         256000
root soft     nproc          256000
root hard     nproc          256000
root soft     nofile         256000
root hard     nofile         256000
EOF

## Increase kernel max Key limit
cat <<EOF > /etc/sysctl.d/60-maxkeys.conf
# eXtremeSHOK.com
# Increase kernel max Key limit
kernel.keys.root_maxkeys=1000000
kernel.keys.maxkeys=1000000
EOF

## Set systemd ulimits
echo "DefaultLimitNOFILE=256000" >> /etc/systemd/system.conf
echo "DefaultLimitNOFILE=256000" >> /etc/systemd/user.conf
echo 'session required pam_limits.so' | tee -a /etc/pam.d/common-session-noninteractive
echo 'session required pam_limits.so' | tee -a /etc/pam.d/common-session
echo 'session required pam_limits.so' | tee -a /etc/pam.d/runuser-l

## Set ulimit for the shell user
cd ~ && echo "ulimit -n 256000" >> .bashrc ; echo "ulimit -n 256000" >> .profile

## Enable unattended upgrades
cat <<'EOF' > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

## Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update > /dev/null
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install docker-ce docker-ce-cli containerd.io

## Docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

#statements
#cloud-init,

## Script Finish
echo -e '\033[1;33m Finished....please restart the system \033[0m'
