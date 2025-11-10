#!/bin/bash
set -e

# Este script se ejecuta cuando el esclavo se inicializa por primera vez.
# Configura la replicación de forma automática y segura.

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    CHANGE REPLICATION SOURCE TO
        SOURCE_HOST='db-master',
        SOURCE_USER='replicator',
        SOURCE_PASSWORD='${MYSQL_REPLICATION_PASSWORD}',
        SOURCE_SSL=1,
        SOURCE_AUTO_POSITION=1;
    START REPLICA;
EOSQL
