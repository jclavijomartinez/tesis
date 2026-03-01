#!/bin/bash
set -e

echo "Interfaces detectadas en contenedor:"
ip -o link show | awk -F': ' '{print $2}'

# Detectar interfaces
IFACE_LAN="eth0"
IFACE_WAN="eth1"

echo "Iniciando Snort en modo inline con $IFACE_LAN:$IFACE_WAN..."
exec snort -Q --daq afpacket -c /etc/snort/snort.conf -i $IFACE_LAN:$IFACE_WAN -A console
