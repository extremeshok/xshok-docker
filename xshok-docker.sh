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

################# Script Info
script_version="1.2"
script_version_date="2020-12-21"

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

# Check for a new version
function check_new_version() {
    found_upgrade="no"
    # shellcheck disable=SC2086
    latest_version="$(curl --compressed --connect-timeout "30" --remote-time --location --retry "3" --max-time "30" "https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-docker.sh" 2> /dev/null | grep "^script_version=" | head -n1 | cut -d '"' -f 2)"
    if [ "$latest_version" != "" ] ; then
        # shellcheck disable=SC2183,SC2086
        if [ "$(printf "%02d%02d%02d%02d" ${latest_version//./ })" -gt "$(printf "%02d%02d%02d%02d" ${script_version//./ })" ] ; then
            echo "------------------------------"
            echo "ALERT: New version : v${latest_version} @ https://github.com/extremeshok/docker-webserver"
            found_upgrade="yes"
        fi
    fi

    if [ "$found_upgrade" == "yes" ] ; then
        echo "Quickly upgrade, run the following command as root:"
        echo "bash xshok-admin.sh --upgrade"
    fi

}


# Auto upgrade the master.conf and the
function xshok_upgrade() {

    if ! xshok_is_root ; then
        echo "ERROR: Only root can run the upgrade"
        exit 1
    fi

    echo "Checking for updates ..."

    found_upgrade="no"
    latest_version="$(curl --compressed  --connect-timeout "30" --remote-time --location --retry "3" --max-time "30" "https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-docker.sh" 2> /dev/null | grep "^script_version=" | head -n1 | cut -d '"' -f 2)"

    if [ "$latest_version" != "" ] ; then
        # shellcheck disable=SC2183,SC2086
        if [ "$(printf "%02d%02d%02d%02d" ${latest_version//./ })" -gt "$(printf "%02d%02d%02d%02d" ${script_version//./ })" ] ; then
            found_upgrade="yes"
            echo "ALERT:  Upgrading script from v${script_version} to v${latest_version}"
            echo "Downloading https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-docker.sh"

            curl --fail --compressed --connect-timeout "30" --remote-time --location --retry "3" --max-time "30" --time-cond "${DIRNAME}/xshok-docker.sh.tmp" --output "${DIRNAME}/xshok-docker.sh.tmp"  "https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-docker.sh"  2> /dev/null
            ret=$?
            if [ "$ret" -ne 0 ] ; then
                echo "ERROR: Could not download https://raw.githubusercontent.com/extremeshok/xshok-docker/master/xshok-docker.sh"
                exit 1
            fi
            # Detect to make sure the entire script is avilable, fail if the script is missing contents
            if [ "$(tail -n 1 "${DIRNAME}/xshok-docker.sh.tmp" | head -n 1 | cut -c 1-7)" != "exit \$?" ] ; then
                echo "ERROR: Downloaded xshok-admin.sh is incomplete, please re-run"
                exit 1
            fi
            # Copy over permissions from old version
            OCTAL_MODE="$(stat -c "%a" "${DIRNAME}/xshok-docker.sh")"

            echo "Inserting update process..."
            # Generate the update script
            cat > "/datastore/xshok_update_script.sh" << EOF
#!/usr/bin/env bash
echo "Running update process"
# Overwrite old file with new
if ! mv -f "${DIRNAME}/xshok-docker.sh.tmp" "${DIRNAME}/xshok-docker.sh" ; then
  echo  "ERROR: failed moving ${DIRNAME}/xshok-docker.sh.tmp to ${DIRNAME}/xshok-docker.sh"
  rm -f \$0
    exit 1
fi
if ! chmod "$OCTAL_MODE" "${DIRNAME}/xshok-docker.sh" ; then
     echo "ERROR: unable to set permissions on ${DIRNAME}/xshok-docker.sh"
     rm -f \$0
     exit 1
fi
    echo "Completed"

    #remove the tmp script before exit
    rm -f \$0
EOF
            # Replaced with $0, so code will update and then call itself with the same parameters it had
            #exec "${0}" "$@"
            bash_bin="$(command -v bash 2> /dev/null)"
            exec "$bash_bin" "/datastore/xshok_update_script.sh"
            echo "Running once as root"
        fi
    fi

    if [ "$found_upgrade" == "no" ] ; then
        echo "No updates available"
    fi
}

################# XSHOK ADVANCED FUNCTIONS  :: END

echo "eXtremeSHOK.com Docker ${script_version} (${script_version_date})"

help_message(){
  echo -e "\033[1mDOCKER OPTIONS\033[0m"
  echo "${EPACE}${EPACE} start docker-compose.yml"
  echo "${EPACE}-u | --up | --start | --init"
  echo "${EPACE}${EPACE} stop all dockers and d cker-compose"
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
  echo "${EPACE}--upgrade"
echo "${EPACE}${EPACE} upgrades the script to the latest version"
  echo "${EPACE}-H, --help"
}

if [ -z "${1}" ]; then
  help_message
              check_new_version
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
      --upgrade)
    xshok_upgrade
    shift
    ;;
    *)
      help_message
                  check_new_version
      ;;
  esac
  shift
done

# And lastly we exit, Note: the exit is always on the 2nd last line
exit $?
