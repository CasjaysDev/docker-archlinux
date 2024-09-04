#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202408091436-git
# @@Author           :  CasjaysDev
# @@Contact          :  CasjaysDev <docker-admin@casjaysdev.pro>
# @@License          :  MIT
# @@ReadME           :
# @@Copyright        :  Copyright 2023 CasjaysDev
# @@Created          :  Mon Aug 28 06:48:42 PM EDT 2023
# @@File             :  04-users.sh
# @@Description      :  script to run users
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck shell=bash
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
set -o pipefail
[ "$DEBUGGER" = "on" ] && echo "Enabling debugging" && set -x$DEBUGGER_OPTIONS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set env variables
exitCode=0
AUR_USER="${AUR_USER:-aur}"
AUR_HOME="${AUR_HOME:-/var/lib/aur}"
AUR_BUILD_DIR="${AUR_BUILD_DIR:-${AUR_HOME}/build}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main script
chmod 777 -f "${AUR_HOME}/build"
if ! grep -s -q "${AUR_HOME}" /etc/passwd; then useradd -m -r -s /bin/bash -d "${AUR_HOME}" "${AUR_USER}" && passwd -d "${AUR_USER}" || exit 1; fi
mkdir -p "${AUR_BUILD_DIR}"
mkdir -p "${AUR_HOME}/.gnupg"
[ -d "/etc/sudoers.d" ] || mkdir -p "/etc/sudoers.d"
echo ''${AUR_USER}'     ALL=(ALL) ALL' >"/etc/sudoers.d/${AUR_USER}" &&
  echo 'standard-resolver' >"${AUR_HOME}/.gnupg/dirmngr.conf" &&
  chown -Rf "${AUR_USER}":"${AUR_USER}" "${AUR_HOME}"
if [ -z "$(command -v yay 2>/dev/null)" ]; then
  if cd "$AUR_BUILD_DIR"; then
    [ -n "$(type -P git)" ] && git config --global init.defaultBranch main
    git clone --depth 1 "https://aur.archlinux.org/yay" "$AUR_BUILD_DIR/yay" && cd "$AUR_BUILD_DIR/yay" && sudo -u "${AUR_USER}" makepkg --noconfirm -si
  else
    exit 1
  fi
fi
sudo -u "${AUR_USER}" yay --afterclean --removemake --save && pacman -Qtdq | xargs -r pacman --noconfirm -Rcns
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the exit code
exitCode=$?
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $exitCode
