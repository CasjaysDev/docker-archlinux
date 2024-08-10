## 👋 Welcome to archlinux 🚀  

archlinux README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update archlinux
```
  
## Install and run container
  
```shell
mkdir -p "$HOME/.local/share/srv/docker/archlinux/rootfs"
git clone "https://github.com/dockermgr/archlinux" "$HOME/.local/share/CasjaysDev/dockermgr/archlinux"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/archlinux/rootfs/." "$HOME/.local/share/srv/docker/archlinux/rootfs/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-archlinux \
--hostname archlinux \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-archlinux/rootfs/data:/data:z" \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-archlinux/rootfs/config:/config:z" \
-p 80:80 \
casjaysdevdocker/archlinux:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/archlinux
    container_name: casjaysdevdocker-archlinux
    environment:
      - TZ=America/New_York
      - HOSTNAME=archlinux
    volumes:
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-archlinux/rootfs/data:/data:z"
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-archlinux/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/archlinux
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/archlinux" "$HOME/Projects/github/casjaysdevdocker/archlinux"
```
  
## Build container  
  
```shell
cd "$HOME/Projects/github/casjaysdevdocker/archlinux"
buildx 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  
