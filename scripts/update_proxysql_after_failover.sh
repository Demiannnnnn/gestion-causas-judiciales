#!/bin/bash
# ============================================================
# ORCHESTRATOR HOOK: UPDATE PROXYSQL AFTER FAILOVER
# ============================================================
# This script is called by Orchestrator after a master failover.
# Arguments:
# $1: Failed Master Host
# $2: New Master Host

FAILED_MASTER=$1
NEW_MASTER=$2
PROXYSQL_HOST="db-proxy"
PROXYSQL_PORT="6032"
PROXYSQL_USER="admin"
PROXYSQL_PASS="admin"

echo "============================================================"
echo "Updating ProxySQL after failover: $FAILED_MASTER -> $NEW_MASTER"
echo "============================================================"

if [ -z "$FAILED_MASTER" ] || [ -z "$NEW_MASTER" ]; then
  echo "ERROR: Missing arguments. Usage: $0 <failed_master> <new_master>"
  exit 1
fi

# Command to execute inside ProxySQL
SQL_COMMANDS="
-- Move old master to OFFLINE_SOFT (or delete it to be safe)
UPDATE mysql_servers SET status='OFFLINE_SOFT' WHERE hostname='$FAILED_MASTER';

-- Ensure new master is in Writer Hostgroup (10) and Reader Hostgroup (20)
-- First, remove it from readers if it was there strictly as a reader
DELETE FROM mysql_servers WHERE hostname='$NEW_MASTER' AND hostgroup_id=20;

-- Insert/Update new master as WRITER (HG 10)
REPLACE INTO mysql_servers (hostgroup_id, hostname, port, max_connections, max_replication_lag, weight, status)
VALUES (10, '$NEW_MASTER', 3306, 1000, 5, 100, 'ONLINE');

-- Insert/Update new master as READER (HG 20) - optional, for read-after-write consistency
REPLACE INTO mysql_servers (hostgroup_id, hostname, port, max_connections, max_replication_lag, weight, status)
VALUES (20, '$NEW_MASTER', 3306, 1000, 5, 100, 'ONLINE');

-- Load changes to runtime
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
"

# Execute via mysql client container (or orchestrator if it has mysql client installed)
# Since we are running this from the Orchestrator container, we need mysql-client installed there.
# If not, we can use a small docker hack if docker socket is mounted, OR just rely on mysql client.
# Assuming mysql client is available in the orchestrator image or we installed it.
# The official orchestrator image is based on Alpine/Debian usually.

# Let's try to connect directly using mysql client
mysql -h "$PROXYSQL_HOST" -P "$PROXYSQL_PORT" -u"$PROXYSQL_USER" -p"$PROXYSQL_PASS" -e "$SQL_COMMANDS"

if [ $? -eq 0 ]; then
  echo "SUCCESS: ProxySQL updated successfully."
else
  echo "ERROR: Failed to update ProxySQL."
  exit 1
fi
