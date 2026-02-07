FROM alpine:3.19

RUN apk add --no-cache \
    bash \
    git \
    gawk \
    sed \
    coreutils \
    grep

WORKDIR /app

COPY script.sh /app/script.sh
RUN chmod +x /app/script.sh

# Налаштування Git
RUN git config --global user.name "Log Analyzer" && \
    git config --global user.email "analyzer@server.local"

ENV OUTPUT_DIR=/app/output

VOLUME ["/app/logs"]

CMD ["/bin/sh", "-c", "tail -f /dev/null"]
