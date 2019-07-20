#!/bin/bash

# UniFi Controller 5.10.25 auto installation script.
# OS       | List of supported Distributions/OS
#
#          | Ubuntu Precise Pangolin ( 12.04 )
#          | Ubuntu Trusty Tahr ( 14.04 )
#          | Ubuntu Xenial Xerus ( 16.04 )
#          | Ubuntu Bionic Beaver ( 18.04 )
#          | Ubuntu Cosmic Cuttlefish ( 18.10 )
#          | Ubuntu Disco Dingo  ( 19.04 )
#          | Debian Jessie ( 8 )
#          | Debian Stretch ( 9 )
#          | Debian Buster ( 10 )
#          | Linux Mint 13 ( Maya )
#          | Linux Mint 17 ( Qiana | Rebecca | Rafaela | Rosa )
#          | Linux Mint 18 ( Sarah | Serena | Sonya | Sylvia )
#          | Linux Mint 19 ( Tara | Tessa )
#          | MX Linux 18 ( Continuum )
#
# Version  | 3.9.5
# Author   | Glenn Rietveld
# Email    | glennrietveld8@hotmail.nl
# Website  | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                                                 Color Codes                                                                     #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
GRAY='\033[0;37m'
WHITE='\033[1;37m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                                                 Start Checks                                                                    #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Check for root (SUDO).
if [ "$EUID" -ne 0 ]; then
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
  echo -e "${WHITE}#${RESET} The script need to be run as root..."
  echo ""
  echo ""
  echo -e "${WHITE}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i"
  echo ""
  echo -e "${WHITE}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su"
  echo ""
  echo ""
  exit 1
fi

abort() {
  echo ""
  echo ""
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
  echo -e "${WHITE}#${RESET} An error occurred. Aborting script..."
  echo -e "${WHITE}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  echo ""
  echo ""
  exit 1
}

header() {
  clear
  echo -e "${GREEN}#########################################################################${RESET}"
  echo ""
}

header_red() {
  clear
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
}

cancel_script() {
  clear
  header
  echo -e "${WHITE}#${RESET} Cancelling the script!"
  echo ""
  echo ""
  exit 0
}

http_proxy_found() {
  clear
  header
  echo -e "${GREEN}#${RESET} HTTP Proxy found. | ${WHITE}${http_proxy}${RESET}"
  echo ""
  echo ""
}

author() {
  echo -e "${WHITE}#${RESET} ${GRAY}Author   |  ${WHITE}Glenn R.${RESET}"
  echo -e "${WHITE}#${RESET} ${GRAY}Email    |  ${WHITE}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${WHITE}#${RESET} ${GRAY}Website  |  ${WHITE}https://GlennR.nl${RESET}"
  echo ""
  echo ""
  echo ""
}

# Get distro.
if [ -z "$(command -v lsb_release)" ]; then
  if [ -f "/etc/os-release" ]; then
    if [[ -n "$(grep VERSION_CODENAME /etc/os-release)" ]]; then
      os_codename=$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="')
    elif [[ -z "$(grep VERSION_CODENAME /etc/os-release)" ]]; then
      os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $4}' | sed 's/\((\|)\)//g')
    fi
  fi
else
  os_codename=$(lsb_release -cs)
fi

if ! [[ $os_codename =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|cosmic|disco|jessie|stretch|continuum|buster) ]]; then
  clear
  header_red
  echo -e "${WHITE}#${RESET} This script is not made for your OS.."
  echo -e "${WHITE}#${RESET} Feel free to contact Glenn R. (AmazedMender16) on the Community Forums if you need help with installing your UniFi Network Controller."
  echo -e ""
  echo -e ""
  exit 1
fi

if [ $(grep "^export PATH=" /root/.bashrc | grep -c "/sbin") -eq 0 ]; then
  if [[ $(grep "^export PATH=" /root/.bashrc) ]]; then
    sed -i 's/^export PATH=/#export PATH=/' /root/.bashrc
  fi
  echo "export PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin" >> /root/.bashrc || abort
  source /root/.bashrc || abort
fi

if [ ! -d /etc/apt/sources.list.d ]; then
  mkdir -p /etc/apt/sources.list.d
fi

# Check if UniFi is already installed.
if [ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  clear
  header
  echo ""
  echo -e "${WHITE}#${RESET} UniFi is already installed on your system!${RESET}"
  echo -e "${WHITE}#${RESET} You can use my Easy Update Script to update your controller.${RESET}"
  echo ""
  echo ""
  read -p $'\033[1;37m#\033[0m Would you like to download and run my Easy Update Script? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
        rm -rf $0 2> /dev/null
        wget https://get.glennr.nl/unifi/update/unifi-update.sh; chmod +x unifi-update.sh; sudo ./unifi-update.sh; exit 0;;
      [Nn]*) exit 0;;
  esac
fi

dpkg_locked_message() {
  clear
  header_red
  echo -e "${WHITE}#${RESET} dpkg is locked.. Waiting for other software managers to finish!"
  echo -e "${WHITE}#${RESET} If this is everlasting please contact Glenn R. (AmazedMender16) on the Community Forums!"
  echo ""
  echo ""
  sleep 5
  if [[ -z "$dpkg_wait" ]]; then
    echo "glennr_lock_active" >> /tmp/glennr_lock
  fi
}

dpkg_locked_60_message() {
  clear
  header
  echo -e "${WHITE}#${RESET} dpkg is already locked for 60 seconds..."
  echo -e "${WHITE}#${RESET} Would you like to force remove the lock?"
  echo ""
  echo ""
  echo ""
}

# Check if dpkg is locked
if [ $(dpkg-query -W -f='${Status}' psmisc 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
    dpkg_locked_message
    if [ $(grep glennr_lock_active /tmp/glennr_lock | wc -l) -ge 12 ]; then
      rm -rf /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      read -p $'\033[1;37m#\033[0m Do you want to proceed with removing the lock? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"")
            killall apt apt-get 2> /dev/null
            rm -rf /var/lib/apt/lists/lock 2> /dev/null
            rm -rf /var/cache/apt/archives/lock 2> /dev/null
            rm -rf /var/lib/dpkg/lock* 2> /dev/null
            dpkg --configure -a 2> /dev/null
            apt-get check >/dev/null 2>&1
            if [ "$?" -ne 0 ]; then
              apt-get install --fix-broken -y 2> /dev/null
            fi
            clear
            clear;;
          [Nn]*) dpkg_wait=true;;
      esac
    fi
  done;
else
  if [[ $os_codename =~ (stretch|continuum|buster) ]]; then
     dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm -rf /tmp/glennr_dpkg_lock 2> /dev/null; fi
     while [[ $dpkg_locked == 'true'  ]]; do
        unset dpkg_locked
        dpkg_locked_message
       if [ $(grep glennr_lock_active /tmp/glennr_lock | wc -l) -ge 12 ]; then
          rm -rf /tmp/glennr_lock 2> /dev/null
          dpkg_locked_60_message
          read -p $'\033[1;37m#\033[0m Do you want to proceed with force removing the lock? (Y/n) ' yes_no
          case "$yes_no" in
              [Yy]*|"")
                ps aux | grep -i apt | awk '{print $2}' >> /tmp/glennr_apt
                glennr_apt_pid_list=$(tr '\r\n' ' ' < /tmp/glennr_apt)
                for glennr_apt in ${glennr_apt_pid_list[@]}; do
                  kill -9 $glennr_apt 2> /dev/null
                done;
                rm -rf /tmp/glennr_apt 2> /dev/null
                rm -rf /var/lib/apt/lists/lock 2> /dev/null
                rm -rf /var/cache/apt/archives/lock 2> /dev/null
                rm -rf /var/lib/dpkg/lock* 2> /dev/null
                dpkg --configure -a 2> /dev/null
                apt-get check >/dev/null 2>&1
                if [ "$?" -ne 0 ]; then
                  apt-get install --fix-broken -y 2> /dev/null
                fi
                clear
                clear;;
              [Nn]*) dpkg_wait=true;;
          esac
       fi
       dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm -rf /tmp/glennr_dpkg_lock 2> /dev/null; fi
     done;
     rm -rf /tmp/glennr_dpkg_lock 2> /dev/null
  else
    dpkg -i /dev/null 2>/dev/null; if [ "$?" -eq 2 ]; then dpkg_locked=true; fi
    while [[ $dpkg_locked == 'true'  ]]; do
      unset dpkg_locked
      dpkg_locked_message
      if [ $(grep glennr_lock_active /tmp/glennr_lock | wc -l) -ge 12 ]; then
        rm -rf /tmp/glennr_lock 2> /dev/null
        dpkg_locked_60_message
        read -p $'\033[1;37m#\033[0m Do you want to proceed with force removing the lock? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"")
              ps aux | grep -i apt | awk '{print $2}' >> /tmp/glennr_apt
              glennr_apt_pid_list=$(tr '\r\n' ' ' < /tmp/glennr_apt)
              for glennr_apt in ${glennr_apt_pid_list[@]}; do
                kill -9 $glennr_apt 2> /dev/null
              done;
              rm -rf /tmp/glennr_apt 2> /dev/null
              rm -rf /var/lib/apt/lists/lock 2> /dev/null
              rm -rf /var/cache/apt/archives/lock 2> /dev/null
              rm -rf /var/lib/dpkg/lock* 2> /dev/null
              dpkg --configure -a 2> /dev/null
              apt-get check >/dev/null 2>&1
              if [ "$?" -ne 0 ]; then
                apt-get install --fix-broken -y 2> /dev/null
              fi
              clear
              clear;;
            [Nn]*) dpkg_wait=true;;
        esac
      fi
      dpkg -i /dev/null 2>/dev/null; if [ "$?" -eq 2 ]; then dpkg_locked=true; fi
    done;
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                                                                 #
#                                                                                                              Required Packages                                                                                                              #
#                                                                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Install needed packages if not installed
clear
header
echo -e "${WHITE}#${RESET} Checking if all required packages are installed!"
echo ""
echo ""
apt-get update
if [ $(dpkg-query -W -f='${Status}' sudo 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install sudo -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise-security main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty-security main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial-security main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install psmisc -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' lsb-release 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install lsb-release -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu precise main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu trusty main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install lsb-release -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' net-tools 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install net-tools -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu trusty main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install net-tools -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' apt-transport-https 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install apt-transport-https -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu trusty-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu bionic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu cosmic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.debian.org/debian-security jessie/updates main") -eq 0 ]]; then
        echo deb http://security.debian.org/debian-security jessie/updates main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install apt-transport-https -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' software-properties-common 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install software-properties-common -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu trusty main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install software-properties-common -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install curl -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu trusty-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu bionic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu cosmic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.debian.org/debian-security jessie/updates main") -eq 0 ]]; then
        echo deb http://security.debian.org/debian-security jessie/updates main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install curl -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' dirmngr 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install dirmngr -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu bionic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ bionic main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ bionic main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu cosmic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ cosmic main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ cosmic main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu disco-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu disco-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ disco main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ disco main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian/ jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian/ stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abor
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian/ buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install dirmngr -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install wget -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu trusty-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu bionic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu cosmic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.debian.org/debian-security jessie/updates main") -eq 0 ]]; then
        echo deb http://security.debian.org/debian-security jessie/updates main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install wget -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' netcat 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install netcat -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ bionic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ bionic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ cosmic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ cosmic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ disco universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ disco universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install netcat -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' haveged 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install haveged -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ bionic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ bionic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ cosmic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ cosmic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ disco universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ disco universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install haveged -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' psmisc 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install psmisc -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise-updates main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise-updates main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu trusty main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
     if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install psmisc -y || abort
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                                                   Variables                                                                     #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

MONGODB_ORG_SERVER=$(dpkg -l | grep ^ii | grep "mongodb-org-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_MONGOS=$(dpkg -l | grep ^ii | grep "mongodb-org-mongos" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_SHELL=$(dpkg -l | grep ^ii | grep "mongodb-org-shell" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_TOOLS=$(dpkg -l | grep ^ii | grep "mongodb-org-tools" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORGN=$(dpkg -l | grep ^ii | grep "mongodb-org" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_SERVER=$(dpkg -l | grep ^ii | grep "mongodb-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_CLIENTS=$(dpkg -l | grep ^ii | grep "mongodb-clients" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_SERVER_CORE=$(dpkg -l | grep ^ii | grep "mongodb-server-core" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGO_TOOLS=$(dpkg -l | grep ^ii | grep "mongo-tools" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
#
SYSTEM_MEMORY=$(awk '/MemTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
SYSTEM_SWAP=$(awk '/SwapTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
#SYSTEM_FREE_DISK=$(df -h / | grep "/" | awk '{print $4}' | sed 's/G//')
SYSTEM_FREE_DISK=$(df -k / | awk '{print $4}' | tail -n1)
#
#SERVER_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
SERVER_IP=$(/sbin/ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | head -1 | sed 's/.*://')
PUBLIC_SERVER_IP=$(curl https://ip.glennr.nl/ -s)
ARCHITECTURE=$(dpkg --print-architecture)
os_codename=$(lsb_release -cs)
#
#JAVA8=$(dpkg -l | grep -c "openjdk-8-jre-headless\|oracle-java8-installer")
mongodb_server_installed=$(dpkg -l | grep -c "mongodb-server\|mongodb-org-server")
mongodb_version=$(dpkg -l | grep "mongodb-server\|mongodb-org-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//' | sed 's/\.//g')

# JAVA Check
java_v8=$(dpkg -l | grep ^ii | grep -c "openjdk-8\|oracle-java8")
java_v9=$(dpkg -l | grep ^ii | grep -c "openjdk-9\|oracle-java9")
java_v10=$(dpkg -l | grep ^ii | grep -c "openjdk-10\|oracle-java10")
java_v11=$(dpkg -l | grep ^ii | grep -c "openjdk-11\|oracle-java11")
java_v12=$(dpkg -l | grep ^ii | grep -c "openjdk-12\|oracle-java12")

unsupported_java_installed=''
java8_installed=''
remote_controller=''
debian_64_mongo=''
openjdk_repo=''
debian_32_run_fix=''
unifi_dependencies=''
mongodb_key_fail=''
port_8080_in_use=''
port_8080_pid=''
port_8080_service=''
port_8443_in_use=''
port_8443_pid=''
port_8443_service=''

###################################################################################################################################################################################################
#                                                                                                                                                                                                                                                 #
#                                                                                                                    Checks                                                                                                                     #
#                                                                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if [ $SYSTEM_FREE_DISK -lt "5242880" ]; then
  clear
  header_red
  echo -e "${WHITE}#${RESET} Free disk space is below 5GB.. Please expand the disk size!"
  echo -e "${WHITE}#${RESET} I recommend expanding to atleast 10GB"
  echo ""
  echo ""
  exit 1
fi


# MongoDB version check.
if [[ $MONGODB_ORG_SERVER > "3.4.999" || $MONGODB_ORG_MONGOS > "3.4.999" || $MONGODB_ORG_SHELL > "3.4.999" || $MONGODB_ORG_TOOLS > "3.4.999" || $MONGODB_ORG > "3.4.999" || $MONGODB_SERVER > "3.4.999" || $MONGODB_CLIENTS > "3.4.999" || $MONGODB_SERVER_CORE > "3.4.999" || $MONGO_TOOLS > "3.4.999" ]]; then
  clear
  header_red
  echo -e "${WHITE}#${RESET} UniFi does not support MongoDB 3.6 or newer.."
  echo -e "${WHITE}#${RESET} Do you want to uninstall the unsupported MongoDB version?"
  echo ""
  echo -e "${WHITE}#${RESET} This will also uninstall any other package depending on MongoDB!"
  echo -e "${WHITE}#${RESET} I highly recommend creating a backup/snapshot of your machine/VM"
  echo ""
  echo ""
  echo ""
  read -p "Do you want to proceed with uninstalling MongoDB? (Y/n)" yes_no
  case "$yes_no" in
      [Yy]*|"")
        clear
        header
        echo -e "${WHITE}#${RESET} Uninstalling MongoDB!"
        if [ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
          echo -e "${WHITE}#${RESET} Removing UniFi to keep system files!"
        fi
        if [ $(dpkg-query -W -f='${Status}' unifi-video 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
          echo -e "${WHITE}#${RESET} Removing UniFi-Video to keep system files!"
        fi
        echo ""
        echo ""
        echo ""
        sleep 3
        rm /etc/apt/sources.list.d/mongo*.list
        if [ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
          dpkg --remove --force-remove-reinstreq unifi || abort
        fi
        if [ $(dpkg-query -W -f='${Status}' unifi-video 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
          dpkg --remove --force-remove-reinstreq unifi-video || abort
        fi
        apt-get purge mongo* -y
        if [[ $? > 0 ]]; then
          clear
          header_red
          echo -e "${WHITE}#${RESET} Failed to uninstall MongoDB!"
          echo -e "${WHITE}#${RESET} Uninstalling MongoDB with different actions!"
          echo ""
          echo ""
          echo ""
          sleep 2
          apt-get --fix-broken install -y || apt-get install -f -y
          apt-get autoremove -y
          if [ $(dpkg-query -W -f='${Status}' mongodb-org 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-org-tools 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org-tools || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-org-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org-server || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-org-mongos 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org-mongos || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-org-shell 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org-shell || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-server || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-clients 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-clients || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-server-core 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-server-core || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongo-tools 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongo-tools || abort
          fi
        fi
        apt-get autoremove -y || abort
        apt-get clean -y || abort;;
      [Nn]*) cancel_script;;
  esac
fi

# Memory and Swap file.
if [ $SYSTEM_MEMORY -lt "2" ]; then
  clear
  header_red
  echo -e "${WHITE}#${RESET} SYSTEM MEMORY is lower than recommended!"
  echo -e "${WHITE}#${RESET} Checking for swap file!"
  echo ""
  echo ""
  echo ""
  sleep 2
  if [ $SYSTEM_FREE_DISK -gt "4194304" ]; then
    if [ $SYSTEM_SWAP == "0" ]; then
      clear
      header
      echo -e "${WHITE}#${RESET} Creating swap file!"
      echo ""
      echo ""
      echo ""
      sleep 2
      dd if=/dev/zero of=/swapfile bs=2048 count=1048576
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab
    else
      clear
      header
      echo -e "${WHITE}#${RESET} Swap file already exists!"
      echo ""
      echo ""
      echo ""
      sleep 2
    fi
  else
    clear
    header_red
    echo -e "${WHITE}#${RESET} Not enough free disk space for the swap file!"
    echo -e "${WHITE}#${RESET} Skipping swap file creation!"
    echo ""
    echo -e "${WHITE}#${RESET} I highly recommend upgrading the system memory to atleast 2GB and expanding the disk space!"
    echo ""
    echo ""
    echo ""
    sleep 8
  fi
fi

if netstat -lnp | grep -q 8080; then
  port_8080_pid=`netstat -lnp | grep 8080 | awk '{print $7}' | sed 's/[/].*//g'`
  port_8080_service=`netstat -lnp | grep 8080 | awk '{print $7}' | sed 's/[0-9/]//g'`
  if [[ $(ls -l /proc/${port_8080_pid}/exe | awk '{print $3}') != "unifi" ]]; then
    port_8080_in_use=true
  fi
fi
if netstat -lnp | grep -q 8443; then
  port_8443_pid=`netstat -lnp | grep 8443 | awk '{print $7}' | sed 's/[/].*//g'`
  port_8443_service=`netstat -lnp | grep 8443 | awk '{print $7}' | sed 's/[0-9/]//g'`
  if [[ $(ls -l /proc/${port_8443_pid}/exe | awk '{print $3}') != "unifi" ]]; then
    port_8443_in_use=true
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                                     Installation Script starts here                                                             #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

apt_mongodb_check() {
  apt-get update
  MONGODB_ORG_CACHE=$(apt-cache madison mongodb-org | awk '{print $3}' | sort -V | tail -n 1 | sed 's/\.//g')
  MONGODB_CACHE=$(apt-cache madison mongodb | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
  MONGO_TOOLS_CACHE=$(apt-cache madison mongo-tools | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
}

set_hold_mongodb_org=''
set_hold_mongodb=''
set_hold_mongo_tools=''

clear
header
echo -e "${WHITE}#${RESET} Getting the latest patches for your machine!"
echo ""
echo ""
echo ""
sleep 2
apt_mongodb_check
if [[ ${MONGODB_ORG_CACHE::2} -gt "34" ]]; then
  if [ $(dpkg --get-selections | grep "mongodb-org" | awk '{print $2}' | grep -c "install") -ne 0 ]; then
    echo "mongodb-org hold" | sudo dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-mongos hold" | sudo dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-server hold" | sudo dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-shell hold" | sudo dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-tools hold" | sudo dpkg --set-selections 2> /dev/null || abort
    set_hold_mongodb_org=true
  fi
fi
if [[ ${MONGODB_CACHE::2} -gt "34" ]]; then
  if [ $(dpkg --get-selections | grep "mongodb-server" | awk '{print $2}' | grep -c "install") -ne 0 ]; then
    echo "mongodb hold" | sudo dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-server hold" | sudo dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-server-core hold" | sudo dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-clients hold" | sudo dpkg --set-selections 2> /dev/null || abort
    set_hold_mongodb=true
  fi
fi
if [[ ${MONGO_TOOLS_CACHE::2} -gt "34" ]]; then
  if [ $(dpkg --get-selections | grep "mongo-tools" | awk '{print $2}' | grep -c "install") -ne 0 ]; then
    echo "mongo-tools hold" | sudo dpkg --set-selections 2> /dev/null || abort
    set_hold_mongo_tools=true
  fi
fi
apt-get update
DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade || abort
DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade || abort
apt-get autoremove -y || abort
apt-get autoclean -y || abort
if [[ $set_hold_mongodb_org == 'true' ]]; then
  echo "mongodb-org install" | sudo dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-mongos install" | sudo dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-server install" | sudo dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-shell install" | sudo dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-tools install" | sudo dpkg --set-selections 2> /dev/null || abort
fi
if [[ $set_hold_mongodb == 'true' ]]; then
  echo "mongodb install" | sudo dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-server install" | sudo dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-server-core install" | sudo dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-clients install" | sudo dpkg --set-selections 2> /dev/null || abort
fi
if [[ $set_hold_mongo_tools == 'true' ]]; then
  echo "mongo-tools install" | sudo dpkg --set-selections 2> /dev/null || abort
fi

# MongoDB check
MONGODB_SERVER_INSTALLED=$(dpkg -l | grep -c "mongodb-server\|mongodb-org-server")

ubuntu_32_mongo() {
  clear
  header
  echo -e "${WHITE}#${RESET} 32 bit system detected!"
  echo -e "${WHITE}#${RESET} Installing MongoDB for 32 bit systems!"
  echo ""
  echo ""
  echo ""
  sleep 2
}

debian_32_mongo() {
  debian_32_run_fix=true
  clear
  header
  echo -e "${WHITE}#${RESET} 32 bit system detected!"
  echo -e "${WHITE}#${RESET} Skipping MongoDB installation!"
  echo ""
  echo ""
  echo ""
  sleep 2
}

mongodb_26_key() {
  if [ ! -z "$http_proxy" ]; then
    http_proxy_found
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${http_proxy} --recv-keys 7F0CEB10 || mongodb_key_fail=true
  elif [ -f /etc/apt/apt.conf ]; then
    apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
    if [[ apt_http_proxy ]]; then
      http_proxy_found
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${apt_http_proxy} --recv-keys 7F0CEB10 || mongodb_key_fail=true
    fi
  else
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 || mongodb_key_fail=true
  fi
  if [[ $mongodb_key_fail == "true" ]]; then
    curl -LO https://www.mongodb.org/static/pgp/server-2.6.asc || abort
    gpg --import server-2.6.asc || abort
    rm -rf server-2.6.asc 2> /dev/null
  fi
}

mongodb_34_key() {
  if [ ! -z "$http_proxy" ]; then
    http_proxy_found
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${http_proxy} --recv-keys 0C49F3730359A14518585931BC711F9BA15703C6 || mongodb_key_fail=true
  elif [ -f /etc/apt/apt.conf ]; then
    apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
    if [[ apt_http_proxy ]]; then
      http_proxy_found
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${apt_http_proxy} --recv-keys 0C49F3730359A14518585931BC711F9BA15703C6 || mongodb_key_fail=true
    fi
  else
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 || mongodb_key_fail=true
  fi
  if [[ $mongodb_key_fail == "true" ]]; then
    curl -LO https://www.mongodb.org/static/pgp/server-3.4.asc || abort
    gpg --import server-3.4.asc || abort
    rm -rf server-3.4.asc 2> /dev/null
  fi
}

if [[ $os_codename == "disco" ]]; then
  clear
  header
  echo -e "${WHITE}#${RESET} Installing a required package.."
  echo ""
  echo ""
  echo ""
  sleep 2
  wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb -O /tmp/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb || abort
  dpkg -i /tmp/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb || abort
  rm /tmp/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb
fi

clear
header
echo -e "${WHITE}#${RESET} The latest patches are installed on your system!"
echo -e "${WHITE}#${RESET} Installing MongoDB..."
echo ""
echo ""
echo ""
sleep 2
if [ ! $MONGODB_SERVER_INSTALLED -eq 1 ]; then
  if [[ $os_codename =~ (precise|maya) && ! $ARCHITECTURE =~ (amd64|arm64) ]]; then
    mongodb_26_key
    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb-org-2.6.list || abort
    apt-get update
    apt-get install -y mongodb-org || abort
  elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) && ! $ARCHITECTURE =~ (amd64|arm64) ]]; then
    mongodb_26_key
    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb-org-2.6.list || abort
    apt-get update
    apt-get install -y mongodb-org || abort
  elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) && ! $ARCHITECTURE =~ (amd64|arm64) ]]; then
    ubuntu_32_mongo
    mongodb_26_key
    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/mongodb-org-2.6.list || abort
    apt-get update
    apt-get install -y mongodb-org || abort
    if [[ $? > 0 ]]; then
      rm -rf /etc/apt/sources.list.d/mongodb-org-2.6.list 2> /dev/null
      apt-get update
      if [ $(dpkg-query -W -f='${Status}' mongodb-server 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        apt-get install mongodb-server -y || abort
      fi
      if [ $(dpkg-query -W -f='${Status}' mongodb-clients 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        apt-get install mongodb-clients -y || abort
      fi
    fi
  elif [[ $os_codename =~ (precise|maya) && $ARCHITECTURE =~ (amd64|arm64) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu precise/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    apt-get update
    apt-get install -y mongodb-org || abort
  elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) && $ARCHITECTURE =~ (amd64|arm64) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    apt-get update
    apt-get install -y mongodb-org || abort
  elif [[ $os_codename =~ (xenial|bionic|cosmic|disco|sarah|serena|sonya|sylvia|tara|tessa) && $ARCHITECTURE =~ (amd64|arm64) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
    apt-get update
    apt-get install -y mongodb-org || abort
  elif [[ $os_codename =~ (jessie|stretch|continuum|buster) ]]; then
    if [[ ! $ARCHITECTURE =~ (amd64|arm64) ]]; then
      debian_32_mongo
    fi
    if [[ $os_codename == "jessie" && $ARCHITECTURE =~ (amd64|arm64) ]]; then
      echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
      debian_64_mongo=install
    elif [[ $os_codename =~ (stretch|continuum|buster) && $ARCHITECTURE =~ (amd64|arm64) ]]; then
      echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
      wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb -O /tmp/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb || abort
      dpkg -i /tmp/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb || abort
      rm /tmp/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb
      debian_64_mongo=install
    fi
    if [ $debian_64_mongo == 'install' ]; then
      mongodb_34_key
      apt-get update
      apt-get install -y mongodb-org || abort
    fi
  fi
else
  clear
  header
  echo -e "${WHITE}#${RESET} MongoDB is already installed..."
  echo ""
  echo ""
  echo ""
  sleep 2
fi

clear
header
echo -e "${WHITE}#${RESET} MongoDB has been installed successfully!"
echo -e "${WHITE}#${RESET} Installing OpenJDK 8..."
echo ""
echo ""
echo ""
sleep 2
if ! [[ $JAVA8 -eq 1 ]]; then
  if [[ $os_codename =~ (precise|maya) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu precise main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu precise main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* xenial main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* bionic main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu bionic main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [ $os_codename == "cosmic" ]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* cosmic main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu cosmic main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [ $os_codename == "disco" ]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu[/]* bionic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main universe >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [ $os_codename == "jessie" ]; then
    apt-get install -t jessie-backports openjdk-8-jre-headless ca-certificates-java -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://archive.debian.org/debian[/]* jessie-backports main") -eq 0 ]]; then
        echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        apt-get update -o Acquire::Check-Valid-Until=false
        apt-get install -t jessie-backports openjdk-8-jre-headless ca-certificates-java -y || abort
        sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
      fi
    fi
  elif [[ $os_codename =~ (stretch|continuum) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* xenial main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [ $os_codename == "buster" ]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.nl.debian.org/debian[/]* stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  fi
  if [[ $openjdk_repo == 'true' ]]; then
    if [ ! -z "$http_proxy" ]; then
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${http_proxy} --recv-keys EB9B1D8886F44E2A || abort
    elif [ -f /etc/apt/apt.conf ]; then
      apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
      if [[ apt_http_proxy ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${apt_http_proxy} --recv-keys EB9B1D8886F44E2A || abort
      fi
    else
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EB9B1D8886F44E2A || abort
    fi
  fi
  apt-get update
  apt-get install openjdk-8-jre-headless -y || abort
else
  clear
  header
  echo -e "${WHITE}#${RESET} OpenJDK/Oracle JAVA 8 is already installed..."
  echo ""
  echo ""
  echo ""
  sleep 2
fi

if [[ $java_v8 -eq 1 ]]; then
  java8_installed=true
fi
if [[ $java_v9 -eq 1 || $java_v10 -eq 1 || $java_v11 -eq 1 || $java_v12 -eq 1 ]]; then
  unsupported_java_installed=true
fi

if [[ ( $java8_installed = 'true' && $unsupported_java_installed = 'true' ) ]]; then
  clear
  header_red
  echo -e "${WHITE}#${RESET} Unsupported JAVA versions are detected, do you want to uninstall them?"
  echo ""
  echo ""
  read -p $'\033[1;37m#\033[0m Do you want to proceed with uninstalling the unsupported JAVA versions? (Y/n) ' yes_no
  case "$yes_no" in
       [Yy]*|"")
          clear
          header
          echo -e "${WHITE}#${RESET} Uninstalling unsupported JAVA versions..."
          echo ""
          echo ""
          echo ""
          sleep 3
          if [[ $java_v9 -eq 1 ]]; then
            apt-get purge openjdk-9-* -y || apt-get purge oracle-java9-* -y
          elif [[ $java_v10 -eq 1 ]]; then
            apt-get purge openjdk-10-* -y || apt-get purge oracle-java10-* -y
          elif [[ $java_v11 -eq 1 ]]; then
            apt-get purge openjdk-11-* -y || apt-get purge oracle-java11-* -y
          elif [[ $java_v12 -eq 1 ]]; then
            apt-get purge openjdk-12-* -y || apt-get purge oracle-java12-* -y
          fi;;
       [Nn]*) ;;
  esac
fi

if [[ ${java_v8} -ge 1 ]]; then
  if [ -f /etc/default/unifi ]; then
    if [[ $(cat /etc/default/unifi | grep "^JAVA_HOME") ]]; then
      sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/default/unifi
    fi
    echo "JAVA_HOME="$( readlink -f "$( which java )" | sed "s:bin/.*$::" )"" >> /etc/default/unifi
  else
    if [[ $(cat /etc/environment | grep "JAVA_HOME") ]]; then
      sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/environment
    fi
    echo "JAVA_HOME="$( readlink -f "$( which java )" | sed "s:bin/.*$::" )"" >> /etc/environment
    source /etc/environment
  fi
fi

clear
header
echo -e "${WHITE}#${RESET} OpenJDK 8 has been installed successfully!"
echo -e "${WHITE}#${RESET} Installing UniFi Dependencies..."
echo ""
echo ""
echo ""
sleep 2
apt-get update
if [[ $os_codename =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|cosmic|disco|stretch|continuum|buster) ]]; then
  apt-get install binutils ca-certificates-java java-common -y || unifi_dependencies=fail
  apt-get install jsvc libcommons-daemon-java -y || unifi_dependencies=fail
elif [[ $os_codename == 'jessie' ]]; then
  apt-get install binutils ca-certificates-java java-common -y --force-yes || unifi_dependencies=fail
  apt-get install jsvc libcommons-daemon-java -y --force-yes || unifi_dependencies=fail
fi
if [[ $unifi_dependencies == 'fail' ]]; then
  if [[ $os_codename =~ (precise|maya) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu precise main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu precise main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu trusty main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename =~ (bionic|tara|tessa) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu bionic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "cosmic" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "disco" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "jessie" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename =~ (stretch|continuum) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "buster" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  fi
  if [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|cosmic|disco|stretch|continuum|buster) ]]; then
    apt-get install binutils ca-certificates-java java-common -y || abort
    apt-get install jsvc libcommons-daemon-java -y || abort
  elif [[ $os_codename == 'jessie' ]]; then
    apt-get install binutils ca-certificates-java java-common -y --force-yes || abort
    apt-get install jsvc libcommons-daemon-java -y --force-yes || abort
  fi
fi

clear
header
echo -e "${WHITE}#${RESET} UniFi dependencies has been installed successfully!"
echo -e "${WHITE}#${RESET} Installing your UniFi Network Controller ( ${WHITE}5.10.25${RESET} )..."
echo ""
echo ""
echo ""
sleep 2
unifi_temp="$(mktemp unifi_sysvinit_all_5.10.25_XXX.deb)" || abort
wget -O "$unifi_temp" 'https://dl.ui.com/unifi/5.10.25/unifi_sysvinit_all.deb' || abort
dpkg -i "$unifi_temp"
if [[ $debian_32_run_fix == 'true' ]]; then
  clear
  header
  echo -e "${WHITE}#${RESET} Fixing broken UniFi install..."
  echo ""
  echo ""
  echo ""
  apt-get --fix-broken install -y || abort
fi
rm -rf "$unifi_temp" 2> /dev/null
service unifi start || abort

# Check if MongoDB service is enabled
if ! [[ $os_codename =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
  if [ ${MONGODB_VERSION::2} -ge '26' ]; then
    SERVICE_MONGODB=$(systemctl is-enabled mongod)
    if [ $SERVICE_MONGODB = 'disabled' ]; then
      systemctl enable mongod 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
    fi
  else
    SERVICE_MONGODB=$(systemctl is-enabled mongodb)
    if [ $SERVICE_MONGODB = 'disabled' ]; then
      systemctl enable mongodb 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
    fi
  fi
  # Check if UniFi service is enabled
  SERVICE_UNIFI=$(systemctl is-enabled unifi)
  if [ $SERVICE_UNIFI = 'disabled' ]; then
    systemctl enable unifi 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | UniFi"; sleep 3; }
  fi
fi

clear
header
echo -e "${WHITE}#${RESET} Would you like to update the UniFi Network Controller via APT?"
echo ""
echo ""
read -p $'\033[1;37m#\033[0m Do you want the script to add the source list file? (Y/n) ' yes_no
case "$yes_no" in
    [Yy]*|"")
      clear
      header
      echo -e "${WHITE}#${RESET} Adding source list..."
      echo ""
      echo ""
      echo ""
      sleep 3
      sed -i '/unifi/d' /etc/apt/sources.list
      rm -rf /etc/apt/sources.list.d/100-ubnt-unifi.list 2> /dev/null
      if [ ! -z "$http_proxy" ]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${http_proxy} --recv-keys 06E85760C0A52C50 || abort
      elif [ -f /etc/apt/apt.conf ]; then
        apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
        if [[ apt_http_proxy ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${apt_http_proxy} --recv-keys 06E85760C0A52C50 || abort
        fi
      else
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 06E85760C0A52C50 || abort
      fi
      if [[ $? > 0 ]]; then
        wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg
      fi
      echo 'deb http://www.ubnt.com/downloads/unifi/debian unifi-5.10 ubiquiti' | tee /etc/apt/sources.list.d/100-ubnt-unifi.list
      apt-get update;;
    [Nn]*) ;;
esac

# Check if controller is reachable via public IP.
timeout 1 nc -zv ${PUBLIC_SERVER_IP} 8443 &> /dev/null && remote_controller=true

if [[ $(dpkg -l | grep "unifi " | grep -c "ii") -eq 1 ]]; then
  clear
  header
  echo ""
  echo -e "${GREEN}#${RESET} UniFi Network Controller 5.10.25 has been installed successfully"
  if [[ ${remote_controller} = 'true' ]]; then
    echo -e "${GREEN}#${RESET} Your controller address: ${WHITE}https://$PUBLIC_SERVER_IP:8443${RESET}"
  else
    echo -e "${GREEN}#${RESET} Your controller address: ${WHITE}https://$SERVER_IP:8443${RESET}"
  fi
  echo ""
  echo ""
  if [[ $os_codename =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
    service unifi status | grep -q running&& echo -e "${GREEN}#${RESET} UniFi is active ( running )" || echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  else
    systemctl is-active -q unifi && echo -e "${GREEN}#${RESET} UniFi is active ( running )" || echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  fi
  if [[ ${port_8080_in_use} == 'true' && ${port_8443_in_use} == 'true' && ${port_8080_pid} == ${port_8443_pid} ]]; then
    echo ""
    echo -e "${RED}#${RESET} Port 8080 and 8443 is already in use by another process ( PID ${port_8080_pid} ), your UniFi Network Controll will most likely not start.."
    echo -e "${RED}#${RESET} Disable the service that is using port 8080 and 8443 ( ${port_8080_service} ) or kill the process with the command below"
    echo -e "${RED}#${RESET} sudo kill -9 ${port_8080_pid}"
    echo ""
  else
    if [[ ${port_8080_in_use} == 'true' ]]; then
      echo ""
      echo -e "${RED}#${RESET} Port 8080 is already in use by another process ( PID ${port_8080_pid} ), your UniFi Network Controll will most likely not start.."
      echo -e "${RED}#${RESET} Disable the service that is using port 8080 ( ${port_8080_service} ) or kill the process with the command below"
      echo -e "${RED}#${RESET} sudo kill -9 ${port_8080_pid}"
    fi
    if [[ ${port_8443_in_use} == 'true' ]]; then
      echo ""
      echo -e "${RED}#${RESET} Port 8443 is already in use by another process ( PID ${port_8443_pid} ), your UniFi Network Controll will most likely not start.."
      echo -e "${RED}#${RESET} Disable the service that is using port 8443 ( ${port_8443_service} ) or kill the process with the command below"
      echo -e "${RED}#${RESET} sudo kill -9 ${port_8443_pid}"
    fi
    echo ""
  fi
  echo ""
  echo ""
  author
  rm $0
else
  clear
  header_red
  echo ""
  echo -e "${RED}#${RESET} Failed to successfully install UniFi Network Controller 5.10.25"
  echo -e "${RED}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!${RESET}"
  echo ""
  echo ""
  rm $0
fi