FROM openarkcode/orchestrator:v3.2.4

# Cambiar a root para instalar paquetes
USER root

# Instalar cliente MySQL, bash, curl y gettext (para envsubst)
RUN apk add --no-cache mysql-client bash curl gettext

# Copiar script de entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Ejecutar script de inicio
ENTRYPOINT ["/entrypoint.sh"]
