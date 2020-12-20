#!/usr/bin/env bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
#
# Script updates can be found at: https://github.com/extremeshok/xshok-docker
#
# Starts your docker-compose based containers properly
#
# Automatically creates volume directories and touches volume files
# Stops all running containers
# Removes any orphaned containers
# Pull/download dependencies and images
# Forces recreation of all containers and will build required containers
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
# Assumptions: Docker and Docker-compose Installed
#
# Tested on KVM, VirtualBox and Dedicated Server
#
# Notes:
# Script must be placed into the same directory as the docker-compose.yml
#
# Usage:
# wget https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-init-docker.sh -O xshok-init-docker.sh && chmod +x xshok-init-docker.sh
# bash xshok-init-docker.sh
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#
################################################################################

PWD="/datastore"
EPACE='   '

source "${PWD}/.env"

## GLOBALS
DIRNAME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${DIRNAME}" || exit 1

################# SUPPORTING FUNCTIONS :: START

################# SUPPORTING FUNCTIONS  :: END

################# XSHOK FUNCTIONS  :: START

################# docker start
xshok_docker_up(){

  #Automatically create required volume dirs
  ## remove all comments
  TEMP_COMPOSE="/tmp/xs_$(date +"%s")"
  sed -e '1{/^#!/ {p}}; /^[\t\ ]*#/d;/\.*#.*/ {/[\x22\x27].*#.*[\x22\x27]/ !{:regular_loop s/\(.*\)*[^\]#.*/\1/;t regular_loop}; /[\x22\x27].*#.*[\x22\x27]/ {:special_loop s/\([\x22\x27].*#.*[^\x22\x27]\)#.*/\1/;t special_loop}; /\\#/ {:second_special_loop s/\(.*\\#.*[^\]\)#.*/\1/;t second_special_loop}}' docker-compose.yml > "$TEMP_COMPOSE"
  mkdir -p "${PWD}/volumes/"
  VOLUMEDIR_ARRAY=$(grep "device:.*\${PWD}/volumes/" "$TEMP_COMPOSE")
  for VOLUMEDIR in $VOLUMEDIR_ARRAY ; do
    if [[ $VOLUMEDIR =~ "\${PWD}" ]]; then
      VOLUMEDIR="${VOLUMEDIR/\$\{PWD\}\//}"
      if [ ! -d "$VOLUMEDIR" ] ; then
        if [ ! -f "$VOLUMEDIR" ] && [[ $VOLUMEDIR != *.* ]] ; then
          echo "Creating dir: $VOLUMEDIR"
          mkdir -p "$VOLUMEDIR"
          chmod 777 "$VOLUMEDIR"
        elif [ ! -d "$VOLUMEDIR" ] && [[ $VOLUMEDIR == *.* ]] ; then
          echo "Creating file: $VOLUMEDIR"
          touch -p "$VOLUMEDIR"
        fi
      fi
    fi
  done
  rm -f "$TEMP_COMPOSE"

  docker-compose down --remove-orphans
  # detect if there are any running containers and manually stop and remove them
  if docker ps -q 2> /dev/null ; then
    docker stop $(docker ps -q)
    sleep 1
    docker rm $(docker ps -q)
  fi

  docker-compose pull --include-deps
  docker-compose up -d --force-recreate --build

}

################# docker stop
xshok_docker_down(){
  docker-compose down
  sync
  docker stop $(docker ps -q)
  sync
}

################# docker restart
xshok_docker_restart(){
  docker-compose down
  sync
  sleep 3
  docker-compose up -d
}

################# docker prune
xshok_docker_prune(){
  echo "Removing images, will NOT remove volumes"
  docker system prune -a -f
}

################# XSHOK FUNCTIONS  :: END

################# XSHOK ADVANCED FUNCTIONS  :: START
################# docker boot
xshok_docker_boot(){

  if [ ! -d "/etc/systemd/system/" ] ; then
    echo "ERROR: systemd not detected"
    exit 1
  fi

  # remove beginning /
  THISNAME="${DIRNAME#/}"
  # remove ending /
  THISNAME="${THISNAME%/}"
  # space with -
  THISNAME="${THISNAME// /-}"
  # / with _
  THISNAME="${THISNAME//\/_}"
  # remove .
  THISNAME="${THISNAME//\.}"

  echo "Generating Systemd service"
  cat << EOF > "/etc/systemd/system/docker-${THISNAME}.service"
[Unit]
Description=Docker Compose ${THISNAME} Service
Requires=docker.service
After=docker.service

[Install]
WantedBy=multi-user.target

[Service]
Type=oneshot
TimeoutStartSec=0
RemainAfterExit=yes
WorkingDirectory=${DIRNAME}
EOF

  if [ -f "${DIRNAME}/xshok-docker.sh" ] ; then
    echo "ExecStart=/bin/bash ${DIRNAME}/xshok-docker.sh --start" >> "/etc/systemd/system/docker-${THISNAME}.service"
    echo "ExecStop=/bin/bash ${DIRNAME}/xshok-docker.sh --stop" >> "/etc/systemd/system/docker-${THISNAME}.service"
    echo "ExecReload=/bin/bash ${DIRNAME}/xshok-docker.sh --reload" >> "/etc/systemd/system/docker-${THISNAME}.service"
  else
    echo "ExecStart=/usr/local/bin/docker-compose up -d --force-recreate --build" >> "/etc/systemd/system/docker-${THISNAME}.service"
    echo "ExecStop=/usr/local/bin/docker-compose down" >> "/etc/systemd/system/docker-${THISNAME}.service"
    echo "ExecStop=/usr/local/bin/docker-compose restart" >> "/etc/systemd/system/docker-${THISNAME}.service"
  fi

  echo "Created: /etc/systemd/system/docker-${THISNAME}.service"
  systemctl daemon-reload
  systemctl enable "docker-${THISNAME}"

  echo "Available Commands:"
  echo "Start-> systemctl start docker-${THISNAME}"
  echo "Stop-> systemctl stop docker-${THISNAME}"
  echo "Reload-> systemctl reload docker-${THISNAME}"
}

################# docker visulise
xshok_docker_visualise(){

  TEMP_VIS="/tmp/xs_vis_$(date +"%s")/"
  mkdir -p "${TEMP_VIS}"
  if [ -d "${TEMP_VIS}" ] && [ -w "${TEMP_VIS}" ] ; then
    echo "Generating Docker Visualisations"
    chmod 777 "${TEMP_VIS}"
    docker-compose config > "${TEMP_VIS}/docker-compose.yml"
    docker run --rm -it --name dcv -v "${TEMP_VIS}:/input:rw" pmsipilot/docker-compose-viz render -m image -o docker-vis-full.png --horizontal --force /input/docker-compose.yml
    mv -f "${TEMP_VIS}/docker-vis-full.png" "${DIRNAME}/docker-vis-full.png"
    docker run --rm -it --name dcv -v "${TEMP_VIS}:/input:rw" pmsipilot/docker-compose-viz render -m image -o docker-vis-novols.png --horizontal --no-volumes --force /input/docker-compose.yml
    mv -f "${TEMP_VIS}/docker-vis-novols.png" "${DIRNAME}/docker-vis-novols.png"
    rm -rf "${TEMP_VIS}"
    echo "Completed, images saved to ${DIRNAME}"

  else
    echo "ERROR, failed to create temp dir or not writable: ${TEMP_VIS}"
    exit 1
  fi
}

xshok_docker_maintenance(){

  df -h /
  if command -v apt-get > /dev/null; then
    apt-get autoremove
    apt-get clean
  fi

  #empty journalctl
  if command -v journalctl > /dev/null; then
     journalctl --vacuum-size=500M
  fi

  #remove error logs
  rm -f /datastore/*/logs/error.log.*

  df -h /
}

################# XSHOK ADVANCED FUNCTIONS  :: END

echo "eXtremeSHOK.com Docker"

help_message(){
  echo -e "\033[1mDOCKER OPTIONS\033[0m"
  echo "${EPACE}${EPACE} start docker-compose.yml"
  echo "${EPACE}-u | --up | --start | --init"
  echo "${EPACE}${EPACE} stop all dockers and docker-compose"
  echo "${EPACE}-d | --down | --stop"
  echo "${EPACE}${EPACE} quickly restart docker-compose"
  echo "${EPACE}-r | --restart | --quickupdown | --quick-up-down | --reload"
  echo "${EPACE}${EPACE} reset docker-compose (down and then up)"
  echo "${EPACE}-R | --reset | --updown | --up-down"
  echo "${EPACE}${EPACE} stop and remove dockers, will NOT remove volumes"
  echo "${EPACE}-p | --prune | --clean"
  echo -e "\033[1mADVANCED OPTIONS\033[0m"
  echo "${EPACE}${EPACE} creates a systemd service to start docker and run docker-compose.yml on boot"
  echo "${EPACE}-b | --boot | --service | --systemd"
  echo "${EPACE}${EPACE} make pretty images of the docker-compose topology"
  echo "${EPACE}-v | --vis | --visuliser"
  echo -e "\033[1mGENERAL OPTIONS\033[0m"
  echo "${EPACE}${EPACE}Display help and exit."
  echo "${EPACE}-H, --help"
}

if [ -z "${1}" ]; then
  help_message
  exit 1
fi

## VALIDATION
if [ ! -f "docker-compose.yml" ] ; then
  echo "ERROR: docker-compose.yml not found, script must be run in the same directory"
  exit 1
fi

if ! docker-compose config > /dev/null ; then
  echo "ERROR: docker-compose.yml failed config check"
  exit 1
fi

while [ ! -z "${1}" ]; do
  case ${1} in
    -[hH] | --help )
      help_message
      ;;
    -u | --up | --start | --init )
      xshok_docker_up
      ;;
    -d | --down | --stop )
      xshok_docker_down
      ;;
    -r | --restart | --quickupdown | --quick-up-down | --reload )
      xshok_docker_restart
      ;;
    -R | --reset | --updown | --up-down )
      xshok_docker_down
      xshok_docker_up
      ;;
    -p | --prune | --clean | --purge )
      xshok_docker_down
      xshok_docker_prune
      ;;
      ## ADVANCED
    -b | --boot | --service | --systemd )
      xshok_docker_boot
      ;;
    -v | --vis | --visuliser )
      xshok_docker_visualise
      ;;
    -m | --maintenance )
      xshok_docker_maintenance
      ;;
    *)
      help_message
      ;;
  esac
  shift
done
