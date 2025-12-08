FROM alpine:3.19

# Instalar dependencias
RUN apk add --no-cache \
    bash \
    mysql-client \
    tar \
    gzip \
    dcron \
    rsync \
    dos2unix

# Crear directorio de trabajo
WORKDIR /app

# Crear usuario no privilegiado *before* using it in chown
RUN adduser -D -u 1000 appuser

# Copiar scripts de backup
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh
RUN dos2unix /app/scripts/*.sh

# Crear directorio de backups
RUN mkdir -p /backups
RUN mkdir -p /app/logs
RUN chown -R appuser:appuser /app/logs

# Script de inicio
COPY entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh

# Change permissions before switching user
RUN chmod +x /entrypoint.sh

USER appuser

ENTRYPOINT ["/entrypoint.sh"]
