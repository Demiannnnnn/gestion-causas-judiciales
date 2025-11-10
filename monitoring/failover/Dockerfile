FROM alpine:latest

# Instalar dependencias
RUN apk add --no-cache bash mysql-client curl docker-cli

# Copiar scripts
COPY scripts/auto-failover-daemon.sh /scripts/auto-failover-daemon.sh
COPY scripts/auto-failback-daemon.sh /scripts/auto-failback-daemon.sh
COPY scripts/failover-promote-slave.sh /scripts/failover-promote-slave.sh
COPY scripts/failback-restore-master.sh /scripts/failback-restore-master.sh

RUN chmod +x /scripts/*.sh

# El script a ejecutar se especifica en docker-compose.yml
CMD ["/bin/bash"]
