-- ============================================================
--  USUARIOS Y PERMISOS
-- ============================================================

-- Administrador
CREATE USER IF NOT EXISTS 'admin_app'@'%' IDENTIFIED BY 'AdminApp#2025!';
GRANT ALL PRIVILEGES ON *.* TO 'admin_app'@'%' WITH GRANT OPTION;

-- Abogado
CREATE USER IF NOT EXISTS 'abogado_app'@'%' IDENTIFIED BY 'Abogado#2025!';
GRANT SELECT, INSERT, UPDATE ON gestion_causas.* TO 'abogado_app'@'%';
GRANT SELECT, INSERT ON gestion_causas.Movimiento TO 'abogado_app'@'%';
GRANT SELECT ON gestion_causas.Tribunal TO 'abogado_app'@'%';
GRANT SELECT ON gestion_causas.Usuario TO 'abogado_app'@'%';
GRANT SELECT, INSERT ON gestion_causas.LogAccion TO 'abogado_app'@'%';

-- Asistente
CREATE USER IF NOT EXISTS 'asistente_app'@'%' IDENTIFIED BY 'Asistente#2025!';
GRANT SELECT ON gestion_causas.* TO 'asistente_app'@'%';
GRANT INSERT ON gestion_causas.Movimiento TO 'asistente_app'@'%';
GRANT INSERT ON gestion_causas.Documento TO 'asistente_app'@'%';
GRANT INSERT ON gestion_causas.Notificacion TO 'asistente_app'@'%';
GRANT INSERT ON gestion_causas.LogAccion TO 'asistente_app'@'%';

-- Sistemas
CREATE USER IF NOT EXISTS 'sistemas_app'@'%' IDENTIFIED BY 'Sistemas#2025!';
GRANT SELECT ON gestion_causas.* TO 'sistemas_app'@'%';
GRANT INSERT, UPDATE ON gestion_causas.LogAccion TO 'sistemas_app'@'%';

-- Readonly
CREATE USER IF NOT EXISTS 'readonly_app'@'%' IDENTIFIED BY 'ReadOnly#2025!';
GRANT SELECT ON gestion_causas.* TO 'readonly_app'@'%';

-- Replicación
CREATE USER IF NOT EXISTS 'replicator'@'%' IDENTIFIED BY 'repl_password' REQUIRE SSL;
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator'@'%';

-- Monitor
CREATE USER IF NOT EXISTS 'monitor_user'@'%' IDENTIFIED BY '***REMOVED***';
GRANT REPLICATION CLIENT ON *.* TO 'monitor_user'@'%';
GRANT SELECT ON gestion_causas.* TO 'monitor_user'@'%';

-- App User
CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON gestion_causas.* TO 'appuser'@'%';

FLUSH PRIVILEGES;