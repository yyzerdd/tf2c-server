#!/usr/bin/env bash
set -euo pipefail

SRCDS_USER="${SRCDS_USER:-srcds}"
SRCDS_HOME="${SRCDS_HOME:-/home/srcds}"
TF_DIR="${TF_DIR:-/home/srcds/tf}"
TF2C_DIR="${TF2C_DIR:-/home/srcds/classified}"

# Server settings via env (override in TrueNAS)
PORT="${PORT:-27015}"
MAP="${MAP:-ctf_2fort}"
MAXPLAYERS="${MAXPLAYERS:-24}"
LAN_ONLY="${LAN_ONLY:-0}"          # 1 = sv_lan 1
SV_PASSWORD="${SV_PASSWORD:-}"     # optional
USE_SDR="${USE_SDR:-0}"            # 1 = sv_use_steam_networking 1

# Ensure permissions (important for mounted datasets)
chown -R "${SRCDS_USER}:${SRCDS_USER}" "${SRCDS_HOME}" || true

# Update/install on container start (recommended)
echo "Updating TF2 (232250) + TF2C (3557020) via steamcmd..."
gosu "${SRCDS_USER}" bash -lc ". /etc/environment || true; steamcmd +runscript ${SRCDS_HOME}/bin/update-tf.steamcmd"
gosu "${SRCDS_USER}" bash -lc ". /etc/environment || true; steamcmd +runscript ${SRCDS_HOME}/bin/update-classified.steamcmd"

# Basic config writes (optional conveniences)
CFG_DIR="${TF2C_DIR}/tf2classified/cfg"
mkdir -p "${CFG_DIR}"
if [[ "${LAN_ONLY}" == "1" ]]; then
  echo "sv_lan 1" >> "${CFG_DIR}/server.cfg"
fi
if [[ -n "${SV_PASSWORD}" ]]; then
  echo "sv_password ${SV_PASSWORD}" >> "${CFG_DIR}/server.cfg"
fi
if [[ "${USE_SDR}" == "1" ]]; then
  echo "sv_use_steam_networking 1" >> "${CFG_DIR}/default.cfg"
fi

# Launch
echo "Starting TF2C server on port ${PORT} map ${MAP} maxplayers ${MAXPLAYERS}..."
exec gosu "${SRCDS_USER}" bash -lc "
  cd '${TF2C_DIR}' &&
  export LD_LIBRARY_PATH='.:bin/linux64:'\"\$LD_LIBRARY_PATH\" &&
  ./srcds_linux64 -port '${PORT}' -tf_path '${TF_DIR}' +map '${MAP}' +maxplayers '${MAXPLAYERS}'
"
