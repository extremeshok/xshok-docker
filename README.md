# xshok-docker :: eXtremeSHOK.com Docker

Scripts for working with docker

## Docker Optimization / Post Install Script for Ubuntu (xshok-ubuntu-docker-host.sh) *run once*
Turns a fresh ubuntu install into an optimised docker host
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
* Create a swapfile (default is 4GB, configurable with SWAPFILE_SIZE)
* Bugfix: high swap usage with low memory usage
* Pretty MOTD BANNER (configurable with NO_MOTD_BANNER)
* Increase max user watches
* Increase max FD limit / ulimit
* Increase kernel max Key limit
* Set systemd ulimits
* Set ulimit for the shell user
* Enable unattended upgrades
* Install Docker-ce withdocker-ce-cli containerd.io aufs-tools cgroupfs-mount docker-ce-rootless-extras slirp4netns
* Install Docker-compose
* Enable TCP BBR congestion control, improves overall network throughput
* Disable Transparent Hugepage before Docker boots
* Install Borgmatic and Borgbase for backups
* Sample borgmatic config installed at /etc/borgmatic/config.yaml

### Notes:
* to disable the MOTD banner, set the env NO_MOTD_BANNER to true (export NO_MOTD_BANNER=true)
* to set the swapfile size to 1GB, set the env SWAPFILE_SIZE to 1 (export SWAPFILE_SIZE=1)
* Disable swapfile (export SWAPFILE_SIZE=0)
```
wget https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-ubuntu-docker-host.sh -O xshok-ubuntu-docker-host.sh && chmod +x xshok-ubuntu-docker-host.sh && ./xshok-ubuntu-docker-host.sh
```

# xshok-docker.sh  (single script replaces all separate scripts)
```
eXtremeSHOK.com Docker
DOCKER OPTIONS
       start docker-compose.yml
   -u | --up | --start | --init
       stop all dockers and docker-compose
   -d | --down | --stop
       quickly restart docker-compose
   -r | --restart | --quickupdown | --quick-up-down | --reload
       reset docker-compose (down and then up)
   -R | --reset | --updown | --up-down
       stop and remove dockers, will NOT remove volumes
   -p | --prune | --clean
ADVANCED OPTIONS
       creates a systemd service to start docker and run docker-compose.yml on boot
   -b | --boot | --service | --systemd
       make pretty images of the docker-compose topology
   -v | --vis | --visuliser
GENERAL OPTIONS
    --upgrade
       upgrades the script to the latest version
   -H, --help
       Display help and exit.
```
### NOTES:
*  Script must be placed into the same directory as the docker-compose.yml
```
wget https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-docker.sh -O xshok-docker.sh && chmod +x xshok-docker.sh
bash xshok-docker.sh
```
## Docker Initialization / Start docker-compose.yml (xshok-docker.sh --start)
Starts your docker-compose based containers properly
* Automatically creates volume directories and touches volume files
* Stops all running containers
* Removes any orphaned containers
* Pull/download dependencies and images
* Forces recreation of all containers and will build required containers

## Docker Cleaning / Stop docker-compose.yml (xshok-docker.sh --clean)
Stops your docker-compose based containers properly
* Stops all running containers
* Removes any orphaned containers amd images

## Creates a systemd service to start/stop docker-compose.yml  (xshok-docker.sh --boot)
Creates a systemd service to start / stop your docker-compose
* On Start: Forces recreation of all containers and will build required containers
* On Stop: Stops all running containers, Removes any orphaned containers
* On Reload: quickest, docker-compose stop and start
