#!/bin/bash
echo "Restaurando Grafana..."
# Restaurar fuentes de datos
curl -s -X POST "http://admin:password@localhost:3000/api/datasources" \
  -H "Content-Type: application/json" \
  -d @datasources.json
# Restaurar dashboards
for file in dashboard_*.json; do
  uid=$(echo $file | sed 's/dashboard_//;s/\.json//')
  curl -s -X POST "http://admin:password@localhost:3000/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -d "{\"dashboard\": $(cat $file), \"overwrite\": true}"
done
echo "Restauración completada"
