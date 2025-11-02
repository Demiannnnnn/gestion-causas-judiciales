-- ============================================================
--   MODELO DE DATOS: GESTIÓN DE CAUSAS JUDICIALES
--   Base de datos: MySQL 8.0
--   Autor: (Camilo)
--   Fecha: 2025-11-01
-- ============================================================

CREATE DATABASE IF NOT EXISTS gestion_causas
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE gestion_causas;

-- ============================================================
--  TABLA: TRIBUNAL
-- ============================================================

CREATE TABLE Tribunal (
    id_tribunal INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    region VARCHAR(100),
    direccion VARCHAR(255),
    UNIQUE KEY (nombre)
) ENGINE=InnoDB;

-- Insertar tribunales de ejemplo
INSERT INTO `Tribunal` (`nombre`, `region`, `direccion`) VALUES
('1er Juzgado de Letras de Santiago', 'Metropolitana', 'Dirección Ficticia 123'),
('Juzgado de Familia de Puente Alto', 'Metropolitana', 'Dirección Ficticia 456'),
('Corte de Apelaciones de Valparaíso', 'Valparaíso', 'Dirección Ficticia 789');

-- ============================================================
--  TABLA: USUARIO
-- ============================================================

CREATE TABLE Usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('ADMINISTRADOR', 'ABOGADO', 'ASISTENTE', 'SISTEMAS') NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    creado_en DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
--  TABLA: CAUSA
-- ============================================================

CREATE TABLE Causa (
    id_causa INT AUTO_INCREMENT PRIMARY KEY,
    rit VARCHAR(50) NOT NULL UNIQUE,
    tribunal_id INT NOT NULL,
    fecha_inicio DATE,
    estado ENUM('ACTIVA', 'CONGELADA', 'ARCHIVADA') DEFAULT 'ACTIVA',
    descripcion TEXT,
    FOREIGN KEY (tribunal_id) REFERENCES Tribunal(id_tribunal)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    INDEX idx_estado_tribunal (estado, tribunal_id)
) ENGINE=InnoDB;

-- ============================================================
--  TABLA: PARTE
-- ============================================================

CREATE TABLE Parte (
    id_parte INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    tipo ENUM('DEMANDANTE', 'DEMANDADO', 'TERCERO', 'OTRO') NOT NULL,
    rut VARCHAR(15)
) ENGINE=InnoDB;

-- ============================================================
--  TABLA INTERMEDIA: CAUSAPARTE (N:N)
-- ============================================================

CREATE TABLE CausaParte (
    id_causa INT NOT NULL,
    id_parte INT NOT NULL,
    representado_por INT NULL,
    PRIMARY KEY (id_causa, id_parte),
    FOREIGN KEY (id_causa) REFERENCES Causa(id_causa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (id_parte) REFERENCES Parte(id_parte)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (representado_por) REFERENCES Usuario(id_usuario)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
--  TABLA: DOCUMENTO
-- ============================================================

CREATE TABLE Documento (
    id_documento INT AUTO_INCREMENT PRIMARY KEY,
    id_causa INT NOT NULL,
    tipo ENUM('RESOLUCIÓN', 'OFICIO', 'PRUEBA', 'OTRO') NOT NULL,
    nombre_archivo VARCHAR(255) NOT NULL,
    ruta_storage VARCHAR(255) NOT NULL,
    fecha_subida DATETIME DEFAULT CURRENT_TIMESTAMP,
    subido_por INT,
    FOREIGN KEY (id_causa) REFERENCES Causa(id_causa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (subido_por) REFERENCES Usuario(id_usuario)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    INDEX idx_documento_causa (id_causa)
) ENGINE=InnoDB;

-- ============================================================
--  TABLA: MOVIMIENTO
-- ============================================================

CREATE TABLE Movimiento (
    id_movimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_causa INT NOT NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descripcion TEXT,
    tipo ENUM('AUDIENCIA', 'RESOLUCIÓN', 'SUSPENSIÓN', 'VENCIMIENTO', 'OTRO') NOT NULL,
    FOREIGN KEY (id_causa) REFERENCES Causa(id_causa)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    INDEX idx_movimiento_fecha (fecha)
) ENGINE=InnoDB;

-- ============================================================
--  TABLA: NOTIFICACION
-- ============================================================

CREATE TABLE Notificacion (
    id_notificacion INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    tipo ENUM('ALERTA', 'VENCIMIENTO', 'MOVIMIENTO', 'REPORTE') NOT NULL,
    mensaje TEXT NOT NULL,
    fecha_envio DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('PENDIENTE', 'ENVIADA', 'LEÍDA') DEFAULT 'PENDIENTE',
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    INDEX idx_notif_estado (estado)
) ENGINE=InnoDB;

-- ============================================================
--  TABLA: LOGACCION
-- ============================================================

CREATE TABLE LogAccion (
    id_log BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    entidad VARCHAR(100),
    accion ENUM('INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'UPLOAD', 'REPORTE'),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    detalle TEXT,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    INDEX idx_log_fecha (fecha),
    INDEX idx_log_usuario (id_usuario)
) ENGINE=InnoDB;

-- ============================================================
--  INDICES ADICIONALES Y OPTIMIZACIÓN
-- ============================================================

CREATE FULLTEXT INDEX ft_causa_descripcion ON Causa(descripcion);
CREATE FULLTEXT INDEX ft_parte_nombre ON Parte(nombre);

-- ============================================================
--  COMENTARIOS FINALES
-- ============================================================
-- Este modelo cubre todos los requisitos funcionales:
-- RF1: Gestión de causas (Causa, Tribunal, Parte, CausaParte)
-- RF2: Consultas avanzadas mediante índices y fulltext
-- RF3: Notificaciones y vencimientos (Movimiento, Notificacion)
-- RF4: Documentos asociados (Documento)
-- RF5: Usuarios y roles (Usuario)
-- RF6: Reportes (consultas agregadas)
-- RF7: Agente IA usando LogAccion para auditoría
-- Redis puede usarse como caché de consultas y canal de notificaciones
-- ============================================================


-- ============================================================
--  USUARIO: admin_app
--  Rol: Administrador general del sistema
--  Permisos: Total sobre la base gestion_causas
-- ============================================================

CREATE USER 'admin_app'@'%' IDENTIFIED BY 'AdminApp#2025!';
GRANT ALL PRIVILEGES ON gestion_causas.* TO 'admin_app'@'%'
    WITH GRANT OPTION;

-- ============================================================
--  USUARIO: abogado_app
--  Rol: Abogado
--  Permisos: Lectura total y escritura parcial (solo sus causas y documentos)
--             Sin privilegios de administración.
-- ============================================================

CREATE USER 'abogado_app'@'%' IDENTIFIED BY 'Abogado#2025!';
GRANT SELECT, INSERT, UPDATE ON gestion_causas.Causa TO 'abogado_app'@'%';
GRANT SELECT, INSERT, UPDATE ON gestion_causas.Parte TO 'abogado_app'@'%';
GRANT SELECT, INSERT, UPDATE ON gestion_causas.CausaParte TO 'abogado_app'@'%';
GRANT SELECT, INSERT, UPDATE ON gestion_causas.Documento TO 'abogado_app'@'%';
GRANT SELECT, INSERT ON gestion_causas.Movimiento TO 'abogado_app'@'%';
GRANT SELECT ON gestion_causas.Tribunal TO 'abogado_app'@'%';
GRANT SELECT ON gestion_causas.Usuario TO 'abogado_app'@'%';
GRANT SELECT, INSERT ON gestion_causas.Notificacion TO 'abogado_app'@'%';
GRANT SELECT, INSERT ON gestion_causas.LogAccion TO 'abogado_app'@'%';

-- ============================================================
--  USUARIO: asistente_app
--  Rol: Asistente o paralegal
--  Permisos: Lectura y registro de movimientos/documentos
--             Sin acceso a administración ni configuración.
-- ============================================================

CREATE USER 'asistente_app'@'%' IDENTIFIED BY 'Asistente#2025!';
GRANT SELECT ON gestion_causas.Causa TO 'asistente_app'@'%';
GRANT SELECT ON gestion_causas.Tribunal TO 'asistente_app'@'%';
GRANT SELECT ON gestion_causas.Parte TO 'asistente_app'@'%';
GRANT INSERT, SELECT ON gestion_causas.Movimiento TO 'asistente_app'@'%';
GRANT INSERT, SELECT ON gestion_causas.Documento TO 'asistente_app'@'%';
GRANT INSERT, SELECT ON gestion_causas.Notificacion TO 'asistente_app'@'%';
GRANT INSERT ON gestion_causas.LogAccion TO 'asistente_app'@'%';

-- ============================================================
--  USUARIO: sistemas_app
--  Rol: Administrador técnico / Agente IA
--  Permisos: Lectura completa y escritura limitada en logs
--             Sin privilegios para modificar datos legales.
-- ============================================================

CREATE USER 'sistemas_app'@'localhost' IDENTIFIED BY 'Sistemas#2025!';
GRANT SELECT ON gestion_causas.* TO 'sistemas_app'@'localhost';
GRANT INSERT, UPDATE ON gestion_causas.LogAccion TO 'sistemas_app'@'localhost';

-- ============================================================
--  USUARIO: readonly_app
--  Rol: Consulta o auditor externo
--  Permisos: Solo lectura global
-- ============================================================

CREATE USER 'readonly_app'@'%' IDENTIFIED BY 'ReadOnly#2025!';
GRANT SELECT ON gestion_causas.* TO 'readonly_app'@'%';

-- ============================================================
--  APLICAR CAMBIOS
-- ============================================================

FLUSH PRIVILEGES;

-- ============================================================
--  USUARIO DE PRUEBA INICIAL
-- Contraseña: Admin123!
-- ============================================================
INSERT INTO `Usuario` (`nombre`, `correo`, `password_hash`, `rol`, `activo`) VALUES
('Admin Principal', 'admin@judicial.cl', '$2b$12$PEm.9URVdnDqQELR7Zh0x.kH.vaK96CSW6KvfddCE3pNQYcIJasHW', 'ADMINISTRADOR', 1);

