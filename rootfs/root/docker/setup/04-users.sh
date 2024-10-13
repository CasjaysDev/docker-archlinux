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
AUR_UID="1000"
AUR_USER="${AUR_USER:-aur}"
AUR_GROUP="${AUR_GROUP:-$AUR_USER}"
AUR_HOME="${AUR_HOME:-/var/lib/aur}"
AUR_BUILD_DIR="${AUR_BUILD_DIR:-${AUR_HOME}/build}"
export GOFLAGS="-buildvcs=false" CGO_ENABLED=0 GOOS=linux
case "$(uname -m)" in x86_64) export GOARCH=amd64 ;; aarch64) export GOARCH=arm64 ;; esac
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main script
rm -Rf "$AUR_BUILD_DIR/yay"
if ! grep -sq "^$AUR_GROUP:" /etc/group; then
  echo "Creating group: $AUR_GROUP"
  groupadd -r -g $AUR_UID $AUR_GROUP
fi
if ! grep -sq "^$AUR_USER:" /etc/passwd; then
  echo "Creating user: $AUR_USER"
  useradd -m -r -s /bin/bash -d "${AUR_HOME}" -u $AUR_UID -g $AUR_UID "$AUR_USER" && passwd -d "$AUR_USER"
fi
grep -sq "^$AUR_USER:" /etc/passwd && grep -sq "^$AUR_GROUP:" /etc/group && chown -Rf $AUR_USER:$AUR_GROUP "$AUR_HOME" || exit 1
if [ -n "$(type -P sudo)" ] && grep -sq "^$AUR_USER:" /etc/passwd; then
  mkdir -p "/etc/sudoers.d"
  echo ''$AUR_USER'     ALL=(ALL) ALL' >"/etc/sudoers.d/$AUR_USER"
fi
mkdir -p "$AUR_BUILD_DIR/yay"
if ! grep -qs "standard-resolver" "$AUR_HOME/.gnupg/dirmngr.conf"; then
  mkdir -p "$AUR_HOME/.gnupg"
  echo 'standard-resolver' >"$AUR_HOME/.gnupg/dirmngr.conf"
fi
if [ -z "$(command -v yay 2>/dev/null)" ]; then
  if cd "$AUR_BUILD_DIR/yay"; then
    [ -n "$(type -P git)" ] && git config --global init.defaultBranch main
    chmod -R 777 "$AUR_BUILD_DIR"
    git clone --depth 1 "https://aur.archlinux.org/yay-bin" "." && rm -Rf ".git"
    sudo -HE -u "$AUR_USER" makepkg -sri --needed --noconfirm -si || exit 1
    sudo -HE -u "$AUR_USER" yay --afterclean --removemake --save --noconfirm
    pacman -Qtdq | xargs -r sudo -HE pacman --noconfirm -Rcns || true
    [ -d "$AUR_BUILD_DIR" ] && cd && rm -Rf "${AUR_BUILD_DIR:?}"/* "$AUR_HOME/.cache"/* || true
  else
    exit 1
  fi
fi
[ -n "$(type -P yay 2>/dev/null)" ]
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the exit code
exitCode=$?
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $exitCode
