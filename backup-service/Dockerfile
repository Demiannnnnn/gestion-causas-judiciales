FROM alpine:3.19

# Instalar dependencias
RUN apk add --no-cache \
    bash \
    mysql-client \
    tar \
    gzip \
    dcron \
    rsync \
    dos2unix  # Add dos2unix

# Crear directorio de trabajo
WORKDIR /app

# Copiar scripts de backup
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh
RUN dos2unix /app/scripts/*.sh # Convert line endings for all scripts

# Crear directorio de backups
RUN mkdir -p /backups

# Script de inicio
COPY entrypoint.sh /entrypoint.sh
RUN dos2unix /entrypoint.sh # Convert line endings for entrypoint.sh

# Change permissions before switching user
RUN chmod +x /entrypoint.sh

# Crear usuario no privilegiado
RUN adduser -D -u 1000 appuser
USER appuser

ENTRYPOINT ["/entrypoint.sh"]