FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    snort tcpdump iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Configuración y reglas
COPY snort.conf /etc/snort/snort.conf
COPY rules/ /etc/snort/rules/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && mkdir -p /var/log/snort

ENTRYPOINT ["/entrypoint.sh"]
