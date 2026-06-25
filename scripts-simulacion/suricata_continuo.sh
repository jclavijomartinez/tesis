#!/bin/bash
LOGS_DIR="/home/jcl/tesis/detectionstk/suricata/logs"
PCAP_TEMP="/tmp/suricata_live.pcap"

echo "[+] Iniciando captura continua de Suricata (intervalo: 30s)"
echo "[+] Presiona Ctrl+C para detener"

while true; do
    sudo timeout 20 tcpdump -i any -w $PCAP_TEMP -c 10000 2>/dev/null
    sudo suricata -c /etc/suricata/suricata.yaml -r $PCAP_TEMP -l $LOGS_DIR 2>/dev/null
    sleep 5
done
