#!/usr/bin/env python3
"""Lee alertas de Suricata y las envía a Wazuh analysisd via socket"""
import json
import time
import os
import subprocess
EVE_FILE = "/home/jcl/tesis/detectionstk/suricata/logs/eve.json"
WAZUH_CONTAINER = "single-node-wazuh.manager-1"
def send_batch_to_wazuh(alerts):
    """Envía un lote de alertas al socket de Wazuh"""
    if not alerts:
        return
    
    # Construir script Python para ejecutar dentro del contenedor
    python_code = "import socket, struct\n"
    for msg in alerts:
        python_code += f"""
try:
    msg = '''{msg}'''.encode()
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    sock.connect('/var/ossec/queue/sockets/queue')
    header = struct.pack('<I', len(msg))
    sock.send(header + msg)
    sock.close()
except:
    pass
"""
    python_code += "print('OK')"
    
    cmd = [
        "docker", "exec", "-i", WAZUH_CONTAINER,
        "python3", "-c", python_code
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, timeout=30, text=True)
        if 'OK' in result.stdout:
            print(f"  ✓ Lote de {len(alerts)} alertas enviado a Wazuh")
            return True
        else:
            print(f"  ✗ Error: {result.stderr[:100]}")
            return False
    except Exception as e:
        print(f"  ✗ Error: {e}")
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
    print("SURICATA -> WAZUH ANALYSISD (socket directo)")
    print("=" * 60)
    print(f"Origen: {EVE_FILE}")
    print(f"Ultima posicion: {last_position}")
    print("=" * 60)
    batch = []
    batch_size = 50  # Enviar de 50 en 50
    
    while True:
        try:
            with open(EVE_FILE, 'r') as f:
                f.seek(last_position)
                
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
                            
                            timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
                            msg = f"1:suricata:{timestamp}:suricata: Alert: {signature} | Src: {src_ip} | Dst: {dest_ip} | Cat: {category} | Sev: {severity}"
                            
                            batch.append(msg)
                            
                            if len(batch) >= batch_size:
                                send_batch_to_wazuh(batch)
                                batch = []
                                
                    except json.JSONDecodeError:
                        pass
                
                # Enviar lo que quede
                if batch:
                    send_batch_to_wazuh(batch)
                    batch = []
                
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
        time.sleep(10)
if __name__ == '__main__':
    main()
