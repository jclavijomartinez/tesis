FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    iproute2 \
    iputils-ping \
    iptables \
    tcpdump \
    vim \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint-router.sh /entrypoint-router.sh
RUN chmod +x /entrypoint-router.sh

CMD ["/entrypoint-router.sh"]
