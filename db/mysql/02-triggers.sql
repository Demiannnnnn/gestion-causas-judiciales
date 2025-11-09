-- ============================================================
--  TRIGGERS PARA AUDITORÍA EN LOGACCION
-- ============================================================

DELIMITER $$

-- Triggers para la tabla Causa
CREATE TRIGGER trg_causa_after_insert
AFTER INSERT ON Causa
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, detalle)
    VALUES ('Causa', 'INSERT', JSON_OBJECT('id', NEW.id_causa, 'rit', NEW.rit));
END$$

CREATE TRIGGER trg_causa_after_update
AFTER UPDATE ON Causa
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, detalle)
    VALUES ('Causa', 'UPDATE', JSON_OBJECT('id', NEW.id_causa, 'cambios', JSON_OBJECT('estado_anterior', OLD.estado, 'estado_nuevo', NEW.estado)));
END$$

CREATE TRIGGER trg_causa_after_delete
AFTER DELETE ON Causa
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, detalle)
    VALUES ('Causa', 'DELETE', JSON_OBJECT('id', OLD.id_causa, 'rit', OLD.rit));
END$$

-- Triggers para la tabla Documento
CREATE TRIGGER trg_documento_after_insert
AFTER INSERT ON Documento
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, id_usuario, detalle)
    VALUES ('Documento', 'INSERT', NEW.subido_por, JSON_OBJECT('id', NEW.id_documento, 'nombre', NEW.nombre_archivo, 'id_causa', NEW.id_causa));
END$$

CREATE TRIGGER trg_documento_after_delete
AFTER DELETE ON Documento
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, id_usuario, detalle)
    VALUES ('Documento', 'DELETE', OLD.subido_por, JSON_OBJECT('id', OLD.id_documento, 'nombre', OLD.nombre_archivo, 'id_causa', OLD.id_causa));
END$$

-- Triggers para la tabla Parte
CREATE TRIGGER trg_parte_after_insert
AFTER INSERT ON Parte
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, detalle)
    VALUES ('Parte', 'INSERT', JSON_OBJECT('id', NEW.id_parte, 'nombre', NEW.nombre, 'tipo', NEW.tipo));
END$$

CREATE TRIGGER trg_parte_after_update
AFTER UPDATE ON Parte
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, detalle)
    VALUES ('Parte', 'UPDATE', JSON_OBJECT('id', NEW.id_parte, 'nombre', NEW.nombre));
END$$

CREATE TRIGGER trg_parte_after_delete
AFTER DELETE ON Parte
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, detalle)
    VALUES ('Parte', 'DELETE', JSON_OBJECT('id', OLD.id_parte, 'nombre', OLD.nombre));
END$$

-- Triggers para la tabla CausaParte
CREATE TRIGGER trg_causaparte_after_insert
AFTER INSERT ON CausaParte
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, detalle)
    VALUES ('CausaParte', 'INSERT', JSON_OBJECT('id_causa', NEW.id_causa, 'id_parte', NEW.id_parte));
END$$

CREATE TRIGGER trg_causaparte_after_delete
AFTER DELETE ON CausaParte
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, detalle)
    VALUES ('CausaParte', 'DELETE', JSON_OBJECT('id_causa', OLD.id_causa, 'id_parte', OLD.id_parte));
END$$

-- Triggers para la tabla Movimiento
CREATE TRIGGER trg_movimiento_after_insert
AFTER INSERT ON Movimiento
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, detalle)
    VALUES ('Movimiento', 'INSERT', JSON_OBJECT('id', NEW.id_movimiento, 'tipo', NEW.tipo, 'id_causa', NEW.id_causa));
END$$

-- Triggers para la tabla Notificacion
CREATE TRIGGER trg_notificacion_after_insert
AFTER INSERT ON Notificacion
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, id_usuario, detalle)
    VALUES ('Notificacion', 'INSERT', NEW.id_usuario, JSON_OBJECT('id', NEW.id_notificacion, 'tipo', NEW.tipo, 'estado', NEW.estado));
END$$

CREATE TRIGGER trg_notificacion_after_update
AFTER UPDATE ON Notificacion
FOR EACH ROW
BEGIN
    INSERT INTO LogAccion (entidad, accion, id_usuario, detalle)
    VALUES ('Notificacion', 'UPDATE', NEW.id_usuario, JSON_OBJECT('id', NEW.id_notificacion, 'estado_anterior', OLD.estado, 'estado_nuevo', NEW.estado));
END$$

DELIMITER ;
