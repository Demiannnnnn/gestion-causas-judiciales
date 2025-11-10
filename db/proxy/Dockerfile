FROM proxysql/proxysql:2.6.5

# Instalar utilidades necesarias
RUN apt-get update && apt-get install -y gettext-base && rm -rf /var/lib/apt/lists/*

# Copiar el template y el script de inicialización
COPY proxysql.cnf.template /etc/proxysql/proxysql.cnf.template
COPY init-config.sh /init-config.sh
RUN chmod +x /init-config.sh

CMD ["/init-config.sh"]
