# xshok-docker :: eXtremeSHOK.com Docker

Scripts for working with docker

## Docker Optimization / Post Install Script for Ubuntu (ubuntu-optimised-docker-host.sh) *run once*
* Force APT to use IPv4
* Remove conflicting utilities
* Update and Install common system utilities
* Remove no longer required packages and purge old cached updates
* Detect if virtual machine and install guest agent (qemu/kvm, vmware, virtualbox)
* Detect cloud-init device and install cloud-init
* Disable portmapper / rpcbind (security)
* Disable SSH password logins (security) if Authorized_keys detected
* Disable local dns server, do not disable systemd-resolved as this breaks nameservers configured with netplan
* set-timezone UTC and enable timesyncd as nntp client
* Create an 8GB swapfile (configurable with SWAPFILE_SIZE)
* Bugfix: high swap usage with low memory usage
* Pretty MOTD BANNER (configurable with NO_MOTD_BANNER)
* Increase max user watches
* Increase max FD limit / ulimit
* Increase kernel max Key limit
* Set systemd ulimits
* Set ulimit for the shell user
* Enable unattended upgrades
* Install Docker-ce
* Install Docker-compose
* Enable TCP BBR congestion control, improves overall network throughput

** Notes: 
to disable the MOTD banner, set the env NO_MOTD_BANNER to true (export NO_MOTD_BANNER=true) **
to set the swapfile size to 1GB, set the env SWAPFILE_SIZE to 1 (export SWAPFILE_SIZE=1)
```
wget https://raw.githubusercontent.com/extremeshok/xshok-docker/master/ubuntu-optimised-docker-host.sh -O ubuntu-optimised-docker-host.sh && chmod +x ubuntu-optimised-docker-host.sh && ./ubuntu-optimised-docker-host.sh
```
