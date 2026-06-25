#!/usr/bin/env python3
"""Lee alertas de Suricata y las envía a Loki y Wazuh via socket interno"""
import json
import requests
import time
import os
import subprocess
LOKI_URL = "http://localhost:3100/loki/api/v1/push"
EVE_FILE = "/home/jcl/tesis/detectionstk/suricata/logs/eve.json"
WAZUH_CONTAINER = "single-node-wazuh.manager-1"
def send_to_loki(signature, src_ip, dest_ip, category, severity):
    payload = {
        "streams": [{
            "stream": {
                "job": "suricata_alerts",
                "source": "ids",
                "severity": str(severity)
            },
            "values": [[
                str(int(time.time() * 1e9)),
                json.dumps({
                    "signature": signature,
                    "src_ip": src_ip,
                    "dest_ip": dest_ip,
                    "category": category,
                    "severity": severity,
                    "event_type": "alert"
                })
            ]]
        }]
    }
    try:
        requests.post(LOKI_URL, json=payload, timeout=2)
    except:
        pass
def send_to_wazuh_socket(signature, src_ip, dest_ip, category, severity):
    """Envía alerta al socket de Wazuh dentro del contenedor"""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    msg = f"1:suricata:{timestamp}:suricata: Alert: {signature} | Src: {src_ip} | Dst: {dest_ip} | Cat: {category} | Sev: {severity}"
    
    # Comando Python dentro del contenedor para enviar al socket
    cmd = [
        "docker", "exec", "-i", WAZUH_CONTAINER,
        "python3", "-c", f"""
import socket, struct
msg = '''{msg}'''.encode()
sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
sock.connect('/var/ossec/queue/sockets/queue')
header = struct.pack('<I', len(msg))
sock.send(header + msg)
sock.close()
print('OK')
"""
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, timeout=10, text=True)
        if 'OK' in result.stdout:
            print("  ✓ Wazuh (socket)")
            return True
        else:
            print(f"  ✗ Wazuh: {result.stderr[:100]}")
            return False
    except Exception as e:
        print(f"  ✗ Wazuh error: {e}")
        return False
def main():
    last_position = 0
    position_file = "/tmp/suricata_eve_position.txt"
    try:
        with open(position_file, 'r') as f:
            last_position = int(f.read().strip())
    except:
        pass
    
    print("=" * 60)
    print("SURICATA MONITOR - Loki + Wazuh Socket (desde HOST)")
    print("=" * 60)
    print(f"Origen: {EVE_FILE}")
    print(f"Loki: {LOKI_URL}")
    print(f"Wazuh: Socket via docker exec")
    print(f"Ultima posicion: {last_position}")
    print("=" * 60)
    while True:
        try:
            with open(EVE_FILE, 'r') as f:
                f.seek(last_position)
                nuevas = 0
                for line in f:
                    try:
                        event = json.loads(line)
                        if event.get('event_type') == 'alert':
                            alert = event.get('alert', {})
                            signature = alert.get('signature', 'unknown')
                            category = alert.get('category', 'unknown')
                            severity = alert.get('severity', 3)
                            src_ip = event.get('src_ip', 'unknown')
                            dest_ip = event.get('dest_ip', 'unknown')
                            
                            nuevas += 1
                            print(f"Alerta #{nuevas}: {signature[:50]}...")
                            
                            send_to_loki(signature, src_ip, dest_ip, category, severity)
                            send_to_wazuh_socket(signature, src_ip, dest_ip, category, severity)
                            
                    except json.JSONDecodeError:
                        pass
                
                last_position = f.tell()
                try:
                    with open(position_file, 'w') as f:
                        f.write(str(last_position))
                except:
                    pass
                    
        except FileNotFoundError:
            print(f"Archivo no encontrado: {EVE_FILE}")
        except Exception as e:
            print(f"Error: {e}")
        time.sleep(5)
if __name__ == '__main__':
    main()
