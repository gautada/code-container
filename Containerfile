ARG ALPINE_VERSION="latest"

FROM gautada/alpine:$ALPINE_VERSION

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL source="https://github.com/gautada/vscode-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"
LABEL description="A Visual Studio Code Server in a container"

# ╭――――――――――――――――――――╮
# │ STANDARD CONFIG    │
# ╰――――――――――――――――――――╯

# USER:
ARG USER=vscode

ARG UID=1001
ARG GID=1001
RUN /usr/sbin/addgroup -g $GID $USER \
 && /usr/sbin/adduser -D -G $USER -s /bin/ash -u $UID $USER \
 && /usr/sbin/usermod -aG wheel $USER \
 && /bin/echo "$USER:$USER" | chpasswd

# PRIVILEGE:
COPY wheel  /etc/container/wheel

# BACKUP:
COPY backup /etc/container/backup

# ENTRYPOINT:
RUN rm -v /etc/container/entrypoint
COPY entrypoint /etc/container/entrypoint

# FOLDERS
RUN /bin/chown -R $USER:$USER /mnt/volumes/container \
 && /bin/chown -R $USER:$USER /mnt/volumes/backup \
 && /bin/chown -R $USER:$USER /var/backup \
 && /bin/chown -R $USER:$USER /tmp/backup


# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
# RUN mkdir /home/$USER/dwn
# COPY VSCode-linux-arm64/* /home/$USER/dwn

RUN /bin/ln -fsv /mnt/volumes/configmaps/config.yml /etc/container/config.yml \
 && /bin/ln -fsv /mnt/volumes/container/config.yml /mnt/volumes/configmaps/config.yml
 
RUN /sbin/apk --no-cache add build-base pkgconf
RUN /sbin/apk --no-cache add alpine-sdk bash libstdc++ libc6-compat
RUN /sbin/apk --no-cache add git npm yarn nodejs
RUN /usr/bin/npm install --global minimist --unsafe-perm
RUN /usr/bin/npm install --global code-server --unsafe-perm
RUN /usr/bin/npm install --global yazl yauzl --unsafe-perm
#    @vscode/ripgrep
RUN /usr/bin/npm install --global spdlog xterm-headless  vscode-proxy-agent vscode-regexpp --unsafe-perm
RUN /usr/bin/npm install --global @microsoft/1ds-core-js --unsafe-perm


# RUN mkdir -p /home/$USER/.config/code-server
# COPY config.yml /home/$USER/.config/code-server/config.yaml
# RUN chown $USER:$USER -R /home/$USER

# RUN npm config set python python3

# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯
USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/container
EXPOSE 3306/tcp 8080/tcp
WORKDIR /home/$USER
