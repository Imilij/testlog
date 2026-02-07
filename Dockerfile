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

RUN git config --global user.name "Script" && \
    git config --global user.email "ivanpavlyk76@gmail.com"

ENV OUTPUT_DIR=/app/output

VOLUME ["/app/logs"]

CMD ["/bin/sh", "-c", "tail -f /dev/null"]
