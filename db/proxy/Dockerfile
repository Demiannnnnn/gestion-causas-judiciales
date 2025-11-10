FROM proxysql/proxysql:2.6.5

# El archivo de configuración será montado desde el volumen generado por config-init-proxysql
# Script de inicio que elimina la base de datos interna para forzar lectura del config
RUN echo '#!/bin/sh' > /start-proxysql.sh && \
    echo 'rm -f /var/lib/proxysql/proxysql.db' >> /start-proxysql.sh && \
    echo 'proxysql --config /etc/proxysql/proxysql.cnf --initial --foreground &' >> /start-proxysql.sh && \
    echo 'PROXYSQL_PID=$!' >> /start-proxysql.sh && \
    echo 'sleep 8' >> /start-proxysql.sh && \
    echo 'mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "UPDATE global_variables SET variable_value=\"86400000\" WHERE variable_name=\"mysql-monitor_replication_lag_interval\"; LOAD MYSQL VARIABLES TO RUNTIME; SAVE MYSQL VARIABLES TO DISK;" 2>&1 || true' >> /start-proxysql.sh && \
    echo 'wait $PROXYSQL_PID' >> /start-proxysql.sh && \
    chmod +x /start-proxysql.sh

CMD ["/start-proxysql.sh"]
