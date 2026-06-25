#!/bin/bash
echo "============================================"
echo "  Recuperación de Servicios - SIEM PYME"
echo "============================================"
echo ""

# 1. Esperar que Docker esté listo
echo "[1/5] Esperando que Docker esté listo..."
sleep 10

# 2. Asignar IPs fijas a contenedores
echo "[2/5] Asignando IPs fijas..."
docker network connect --ip 172.18.0.2 monitoring_monitoring node-exporter 2>/dev/null && echo "  ✅ node-exporter → 172.18.0.2"
docker network connect --ip 172.18.0.3 monitoring_monitoring prometheus 2>/dev/null && echo "  ✅ prometheus → 172.18.0.3"
docker network connect --ip 172.18.0.4 monitoring_monitoring grafana 2>/dev/null && echo "  ✅ grafana → 172.18.0.4"
docker network connect --ip 172.18.0.5 monitoring_monitoring alloy 2>/dev/null && echo "  ✅ alloy → 172.18.0.5"
docker network connect --ip 172.18.0.6 monitoring_monitoring cadvisor 2>/dev/null && echo "  ✅ cadvisor → 172.18.0.6"
docker network connect --ip 172.18.0.7 monitoring_monitoring loki 2>/dev/null && echo "  ✅ loki → 172.18.0.7"

# 3. Iniciar Suricata
echo "[3/5] Iniciando Suricata..."
sudo suricata -c /etc/suricata/suricata.yaml -i enp0s3 --af-packet -D 2>/dev/null
if ps aux | grep -q "[s]uricata"; then
    echo "  ✅ Suricata iniciado"
else
    echo "  ❌ Error al iniciar Suricata"
fi

# 4. Iniciar script de correlación
echo "[4/5] Iniciando script de correlación..."
cd /home/jcl/tesis/scripts-simulacion
nohup python3 suricata_correlacion.py > /tmp/suricata_monitor.log 2>&1 &
sleep 2
if ps aux | grep -q "[s]uricata_correlacion"; then
    echo "  ✅ Script de correlación iniciado"
else
    echo "  ❌ Error al iniciar script"
fi

# 5. Verificar estado final
echo ""
echo "[5/5] Verificando estado final..."
echo ""
echo "--- Contenedores en red monitoring_monitoring ---"
docker network inspect monitoring_monitoring --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{"\n"}}{{end}}'
echo ""
echo "--- Servicios activos ---"
echo "  Loki:       $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3100/ready)"
echo "  Prometheus: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:9090/-/ready)"
echo "  Grafana:    $(curl -s -o /dev/null -w '%{http_code}' http://admin:password@localhost:3000/api/health)"
echo ""
echo "============================================"
echo "  Recuperación completada"
echo "============================================"
