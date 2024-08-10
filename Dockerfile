# syntax=docker/dockerfile:experimental
# Docker image for archlinux using the archlinux template
ARG IMAGE_NAME="archlinux"
ARG PHP_SERVER="archlinux"
ARG BUILD_DATE="202408101733"
ARG LANGUAGE="en_US.UTF-8"
ARG TIMEZONE="America/New_York"
ARG WWW_ROOT_DIR="/usr/share/httpd/default"
ARG DEFAULT_FILE_DIR="/usr/local/share/template-files"
ARG DEFAULT_DATA_DIR="/usr/local/share/template-files/data"
ARG DEFAULT_CONF_DIR="/usr/local/share/template-files/config"
ARG DEFAULT_TEMPLATE_DIR="/usr/local/share/template-files/defaults"

ARG USER="root"
ARG SHELL_OPTS="set -e -o pipefail"
ARG AUR_USER="aur"
ARG AUR_HOME="/home/aur"

ARG SERVICE_PORT=""
ARG EXPOSE_PORTS=""
ARG PHP_VERSION="system"
ARG NODE_VERSION="system"
ARG NODE_MANAGER="system"

ARG IMAGE_REPO="casjaysdev/archlinux"
ARG IMAGE_VERSION="latest"
ARG CONTAINER_VERSION="USE_DATE"

ARG PULL_URL="menci/archlinuxarm"
ARG DISTRO_VERSION="${IMAGE_VERSION}"
ARG BUILD_VERSION="${BUILD_DATE}"

FROM tianon/gosu:latest AS gosu
FROM ${PULL_URL}:${DISTRO_VERSION} AS build
ARG TZ
ARG USER
ARG LICENSE
ARG TIMEZONE
ARG LANGUAGE
ARG IMAGE_NAME
ARG BUILD_DATE
ARG SERVICE_PORT
ARG EXPOSE_PORTS
ARG BUILD_VERSION
ARG IMAGE_VERSION
ARG WWW_ROOT_DIR
ARG DEFAULT_FILE_DIR
ARG DEFAULT_DATA_DIR
ARG DEFAULT_CONF_DIR
ARG DEFAULT_TEMPLATE_DIR
ARG DISTRO_VERSION
ARG NODE_VERSION
ARG NODE_MANAGER
ARG PHP_VERSION
ARG PHP_SERVER
ARG SHELL_OPTS

ARG AUR_USER
ARG AUR_HOME

ARG PACK_LIST="bash-completion git curl wget sudo unzip base-devel mailx postfix python python-pip certbot ca-certificates "

ENV ENV=~/.profile
ENV SHELL="/bin/sh"
ENV TZ="${TIMEZONE}"
ENV TIMEZONE="${TZ}"
ENV LANG="${LANGUAGE}"
ENV TERM="xterm-256color"
ENV HOSTNAME="casjaysdev-archlinux"

USER ${USER}
WORKDIR /root

RUN set -e; \
  echo "Setting up prerequisites"; \
  pacman -Sy --noconfirm archlinux-keyring; \
  pacman-key --init; \
  pacman-key --populate; \
  echo "installing bash"; \
  pacman -Sy --noconfirm bash; \
  SH_CMD="$(which sh 2>/dev/null)"; \
  BASH_CMD="$(which bash 2>/dev/null)"; \
  [ -n "$BASH_CMD" ] && sed -i 's|root:x:.*|root:x:0:0:root:/root:'$BASH_CMD'|g' "/etc/passwd" || true; \
  [ -x "$BASH_CMD" ] && [ "$SH_CMD" != "/bin/sh" ] && { rm -Rf "$SH_CMD";ln -s "$BASH_CMD" "$SH_CMD"; } || true; \
  [ -x "$BASH_CMD" ] && [ ! -L "/bin/sh" ] && { rm -rf "/bin/sh" || true; } && ln -sf "$BASH_CMD" "/bin/sh" || true

ENV SHELL="/bin/bash"
SHELL [ "/bin/bash", "-c" ]

COPY ./rootfs/usr/local/bin/pkmgr /usr/local/bin/pkmgr
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu

RUN echo "Initializing the system"; \
  $SHELL_OPTS; \
  if [ -f "/root/docker/setup/00-init.sh" ];then echo "Running the init script";bash "/root/docker/setup/00-init.sh";echo "Done running the init script";fi; \
  echo ""

RUN echo "Creating and editing system files "; \
  $SHELL_OPTS; \
  [ -f "/root/.profile" ] || touch "/root/.profile"; \
  mkdir -p "${DEFAULT_DATA_DIR}" "${DEFAULT_CONF_DIR}" "${DEFAULT_TEMPLATE_DIR}" "/root/docker/setup" "/etc/profile.d"; \
  if [ -f "/root/docker/setup/01-system.sh" ];then echo "Running the system script";bash "/root/docker/setup/01-system.sh";echo "Done running the system script";fi; \
  echo ""

RUN echo "Running pre-package commands"; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Setting up and installing packages"; \
  $SHELL_OPTS; \
  if [ -n "${PACK_LIST}" ];then echo "Installing packages: $PACK_LIST";echo "${PACK_LIST}" >/root/docker/setup/packages.txt;pkmgr install ${PACK_LIST};fi; \
  echo ""

RUN echo "Initializing packages before copying files to image"; \
  $SHELL_OPTS; \
  if [ -f "/root/docker/setup/02-packages.sh" ];then echo "Running the packages script";bash "/root/docker/setup/02-packages.sh";echo "Done running the packages script";fi; \
  echo ""

COPY ./rootfs/. /
COPY ./Dockerfile /root/docker/Dockerfile

RUN echo "Updating system files "; \
  $SHELL_OPTS; \
  echo "$TIMEZONE" >"/etc/timezone"; \
  touch "/etc/profile" "/root/.profile"; \
  echo 'hosts: files dns' >"/etc/nsswitch.conf"; \
  [ "$PHP_VERSION" = "system" ] && PHP_VERSION="php" || true; \
  PHP_BIN="$(command -v ${PHP_VERSION} 2>/dev/null || true)"; \
  PHP_FPM="$(ls /usr/*bin/php*fpm* 2>/dev/null || true)"; \
  pip_bin="$(command -v python3 2>/dev/null || command -v python2 2>/dev/null || command -v python 2>/dev/null || true)"; \
  py_version="$(command $pip_bin --version | sed 's|[pP]ython ||g' | awk -F '.' '{print $1$2}' | grep '[0-9]' || true)"; \
  [ "$py_version" -gt "310" ] && pip_opts="--break-system-packages " || pip_opts=""; \
  if [ -n "$pip_bin" ];then $pip_bin -m pip install certbot-dns-rfc2136 certbot-dns-duckdns certbot-dns-cloudflare certbot-nginx $pip_opts || true;fi; \
  [ -f "/usr/share/zoneinfo/${TZ}" ] && ln -sf "/usr/share/zoneinfo/${TZ}" "/etc/localtime" || true; \
  [ -n "$PHP_BIN" ] && [ -z "$(command -v php 2>/dev/null)" ] && ln -sf "$PHP_BIN" "/usr/bin/php" 2>/dev/null || true; \
  [ -n "$PHP_FPM" ] && [ -z "$(command -v php-fpm 2>/dev/null)" ] && ln -sf "$PHP_FPM" "/usr/bin/php-fpm" 2>/dev/null || true; \
  if [ -f "/etc/profile.d/color_prompt.sh.disabled" ]; then mv -f "/etc/profile.d/color_prompt.sh.disabled" "/etc/profile.d/color_prompt.sh";fi ; \
  { [ -f "/etc/bash/bashrc" ] && cp -Rf "/etc/bash/bashrc" "/root/.bashrc"; } || { [ -f "/etc/bashrc" ] && cp -Rf "/etc/bashrc" "/root/.bashrc"; } || { [ -f "/etc/bash.bashrc" ] && cp -Rf "/etc/bash.bashrc" "/root/.bashrc"; } || true; \
  if [ -z "$(command -v "apt-get" 2>/dev/null)" ];then grep -s -q 'alias quit' "/root/.bashrc" || printf '# Profile\n\n%s\n%s\n%s\n' '. /etc/profile' '. /root/.profile' "alias quit='exit 0 2>/dev/null'" >>"/root/.bashrc"; fi; \
  if [ "$PHP_VERSION" != "system" ] && [ -e "/etc/php" ] && [ -d "/etc/${PHP_VERSION}" ];then rm -Rf "/etc/php";fi; \
  if [ "$PHP_VERSION" != "system" ] && [ -n "${PHP_VERSION}" ] && [ -d "/etc/${PHP_VERSION}" ];then ln -sf "/etc/${PHP_VERSION}" "/etc/php";fi; \
  if [ -f "/root/docker/setup/03-files.sh" ];then echo "Running the files script";bash "/root/docker/setup/03-files.sh";echo "Done running the files script";fi; \
  echo ""

RUN echo "Custom Settings"; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Setting up users and scripts "; \
  $SHELL_OPTS; \
  if ! grep -s -q "${AUR_HOME}" /etc/passwd;then useradd -m -r -s /bin/bash -d "${AUR_HOME}" "${AUR_USER}";fi; \
  passwd -d "${AUR_USER}"; \
  [ -d "/etc/sudoers.d" ] || mkdir -p "/etc/sudoers.d"; \
  echo ''${AUR_USER}'     ALL=(ALL) ALL' >"/etc/sudoers.d/${AUR_USER}" && \
  echo 'standard-resolver' >"${AUR_HOME}/.gnupg/dirmngr.conf" && \
  chown -Rf "${AUR_USER}":"${AUR_USER}" "${AUR_HOME}"; \
  if [ -z "$(command -v yay 2>/dev/null)" ];then cd "${AUR_HOME}/build" && \
  sudo -u "${AUR_USER}" git clone --depth 1 "https://aur.archlinux.org/yay.git" && cd yay && \
  sudo -u "${AUR_USER}" makepkg --noconfirm -si; \
  fi; \
  sudo -u "${AUR_USER}" yay --afterclean --removemake --save && pacman -Qtdq | xargs -r pacman --noconfirm -Rcns; \
  if [ -f "/root/docker/setup/04-users.sh" ];then echo "Running the users script";bash "/root/docker/setup/04-users.sh";echo "Done running the users script";fi; \
  echo ""

RUN echo "Running the user init commands"; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Setting OS Settings "; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Custom Applications"; \
  $SHELL_OPTS; \
  echo ""

RUN echo "Running custom commands"; \
  if [ -f "/root/docker/setup/05-custom.sh" ];then echo "Running the custom script";bash "/root/docker/setup/05-custom.sh";echo "Done running the custom script";fi; \
  echo ""

RUN echo "Running final commands before cleanup"; \
  $SHELL_OPTS; \
  if [ -f "/root/docker/setup/06-post.sh" ];then echo "Running the post script";bash "/root/docker/setup/06-post.sh";echo "Done running the post script";fi; \
  echo ""

RUN echo "Deleting unneeded files"; \
  $SHELL_OPTS; \
  pkmgr clean; \
  rm -Rf "/config" "/data" || true; \
  rm -rf /etc/systemd/system/*.wants/* || true; \
  rm -rf /lib/systemd/system/systemd-update-utmp* || true; \
  rm -rf /lib/systemd/system/anaconda.target.wants/* || true; \
  rm -rf /lib/systemd/system/local-fs.target.wants/* || true; \
  rm -rf /lib/systemd/system/multi-user.target.wants/* || true; \
  rm -rf /lib/systemd/system/sockets.target.wants/*udev* || true; \
  rm -rf /lib/systemd/system/sockets.target.wants/*initctl* || true; \
  rm -Rf /usr/share/doc/* /var/tmp/* /var/cache/*/* /root/.cache/* /usr/share/info/* /tmp/* || true; \
  if [ -d "/lib/systemd/system/sysinit.target.wants" ];then cd "/lib/systemd/system/sysinit.target.wants" && rm -f $(ls | grep -v systemd-tmpfiles-setup);fi; \
  if [ -f "/root/docker/setup/07-cleanup.sh" ];then echo "Running the cleanup script";bash "/root/docker/setup/07-cleanup.sh";echo "Done running the cleanup script";fi; \
  echo ""

RUN echo "Init done"
FROM scratch
ARG TZ
ARG USER
ARG TIMEZONE
ARG LANGUAGE
ARG IMAGE_NAME
ARG BUILD_DATE
ARG SERVICE_PORT
ARG EXPOSE_PORTS
ARG BUILD_VERSION
ARG IMAGE_VERSION
ARG WWW_ROOT_DIR
ARG DEFAULT_FILE_DIR
ARG DEFAULT_DATA_DIR
ARG DEFAULT_CONF_DIR
ARG DEFAULT_TEMPLATE_DIR
ARG DISTRO_VERSION
ARG NODE_VERSION
ARG NODE_MANAGER
ARG PHP_VERSION
ARG PHP_SERVER
ARG LICENSE="WTFPL"
ARG ENV_PORTS=""
ARG GIT_VERSION="$(git -C . show-ref --head --dereference 2>/dev/null|grep ' HEAD' |awk -F' ' '{print $1}')"

USER ${USER}
WORKDIR /root

LABEL maintainer="CasjaysDev <docker-admin@casjaysdev.pro>"
LABEL org.opencontainers.image.vendor="CasjaysDev"
LABEL org.opencontainers.image.authors="CasjaysDev"
LABEL org.opencontainers.image.description="Containerized version of ${IMAGE_NAME}"
LABEL org.opencontainers.image.name="${IMAGE_NAME}"
LABEL org.opencontainers.image.base.name="${IMAGE_NAME}"
LABEL org.opencontainers.image.license="${LICENSE}"
LABEL org.opencontainers.image.build-date="${BUILD_DATE}"
LABEL org.opencontainers.image.version="${BUILD_VERSION}"
LABEL org.opencontainers.image.schema-version="${BUILD_VERSION}"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/casjaysdevdocker/archlinux"
LABEL org.opencontainers.image.url.source="https://hub.docker.com/r/casjaysdevdocker/archlinux"
LABEL org.opencontainers.image.vcs-type="Git"
LABEL org.opencontainers.image.vcs-ref="${GIT_VERSION}"
LABEL org.opencontainers.image.vcs-url="https://github.com/casjaysdevdocker/archlinux"
LABEL org.opencontainers.image.documentation="https://github.com/casjaysdevdocker/archlinux"
LABEL com.github.containers.toolbox="false"

ENV ENV=~/.bashrc
ENV USER="${USER}"
ENV SHELL="/bin/bash"
ENV TZ="${TIMEZONE}"
ENV TIMEZONE="${TZ}"
ENV LANG="${LANGUAGE}"
ENV TERM="xterm-256color"
ENV PORT="${SERVICE_PORT}"
ENV ENV_PORTS="${ENV_PORTS}"
ENV CONTAINER_NAME="${IMAGE_NAME}"
ENV HOSTNAME="casjaysdev-${IMAGE_NAME}"
ENV PHP_SERVER="${PHP_SERVER}"
ENV NODE_VERSION="${NODE_VERSION}"
ENV NODE_MANAGER="${NODE_MANAGER}"
ENV PHP_VERSION="${PHP_VERSION}"
ENV DISTRO_VERSION="${IMAGE_VERSION}"
ENV WWW_ROOT_DIR="${WWW_ROOT_DIR}"

COPY --from=build /. /

VOLUME [ "/config","/data" ]

EXPOSE ${SERVICE_PORT} ${ENV_PORTS}

CMD [ "tail", "-f", "/dev/null" ]
ENTRYPOINT [ "tini","--","/usr/local/bin/entrypoint.sh" ]
HEALTHCHECK --start-period=10m --interval=5m --timeout=15s CMD [ "/usr/local/bin/entrypoint.sh", "healthcheck" ]
