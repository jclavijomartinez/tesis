#!/bin/bash
set -euo pipefail

echo "[INFO] Interfaces dentro del contenedor:"
ip -o link show | awk -F': ' '{print " - " $2}'

# Detectar primera interfaz distinta de 'lo'
RAW_IF=$(ip -o link show | awk -F': ' '$2!="lo" {print $2; exit}')

# Eliminar sufijos tipo @ifX y espacios en blanco
LAN_IF=$(echo "$RAW_IF" | cut -d'@' -f1 | tr -d '[:space:]')

if [[ -z "${LAN_IF:-}" ]]; then
  echo "[ERROR] No se pudo detectar interfaz LAN"
  ip -o link show
  exit 1
fi

# Mostrar si tiene IP (sin romper set -e)
LAN_IP=$(ip -o -4 addr show dev "$LAN_IF" | awk '{print $4}' || true)
if [[ -z "${LAN_IP}" ]]; then
  echo "[INFO] La interfaz $LAN_IF no tiene IPv4 asignada (esto es normal en macvlan DHCP)"
else
  echo "[INFO] La interfaz $LAN_IF tiene IPv4 asignada: $LAN_IP"
fi

echo "[INFO] Usando interfaz LAN: $LAN_IF"

# Arrancar dnsmasq en foreground solo en la LAN
exec dnsmasq -k -d \
  --interface="$LAN_IF" \
  --bind-dynamic
