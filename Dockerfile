# Ubuntu 24.04 LTS as per the wiki
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    SRCDS_USER=srcds \
    SRCDS_HOME=/home/srcds \
    TF_DIR=/home/srcds/tf \
    TF2C_DIR=/home/srcds/classified

# Enable i386 + install dependencies (NO apt steamcmd)
RUN apt-get update && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      wget \
      tar \
      dialog \
      p7zip \
      aria2 \
      tilde \
      rsync \
      gosu \
      lib32z1 \
      libbz2-1.0:i386 \
      lib32gcc-s1 \
      lib32stdc++6 \
      libcurl3-gnutls:i386 \
      libsdl2-2.0-0:i386 \
      libc6:i386 \
    && rm -rf /var/lib/apt/lists/*

# Install SteamCMD directly from Valve (avoids EULA / dpkg issues)
RUN mkdir -p /opt/steamcmd && \
    wget -qO /opt/steamcmd/steamcmd_linux.tar.gz \
      https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && \
    tar -xzf /opt/steamcmd/steamcmd_linux.tar.gz -C /opt/steamcmd && \
    ln -sf /opt/steamcmd/steamcmd.sh /usr/local/bin/steamcmd

# Create disabled user with home (matches wiki)
RUN useradd -s /bin/false -mr ${SRCDS_USER}

# Prepare directories + ownership
RUN mkdir -p "${TF_DIR}" "${TF2C_DIR}" "${SRCDS_HOME}/bin" && \
    chown -R ${SRCDS_USER}:${SRCDS_USER} "${SRCDS_HOME}"

# SteamCMD scripts (update TF + TF2C)
RUN cat <<'EOF' > /home/srcds/bin/update-tf.steamcmd
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir /home/srcds/tf
login anonymous
app_update 232250 validate
quit
EOF

RUN cat <<'EOF' > /home/srcds/bin/update-classified.steamcmd
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir /home/srcds/classified
login anonymous
app_update 3557020 validate
quit
EOF

RUN chown -R srcds:srcds /home/srcds/bin

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Persistent volumes
VOLUME ["/home/srcds/tf", "/home/srcds/classified"]

# TF2 / Source ports
EXPOSE 27015/udp 27015/tcp

ENTRYPOINT ["/entrypoint.sh"]
