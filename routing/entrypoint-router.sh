#!/bin/bash
set -euo pipefail

# 1) Habilitar IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# 2) Configurar interfaz LAN (la del bridge macvlan)
LAN_IF="enp0s8"   # el parent físico de la LAN en el host
LAN_IP="192.168.1.1/24"

# Crear interfaz macvlan interna si hace falta
if ! ip link show lan0 &>/dev/null; then
  ip link add lan0 link "$LAN_IF" type macvlan mode bridge
  ip addr add "$LAN_IP" dev lan0
  ip link set lan0 up
fi

echo "[INFO] LAN configurada en lan0 con IP $LAN_IP"

# 3) Detectar interfaz WAN (salida a Internet)
WAN_IF=$(ip route | awk '/^default/ {print $5; exit}')
echo "[INFO] WAN_IF=$WAN_IF"

# 4) NAT Masquerade
iptables -t nat -A POSTROUTING -o "$WAN_IF" -s 192.168.1.0/24 -j MASQUERADE
iptables -A FORWARD -i lan0 -o "$WAN_IF" -j ACCEPT
iptables -A FORWARD -i "$WAN_IF" -o lan0 -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "[INFO] NAT configurado: 192.168.1.0/24 -> $WAN_IF"

# 5) Mantener contenedor vivo
tail -f /dev/null
