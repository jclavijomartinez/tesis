FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sed \
    dnsmasq \
    iproute2 \
    iputils-ping \
    iptables \
    tcpdump \
    ufw \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Copiar configuración de dnsmasq
COPY dnsmasq/dnsmasq.conf /etc/dnsmasq.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Exponer DHCP y DNS
EXPOSE 67/udp 53/udp

# Usamos el entrypoint para levantar todo
CMD ["/entrypoint.sh"]

