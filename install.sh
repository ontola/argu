#!/bin/bash

if [ $EUID != 0 ]; then
    sudo -E "$0" "$@"
    exit $?
fi

USR=$SUDO_USER
USR_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)

clone_project() {
  if [ ! -d $DEV_HOME/$1/$2/$3 ]
  then
    echo Running $USR mkdir -p $DEV_HOME/$1/$2/$3
    sudo -u $USR mkdir -p $DEV_HOME/$1/$2/$3
  fi
  if [ "$(ls -A $DEV_HOME/$1/$2/$3)" ]
  then
    echo Skipping directory $DEV_HOME/$1/$2/$3, not empty
    return
  fi
  sudo -u $USR git clone --recursive git@$1:$2/$3.git $DEV_HOME/$1/$2/$3
}

clone_projects() {
 clone_project bitbucket.org arguweb devproxy
 clone_project bitbucket.org arguweb argu
 clone_project bitbucket.org arguweb aod_search
 clone_project bitbucket.org arguweb email_service
 clone_project bitbucket.org arguweb token_service
 clone_project bitbucket.org arguweb service_module
 clone_project bitbucket.org arguweb surveys
 clone_project bitbucket.org arguweb survey_builder

 clone_project bitbucket.org fletcher91 ruby-vips-qt-unicorn

 clone_project github.com fletcher91 link-lib
 clone_project github.com fletcher91 link-redux
}

create_tree() {
  if [ ! -d $DEV_HOME  ]
  then
    sudo -u $USR mkdir -p $DEV_HOME
  fi
}

ensure_hosts() {
  if !(grep -xq "$1\s*$2" /etc/hosts)
  then
    echo $1     $2 >> /etc/hosts
  fi
}

install_adapter() {
 echo install nic adapter
}

install_compose() {
  echo install compose
  pip install docker-compose
}

install_dependencies() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew update
    echo "Proper dependency installation not yet implemented for osx (so ticket+PR)"
  elif [[ "$OSTYPE" == "win32" ]]; then
    echo "Dependency installation not yet implemented for windows (so ticket+PR)"
  else
    sudo apt-get -qq install -y \
      apt-transport-https \
      build-essential \
      ca-certificates \
      curl \
      libnss3-tools \
      python-setuptools \
      python-dev \
      software-properties-common
    sudo easy_install pip
  fi
}

install_docker() {
  echo install docker
  if command -v docker
  then
    echo "Docker command already present"
    return
  fi
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Docker installation not yet implemented for osx (so ticket+PR)"
  elif [[ "$OSTYPE" == "win32" ]]; then
    echo "Docker installation not yet implemented for windows (so ticket+PR)"
  else
    sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv 7EA0A9C3F273FCD8
    sudo add-apt-repository 'https://download.docker.com/linux/debian'
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
    sudo apt-get -qq update -qq
    sudo apt-get -qq install -y docker-ce
  fi
}

install_hosts() {
  ensure_hosts '127.0.0.1' 'argu.localdev'
  ensure_hosts '127.0.0.1' 'app.argu.localdev'
  ensure_hosts '::1' 'argu.localdev'
  ensure_hosts '::1' 'app.argu.localdev'
  ensure_hosts '127.0.0.1' 'argu.localtest'
  ensure_hosts '127.0.0.1' 'app.argu.localtest'
  ensure_hosts '::1' 'argu.localtest'
  ensure_hosts '::1' 'app.argu.localtest'
  ensure_hosts '127.0.0.1' 'elastic'
  ensure_hosts '127.0.0.1' 'postgres'
  ensure_hosts '127.0.0.1' 'redis'
  ensure_hosts '127.0.0.1' 'rabbitmq'
  ensure_hosts '127.0.0.1' 'mailcatcher'
  ensure_hosts '127.0.0.1' 'token.svc.cluster.local'
  ensure_hosts '127.0.0.1' 'email.svc.cluster.local'
  ensure_hosts '127.0.0.1' 'argu.svc.cluster.local'
  ensure_hosts '127.0.0.1' 'apex-rs.svc.cluster.local'
}

setup_path() {
  echo "Enter development direcory location (defaults to '$USR_HOME/dev' or GO_PATH ($GO_PATH)):"
  read dev_root
  default=${GOPATH:-$USR_HOME/dev}
  dev_root=${dev_root:-$default}
  export DEV_ROOT=$dev_root
  export DEV_HOME=$dev_root/src
}

setup_ssh() {
  ssh-add
}

# Ask and setup path
setup_path
# Create directory tree
create_tree
# Install dependencies
install_dependencies
# Check for ssh keys
echo TODO: Check for ssh keys
setup_ssh
# Clone projects
clone_projects
install_hosts
# setup network adapters
install_adapter
# install docker
install_docker
# install docker-compose
install_compose
# Setup devproxy
if [ ! -f ./setup.sh ]; then
  cd $DEV_HOME/bitbucket.org/arguweb/devproxy
fi
./dev.sh
# done?
echo "done?"
