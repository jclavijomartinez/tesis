#!/bin/sh

PORT=8000
TARGETS="1.1.1.1 8.8.8.8"
METRICS_FILE=/tmp/metrics.txt

# Iniciar archivo vacío
echo "# HELP ping_latency_ms Ping latency in ms" > $METRICS_FILE
echo "# TYPE ping_latency_ms gauge" >> $METRICS_FILE

# Hilo que hace ping cada 2 segundos
(
  while true; do
    TMP_FILE=$(mktemp)
    echo "# HELP ping_latency_ms Ping latency in ms" > $TMP_FILE
    echo "# TYPE ping_latency_ms gauge" >> $TMP_FILE
    for target in $TARGETS; do
      LATENCY=$(ping -c 1 -W 1 $target 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
      if [ -n "$LATENCY" ]; then
        echo "ping_latency_ms{target=\"$target\"} $LATENCY" >> $TMP_FILE
      else
        echo "ping_latency_ms{target=\"$target\"} -1" >> $TMP_FILE
      fi
    done
    mv $TMP_FILE $METRICS_FILE
    sleep 2
  done
) &

# Servidor HTTP muy simple en loop con netcat
while true; do
  {
    echo "HTTP/1.1 200 OK"
    echo "Content-Type: text/plain"
    echo
    cat $METRICS_FILE
  } | nc -l -p $PORT -q 1
done

