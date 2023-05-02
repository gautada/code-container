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
RUN /bin/ln -fsv /mnt/volumes/configmaps/code-server.yml /etc/container/code-server.yml \
 && /bin/ln -fsv /mnt/volumes/container/code-server.yml /mnt/volumes/configmaps/code-server.yml
 
RUN /sbin/apk --no-cache add build-base pkgconf
RUN /sbin/apk --no-cache add git npm yarn nodejs
RUN /sbin/apk --no-cache add alpine-sdk bash libstdc++ libc6-compat
RUN /usr/bin/npm config set python python3

RUN git clone --branch v4.12.0 https://github.com/coder/code-server.git
WORKDIR code-server
RUN yarn global add code-server

# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯

USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/container
EXPOSE 3306/tcp 8080/tcp
WORKDIR /home/$USER

RUN /bin/mkdir -p /home/$USER/.config/git/ \
 && /bin/ln -fsv /home/$USER/.config/git/config /home/$USER/.gitconfig \
 && /bin/ln -fsv /mnt/volumes/configmaps/git-config  /home/$USER/.config/git/config \
 && /bin/ln -fsv /home/$USER/.config/git/credentials /home/$USER/.git-credentials \
 && /bin/ln -fsv /mnt/volumes/secrets/container/git-credentials /home/$USER/.config/git/credentials 

RUN /bin/ln -fsv /mnt/volumes/secrets/container/ca.key /home/$USER/.config/git/ca.key \
 && /bin/ln -fsv /mnt/volumes/secrets/namesapce/ca.crt /home/$USER/.config/git/ca.crt


