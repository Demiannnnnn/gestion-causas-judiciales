FROM proxysql/proxysql:2.6.5

# Install Python3 and pip
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y python3 python3-pip && \
    pip3 install PyMySQL

# Copy the config generation script, template, and .env file
COPY ./scripts/fix_proxysql_config.py /usr/local/bin/fix_proxysql_config.py
COPY ./db/proxy/proxysql.cnf.template /usr/local/bin/proxysql.cnf.template
COPY ./.env /usr/local/bin/.env # Copiar el archivo .env principal

# Script de inicio que elimina la base de datos interna para forzar lectura del config
RUN echo '#!/bin/sh' > /start-proxysql.sh && \
    echo 'mkdir -p /var/lib/proxysql' >> /start-proxysql.sh && \
    echo 'chown -R proxysql:proxysql /var/lib/proxysql' >> /start-proxysql.sh && \
    echo 'rm -f /var/lib/proxysql/proxysql.db' >> /start-proxysql.sh && \
    echo '' >> /start-proxysql.sh && \
    echo '# Generate ProxySQL config using Python script' >> /start-proxysql.sh && \
    echo 'python3 /usr/local/bin/fix_proxysql_config.py' >> /start-proxysql.sh && \
    echo '' >> /start-proxysql.sh && \
    echo 'proxysql --config /etc/proxysql/proxysql.cnf --initial --foreground &' >> /start-proxysql.sh && \
    echo 'PROXYSQL_PID=$!' >> /start-proxysql.sh && \
    echo 'sleep 8' >> /start-proxysql.sh && \
    echo 'mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "UPDATE global_variables SET variable_value=\"86400000\" WHERE variable_name=\"mysql-monitor_replication_lag_interval\"; LOAD MYSQL VARIABLES TO RUNTIME; SAVE MYSQL VARIABLES TO DISK;" 2>&1 || true' >> /start-proxysql.sh && \
    echo 'wait $PROXYSQL_PID' >> /start-proxysql.sh && \
    chmod +x /start-proxysql.sh

CMD ["/start-proxysql.sh"]
