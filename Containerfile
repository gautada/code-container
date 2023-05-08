ARG ALPINE_VERSION="latest"

FROM gautada/alpine:$ALPINE_VERSION

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL source="https://github.com/gautada/code-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"

# ╭――――――――――――――――――――╮
# │ STANDARD CONFIG    │
# ╰――――――――――――――――――――╯

# USER:
ARG USER=coder

ARG UID=1001
ARG GID=1001
RUN /usr/sbin/addgroup -g $GID $USER \
 && /usr/sbin/adduser -D -G $USER -s /bin/zsh -u $UID $USER \
 && /usr/sbin/usermod -aG wheel $USER \
 && /bin/echo "$USER:$USER" | chpasswd

# PRIVILEGE:
COPY wheel  /etc/container/wheel
RUN /bin/ln -fsv /etc/container/wheel /etc/sudoers.d/wheel
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

# Older VS Code build config
# RUN /bin/ln -fsv /mnt/volumes/configmaps/code-server.yml /etc/container/code-server.yml \
#  && /bin/ln -fsv /mnt/volumes/container/code-server.yml /mnt/volumes/configmaps/code-server.yml
#  
# RUN /sbin/apk --no-cache add build-base pkgconf
# RUN /sbin/apk --no-cache add git npm yarn nodejs
# RUN /sbin/apk --no-cache add alpine-sdk bash libstdc++ libc6-compat
# RUN /usr/bin/npm config set python python3
# 
# RUN git clone --branch v4.12.0 https://github.com/coder/code-server.git
# WORKDIR code-server
# RUN yarn global add code-server

RUN /sbin/apk add --no-cache build-base yarn npm git
RUN /sbin/apk add --no-cache openssh-client openssh 
RUN /sbin/apk add --no-cache tmux tpm
RUN /sbin/apk add --no-cache neovim neovim-doc
RUN /sbin/apk add --no-cache zsh
RUN /sbin/apk add --no-cache nerd-fonts-all

RUN /sbin/apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing kubectl

RUN /bin/ln -fsv /mnt/volumes/container /Workspace
COPY --chown=$USER tmux.conf /home/$USER/.config/tmux/tmux.conf

# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯

USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/container
EXPOSE 8080/tcp
WORKDIR /Workspace

RUN git clone https://github.com/gautada/config.git /home/$USER/.config/repo
RUN /bin/ln -fsv /home/$USER/.config/repo/public /home/$USER/.config/nvim

RUN /bin/mkdir -p /home/$USER/.config/git/ \
 && /bin/ln -fsv /home/$USER/.config/git/config /home/$USER/.gitconfig \
 && /bin/ln -fsv /mnt/volumes/configmaps/git-config  /home/$USER/.config/git/config \
 && /bin/ln -fsv /home/$USER/.config/git/credentials /home/$USER/.git-credentials \
 && /bin/ln -fsv /mnt/volumes/secrets/container/git-credentials /home/$USER/.config/git/credentials 

RUN /bin/ln -fsv /mnt/volumes/secrets/container/ca.key /home/$USER/.config/git/ca.key \
 && /bin/ln -fsv /mnt/volumes/secrets/container/ca.crt /home/$USER/.config/git/ca.crt 

RUN /usr/bin/yarn global add wetty

# COPY setup-vault /home/$USER/.scripts/setup-vault
# COPY setup-client-ca /home/$USER/.scripts/setup-client-ca
# RUN ln -s /home/$USER/.scripts/setup-vault /home/$USER/setup-vault \
#  && ln -s /home/$USER/.scripts/setup-client-ca /home/$USER/setup-client-ca
# RUN /bin/mkdir -p ~/.kube
