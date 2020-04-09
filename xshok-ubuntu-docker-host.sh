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
# to set the swapfile size to 1GB, set the env SWAPFILE_SIZE to 1 (export SWAPFILE_SIZE=1)
#
# Usage:
# wget https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-ubuntu-docker-host.sh -O xshok-ubuntu-docker-host.sh && chmod +x xshok-ubuntu-docker-host.sh && ./xshok-ubuntu-docker-host.sh
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#
################################################################################

# Set the local
export LANG="en_US.UTF-8"
export LC_ALL="C"

if [ "$(lsb_release -i 2>/dev/null | cut -f 2 | xargs)" != "Ubuntu" ] ; then
  echo "ERROR: This script only supports Ubuntu"
  exit 1
fi

if [ -f "/etc/extremeshok" ] ; then
  echo "Script can only be run once"
  exit 1
fi

## Force APT to use IPv4
echo -e "Acquire::ForceIPv4 \"true\";\\n" > /etc/apt/apt.conf.d/99force-ipv4

## Refresh the package lists
apt-get update > /dev/null 2>&1

## Remove conflicting utilities
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' purge snapd ntp openntpd snap lxd bind bluez docker docker-engine docker.io containerd runc

## Update
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' dist-upgrade

## Install common system utilities
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install \
apt-transport-https \
aptitude \
axel \
build-essential \
ca-certificates \
curl \
dialog \
dos2unix \
dpkg-dev \
git \
gnupg-agent \
htop \
iftop \
iotop \
iperf \
ipset \
iptraf \
mlocate \
nano \
net-tools \
pigz \
python3-pip \
software-properties-common \
sshpass \
tmux \
unzip zip \
vim \
vim-nox \
wget
whois \

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

## Disable SSH password logins for root user (security)
if cat "${HOME}/.ssh/authorized_keys" | tail -n 1 | cut -d' ' -f 1 | grep -q 'ssh-' ; then
  echo "SSH authorized_keys detected, Disabling password login"
  sed -i 's|#PermitRootLogin yes|PermitRootLogin without-password|g' /etc/ssh/sshd_config
  sed -i 's|PermitRootLogin yes|PermitRootLogin without-password|g' /etc/ssh/sshd_config
  sed -i 's|#PermitRootLogin no|PermitRootLogin without-password|g' /etc/ssh/sshd_config
  sed -i 's|PermitRootLogin no|PermitRootLogin without-password|g' /etc/ssh/sshd_config
  sed -i 's|#HostKey /etc/|HostKey /etc/|g' /etc/ssh/sshd_config
  sed -i 's|#UseDNS yes|UseDNS no|g' /etc/ssh/sshd_config
  sed -i 's|UseDNS yes|UseDNS no|g' /etc/ssh/sshd_config
  sed -i 's|#MaxAuthTries 6|MaxAuthTries 3|g' /etc/ssh/sshd_config
  sed -i 's|MaxAuthTries 6|#MaxAuthTries 3|g' /etc/ssh/sshd_config
  systemctl reload ssh
fi

## Disable local dns server, do not disable systemd-resolved as this breaks nameservers configured with netplan
sed -i 's|#DNSStubListener=yes|DNSStubListener=no|g' /etc/systemd/resolved.conf
sed -i 's|DNSStubListener=yes|DNSStubListener=no|g' /etc/systemd/resolved.conf
sed -i 's|#DNSStubListener=no|DNSStubListener=no|g' /etc/systemd/resolved.conf
rm -rf /etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved.service


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

## Create a swapfile
SWAPFILE_SIZE=${SWAPFILE_SIZE:-4}
if [ "${SWAPFILE_SIZE}" != "0" ] ; then
  echo "Creating ${SWAPFILE_SIZE}G swapfile"
  fallocate -l ${SWAPFILE_SIZE}G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
  swapon --show
fi

## Pretty MOTD BANNER
if [ -z "${NO_MOTD_BANNER}" ] ; then
  if [ ! -f "/etc/update-motd.d/99-extremeshok" ] ; then
    sed -i 's|PrintMotd no|PrintMotd yes|g' /etc/ssh/sshd_config
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

## Increase max user watches
# BUG FIX : No space left on device
echo "fs.inotify.max_user_instances=524288" >> /etc/sysctl.conf
echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
echo "fs.inotify.max_queued_events=524288" >> /etc/sysctl.conf
## Set max map count, required for elasticsearch
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
## Apply sysctl.conf
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
EOF
# Enable Update Origins
sed -i 's|\/\/.*"\${distro_id}:\${distro_codename}"|"\${distro_id}:\${distro_codename}"|' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's|\/\/.*"\${distro_id}:\${distro_codename}-security"|"\${distro_id}:\${distro_codename}-security"|' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's|\/\/.*"\${distro_id}:\${distro_codename}-updates"|"\${distro_id}:\${distro_codename}-updates"|' /etc/apt/apt.conf.d/50unattended-upgrades


## Increase kernel max Key limit
cat <<EOF > /etc/sysctl.d/99-xs-maxkeys.conf
# eXtremeSHOK.com
# Increase kernel max Key limit
kernel.keys.root_maxkeys=1000000
kernel.keys.maxkeys=1000000
EOF

## Enable TCP BBR congestion control
cat <<EOF > /etc/sysctl.d/99-xs-kernel-bbr.conf
# eXtremeSHOK.com
# TCP BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

## Memory Optimising
cat <<EOF > /etc/sysctl.d/99-xs-memory.conf
# eXtremeSHOK.com
# Memory Optimising
vm.min_free_kbytes=65536
vm.nr_hugepages=72
# (Redis/MongoDB)
vm.overcommit_memory = 1
EOF

## Enable IPv6
cat <<EOF > /etc/sysctl.d/99-xs-ipv6.conf
# eXtremeSHOK.com
# Enable IPv6
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
EOF

## TCP fastopen
cat <<EOF > /etc/sysctl.d/99-xs-tcp-fastopen.conf
# eXtremeSHOK.com
# TCP fastopen
net.ipv4.tcp_fastopen=3
EOF

## Bugfix: high swap usage with low memory usage
cat <<EOF > /etc/sysctl.d/99-xs-swappiness.conf
# eXtremeSHOK.com
# Bugfix: high swap usage with low memory usage
vm.swappiness=10
EOF

## FS Optimising
cat <<EOF > /etc/sysctl.d/99-xs-tcp-fastopen.conf
# eXtremeSHOK.com
# FS Optimising
fs.nr_open=12000000
fs.file-max=9000000
EOF

## Net optimising
cat <<EOF > /etc/sysctl.d/99-xs-net.conf
# eXtremeSHOK.com
net.core.netdev_max_backlog=8192
net.core.optmem_max=8192
net.core.rmem_max=16777216
net.core.somaxconn=8151
net.core.wmem_max=16777216
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_base_mss = 1024
net.ipv4.tcp_challenge_ack_limit = 999999999
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_time=240
net.ipv4.tcp_limit_output_bytes=65536
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_rmem=8192 87380 16777216
net.ipv4.tcp_sack=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_syn_retries=3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_wmem=8192 65536 16777216
net.netfilter.nf_conntrack_generic_timeout = 60
net.netfilter.nf_conntrack_helper=0
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_tcp_timeout_established = 28800
net.unix.max_dgram_qlen = 4096
EOF


## Disable Transparent Hugepage, required for mongodb, redis
cat <<EOF > /etc/systemd/system/docker-hugepage-fix.service
[Unit]
Description="Disable Transparent Hugepage before Docker boots"
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
RequiredBy=docker.service
EOF
systemctl daemon-reload
systemctl enable docker-hugepage-fix

## Ensure Entropy Pools are Populated, prevents slowdowns whilst waiting for entropy
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install haveged
## Net optimising
cat <<EOF > /etc/default/haveged
# eXtremeSHOK.com
#   -w sets low entropy watermark (in bits)
DAEMON_ARGS="-w 1024"
EOF
systemctl daemon-reload
systemctl enable haveged

## Limit the size and optimise journald
cat <<EOF > /etc/systemd/journald.conf
# eXtremeSHOK.com
[Journal]
# Store on disk
Storage=persistent
# Don't split Journald logs by user
SplitMode=none
# Disable rate limits
RateLimitInterval=0
RateLimitIntervalSec=0
RateLimitBurst=0
# Disable Journald forwarding to syslog
ForwardToSyslog=no
# Journald forwarding to wall /var/log/kern.log
ForwardToWall=yes
# Disable signing of the logs, save cpu resources.
Seal=no
Compress=yes
# Fix the log size
SystemMaxUse=64M
RuntimeMaxUse=60M
# Optimise the logging and speed up tasks
MaxLevelStore=warning
MaxLevelSyslog=warning
MaxLevelKMsg=warning
MaxLevelConsole=notice
MaxLevelWall=crit
EOF
systemctl restart systemd-journald.service
journalctl --vacuum-size=64M --vacuum-time=1d;
journalctl --rotate

## Docker-ce
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=$(dpkg-architecture -q DEB_BUILD_ARCH)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update > /dev/null 2>&1
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install docker-ce docker-ce-cli containerd.io

## Docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

##  Download eXtremeSHOK.com Docker Scripts
if [ ! -d "/datastore" ] ; then
  mkdir -p /datastore
  cd /datastore || exit
  git clone https://github.com/extremeshok/xshok-docker.git
fi

echo "eXtremeSHOK.com Optimised" > /etc/extremeshok

cat /etc/update-motd.d/99-extremeshok
## Script Finish
echo -e '\033[1;33m Finished....please restart the system \033[0m'
