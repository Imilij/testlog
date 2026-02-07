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

# Git config через змінні середовища
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL

RUN git config --global user.name "${GIT_USER_NAME}" && \
    git config --global user.email "${GIT_USER_EMAIL}"

ENV OUTPUT_DIR=/app/output

VOLUME ["/app/logs"]

CMD ["/bin/sh", "-c", "tail -f /dev/null"]

