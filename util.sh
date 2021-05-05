#!/bin/bash
# util.sh
# Utility functions and tests for installation and system configuration
# These are intended for use on Debian-based systems, will not work
# on RPM-based distros, etc. (yet)

# author: Matt Fields
# github: fieldse

# --------------------------------- #
#           General                 #
# --------------------------------- #

# Confirm a user input
function confirm() {
  echo '' && read -n1 -p "${1} (Y/n)?" SELECTION
  [[ ${SELECTION,,} == 'y' ]]
  return "$?"
}

# Print formatted failure message and exit
function fail() {
  printf "\nerror: %s -- exiting\n" "${1}"
  exit 1
}

# Confirm a user input or fail
function confirmOrFail() {
  confirm "$1" || fail "$2"
}


# --------------------------------- #
#        Formatted printing         #
# --------------------------------- #

# Print a padded message
function printPadded() {
  printf "[+] %-64s \n" "${1}"
}

# --------------------------------- #
#           State checks            #
# --------------------------------- #
# These check the exit status of a command and print a formatted
# message of the result

# Print output status, don't exit on fail
#   params    state (bool), msg (string)
function printStatus() {
  [[ $1 == 0 ]] && status='OK' || status='fail'
  msg="${2}"
  printf "[+] %-64s [%s]\n" "${msg}" "${status}"
  return $1
}

# Pass check or exit
# Params:
#   state   (bool)    test state
#   msg     (str)     test description message
#   err     (str)     optional fail message
function checkOrFail() {
  state="${1}"
  msg="${2}"
  errMsg=$([[ ! -z "${3}" ]] && echo "${3}" || echo "${msg} failed")
  printStatus "${state}" "${msg}" || fail "${errMsg}"
}


# --------------------------------- #
#        File/directory tests       #
# --------------------------------- #

# File existence check, print and return
function fileExists() {
  [[ -f "${1}" ]] ; state=$?
  msg="checking file exists: ${1}"
  printStatus "${state}" "${msg}"
  return $state
}

# Directory existence check, print and return
function dirExists() {
  [[ -d "${1}" ]] ; state=$?
  msg="checking directory:   ${1}"
  printStatus "${state}" "${msg}"
  return $state
}

# File existence check or fail
function fileExistsOrFail() {
  [[ -f "${1}" ]] ; state=$?
  msg="checking file exists: ${1}"
  err="${1} not found"
  checkOrFail "${state}" "${msg}" "${err}"
}

# Directory existence check or fail
function dirExistsOrFail() {
  [[ -d "${1}" ]] ; state=$?
  msg="checking directory:   ${1}"
  err="${1} not found"
  checkOrFail "${state}" "${msg}" "${err}"
}

# Create directory with permissions
#   params    dirName,  permissions(octal)
function existsOrCreateDir() {
  dir=$1
  permissions=${2:-755}
  [[ -d $dir ]]; state=$?
  msg="checking directory:   ${dir}"
  printStatus "${state}" "${msg}"

  if [[ $state != 0 ]] ; then
    mkdir -p ${dir} && chmod ${permissions} ${dir}
    printStatus "$?" "creating directory:   ${dir}"
  fi
}


# --------------------------------- #
#           System                  #
# --------------------------------- #

# Prompt to reboot the machine (requires superuser)
function restartOS() {
  confirm "System restart required to continue. Restart now?" && sudo restart now || (echo "canceled" && return 1 )
}

# --------------------------------- #
#           Environment             #
# --------------------------------- #

# Source all the .env files in the passed directory
function sourceAllEnvs() {
  dirExistsOrFail "${1}"
  echo -e "\nsourcing env files in ${1}:"
  for f in ${1}/*.env ; do
    sourceEnvFile ${f}
  done
}

# Source an env file, export all vars to current shell
function sourceEnvFile() {
  export $(egrep -v '^#' $1 | xargs -d "\n")
}

# --------------------------------- #
#           Package management      #
# --------------------------------- #

# Runs apt update (requires superuser)
function aptUpdate() {
  sudo apt update
}

# Install an apt package (requires superuser)
# Params:
#   package     apt package name
function packageInstall() {
  echo -e "\ninstall ${1}"
  sudo apt install -y ${1}
  checkOrFail "$?" "install ${1}"
}

# Install all packages passed as args
function packageInstallAll() {
  echo -e "\ninstall packages: ${@}"
  aptUpdate && sudo apt install -y ${@}
  checkOrFail "$?" "install packages"
}

# --------------------------------- #
#           user groups             #
# --------------------------------- #

# Check if unix group exists
function groupExists() {
  cat /etc/group | cut -d ':' -f1 | grep -e "^${1}" -q ; state=$?
  printStatus "${state}" "group exists? ${1}"
  return ${state}
}

# Create group if it doesn't exist
function createGroup() {
  if ! groupExists "${1}" ; then
    sudo groupadd ${1}
    printStatus "$?" "create group: ${1}"
  fi
}

# Check if user is member of group
function userHasGroup() {
  groups | grep -q "${1}" ; state=$?
  printStatus "${state}" "user is member of group? ${1}"
  return ${state}
}


function addUserToGroup() {
  sudo -H usermod -aG ${1} ${USER}
  checkOrFail "$?" "add user to group: ${1}"

  echo -e "\nrefresh user groups"
  exec su -l $USER
  userHasGroup ${1}
}

# --------------------------------- #
#        System service checks      #
# --------------------------------- #

# Check a system service is running
function serviceRunning() {
  service "$1" status > /dev/null 2>&1 ; state=$?
  printStatus "${state}" "check service is running: ${1}"
  return $state
}

# Start a system service (requires superuser)
function startService() {
  sudo service ${1} start > /dev/null 2>&1 ; state=$?
  checkOrFail "$?" "start ${1} service"
}

# Restart a system service (requires superuser)
function restartService() {
  sudo service ${1} restart > /dev/null 2>&1 ; state=$?
  checkOrFail "$?" "restart service: ${1}"
}

# --------------------------------- #
#        Installation checks        #
# --------------------------------- #
function isInstalled() {
  msg="checking installed: ${1}"
  ( [[ $(type ${1}) ]] || [[ $(which ${1}) ]] ); state=$?
  printStatus "${state}" "${msg}"
  return $state
}

function installedOrFail() {
  isInstalled "${1}" || fail "${1} not installed"
}


# --------------------------------- #
#           Version checks          #
# --------------------------------- #

# Attempt to extract and compare version string
#   params:   filename, minversion
function checkVersion() {
  filename=$1
  minVersion=$2
  msg="version check: ${filename} (>=${minVersion})"
  err="version check failed"
  installed=$( versionString ${filename} )
  [ $(version ${installed}) -ge $(version ${minVersion}) ] ; state=$?
  checkOrFail "${state}" "${msg} installed: ${installed}" "${err}"
}

# Get a regularized version number from a dot-syntax version string
function version() {
  echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}

# Split a version string from --version output
function versionString() {
  filename=$1
  echo $(${filename} --version | cut -d' ' -f3 | sed 's/,//' )
}

# Manual user-verified version check
function confirmVersion() {
  filename=$1
  minVersion=$2
  installed=$(${filename} --version)
  echo -e "\nVerify version: ${filename}"
  printf "  %-30s %s\n" 'installed' "${installed}"
  printf "  %-30s %s\n" 'minimum version' "${minVersion}"
  read -n1 -p "Is your ${filename} version correct? [y/n] " ok
  [[ $ok == 'y' ]] ; state=$?
  echo
  checkOrFail "${state}" "version check: ${filename}"
}

# --------------------------------- #
#           Git                     #
# --------------------------------- #

function gitUser(){
  git config --global user.name
}

function gitEmail(){
  git config --global user.email
}

# Set global github username and email if not already set
function checkGithubUser() {
  [[ ! ( -z $(gitUser) || -z $(gitEmail) ) ]] ; state=$?
  msg="check Github user"
  err="setup git username failed"
  printStatus "${state}" "${msg}"
  if [[ $state != 0 ]] ; then
    echo -e "\nSet your username and email for github.com (this will change global git config) "
    read -p "Set username for github.com: " github_user
    read -p "Set email for github.com: " github_email
    echo -e "Setting git global user.name: ${github_user}"
    echo -e "Setting git global user.email: ${github_email}"
    git config --global user.name ${github_user} && git config --global user.email ${github_email}
    checkOrFail "$?" "${msg}" "${err}"
fi
}

# strip repo name from url
# Todo: This should handle generic git urls
function stripRepoName(){
  echo $1 | cut -d '/' -f 2
}

# Does the repository exist in our local directory context?
function repoLocalDirExists() {
  repo="$1"
  msg="check repo \"$repo\" exists"
  dirName="./$(stripRepoName ${repo})"
  [[ -d "${dirName}" ]] ; state=$?
  printStatus "${state}" "${msg}"
  return ${state}
}

# Clone a repository if it doesn't exist
function cloneRepo() {
  msg="clone \"$repo\"" ; echo -e "\n${msg}"
  url="git@github.com:${gitUser}/$1"
  git clone "${url}"
  checkOrFail "$?" "${msg}"
}

# Update an existing repository
function updateRepo() {
  repoName="$(stripRepoName ${1})"
  msg="Update repository: ${repoName}"; echo -e "\n${msg}"
  [[ -d "${repoName}" ]] && cd "${repoName}" && git pull origin master && cd ..
  checkOrFail "$?" "${msg}"
}

# Clone a repository if it doesn't exist, otherwise pull latest version
function cloneOrUpdateRepo() {
  repo="$1"
  msg="repo ${repo} exists and up to date"
  if (repoLocalDirExists "${repo}"); then
    updateRepo "${repo}"
  else
    cloneRepo "${repo}"
  fi
  checkOrFail "$?" "${msg}"
}
