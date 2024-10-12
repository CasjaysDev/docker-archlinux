## 👋 Welcome to archlinux 🚀  

archlinux README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update os archlinux
```
  
## Install and run container
  
```shell
mkdir -p "/var/lib/srv/root/docker/casjaysdev/archlinux/latest"
git clone "https://github.com/dockermgr/archlinux" "$HOME/.local/share/CasjaysDev/dockermgr/archlinux"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/archlinux/rootfs/." "/var/lib/srv/root/docker/casjaysdev/archlinux/latest/"
docker run -d \
--restart always \
--privileged \
--name casjaysdev-archlinux-latest \
--hostname archlinux \
-e TZ=${TIMEZONE:-America/New_York} \
-v "/var/lib/srv/root/docker/casjaysdev/archlinux/latest/data:/data:z" \
-v "/var/lib/srv/root/docker/casjaysdev/archlinux/latest/config:/config:z" \
casjaysdev/archlinux:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdev/archlinux
    container_name: casjaysdev-archlinux-latest
    environment:
      - TZ=America/New_York
      - HOSTNAME=archlinux
    volumes:
      - "/var/lib/srv/root/docker/casjaysdev/archlinux/latest/data:/data:z"
      - "/var/lib/srv/root/docker/casjaysdev/archlinux/latest/config:/config:z"
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src os archlinux
```
  
## Build container  
  
```shell
git clone "https://github.com/dockersrc/archlinux" "$HOME/Projects/github/dockersrc/archlinux"
cd "$HOME/Projects/github/dockersrc/archlinux" && buildx all 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdev: [Github](https://github.com/dockersrc) [Docker](https://hub.docker.com/u/casjaysdev) ⛵  
