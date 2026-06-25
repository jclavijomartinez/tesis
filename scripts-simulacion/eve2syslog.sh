#!/bin/bash
# Convierte alertas de Suricata (eve.json) a formato syslog para Wazuh

EVE_FILE="/home/jcl/tesis/detectionstk/suricata/logs/eve.json"
SYSLOG_FILE="/var/log/suricata_alerts.log"

# Inicializar el archivo de salida
sudo touch $SYSLOG_FILE
sudo chmod 644 $SYSLOG_FILE

while true; do
    # Leer las últimas 50 líneas del eve.json
    sudo tail -50 $EVE_FILE | while read line; do
        # Verificar si la línea contiene una alerta
        if echo "$line" | grep -q '"event_type":"alert"'; then
            # Extraer la firma usando Python
            SIGNATURE=$(echo "$line" | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.readline())
    alert = d.get('alert', {})
    sig = alert.get('signature', 'unknown')
    print(sig)
except:
    print('parse_error')
" 2>/dev/null)
            
            TIMESTAMP=$(date +"%b %d %H:%M:%S")
            echo "$TIMESTAMP ds suricata: Alert: $SIGNATURE" | sudo tee -a $SYSLOG_FILE > /dev/null
        fi
    done
    
    sleep 30
done
