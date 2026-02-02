FROM alpine:3.20
RUN apk add --no-cache iputils bash netcat-openbsd
WORKDIR /app
COPY ping-exporter.sh .
RUN chmod +x ping-exporter.sh
CMD ["./ping-exporter.sh"]
