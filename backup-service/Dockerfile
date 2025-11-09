FROM alpine:3.19

# Instalar dependencias
RUN apk add --no-cache \
    bash \
    mysql-client \
    tar \
    gzip \
    dcron \
    rsync

# Crear directorio de trabajo
WORKDIR /app

# Copiar scripts de backup
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Crear directorio de backups
RUN mkdir -p /backups

# Copiar el crontab
COPY crontab /etc/crontabs/root

# Script de inicio
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
