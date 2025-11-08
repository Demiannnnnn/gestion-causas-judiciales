from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    String,
    Date,
    Enum,
    Text,
    ForeignKey,
    Boolean,
    DateTime,
    BIGINT,
)
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func

Base = declarative_base()

# --- Modelos Principales ---

class Tribunal(Base):
    __tablename__ = 'Tribunal'
    id_tribunal = Column(Integer, primary_key=True)
    nombre = Column(String(150), nullable=False, unique=True)
    region = Column(String(100))
    direccion = Column(String(255))
    causas = relationship("Causa", back_populates="tribunal")

class Causa(Base):
    __tablename__ = 'Causa'
    id_causa = Column(Integer, primary_key=True)
    rit = Column(String(50), nullable=False, unique=True)
    tribunal_id = Column(Integer, ForeignKey('Tribunal.id_tribunal'), nullable=False)
    fecha_inicio = Column(Date)
    estado = Column(Enum('ACTIVA', 'CONGELADA', 'ARCHIVADA', name='estado_causa'), default='ACTIVA')
    descripcion = Column(Text)
    
    tribunal = relationship("Tribunal", back_populates="causas")
    documentos = relationship("Documento", back_populates="causa")
    movimientos = relationship("Movimiento", back_populates="causa")
    partes = relationship('CausaParte', back_populates='causa')

    def to_json(self):
        return {
            "id_causa": self.id_causa,
            "rit": self.rit,
            "tribunal_id": self.tribunal_id,
            "fecha_inicio": self.fecha_inicio.isoformat() if self.fecha_inicio else None,
            "estado": self.estado,
            "descripcion": self.descripcion
        }

class Usuario(Base):
    __tablename__ = 'Usuario'
    id_usuario = Column(Integer, primary_key=True)
    nombre = Column(String(150), nullable=False)
    correo = Column(String(100), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)
    rol = Column(Enum('ADMINISTRADOR', 'ABOGADO', 'ASISTENTE', 'SISTEMAS', name='rol_usuario'), nullable=False)
    activo = Column(Boolean, default=True)
    creado_en = Column(DateTime, server_default=func.now())
    
    documentos_subidos = relationship("Documento", back_populates="subido_por_usuario")
    notificaciones = relationship("Notificacion", back_populates="usuario")
    logs = relationship("LogAccion", back_populates="usuario")
    causas_representadas = relationship('CausaParte', back_populates='representante')

class Parte(Base):
    __tablename__ = 'Parte'
    id_parte = Column(Integer, primary_key=True)
    nombre = Column(String(150), nullable=False)
    tipo = Column(Enum('DEMANDANTE', 'DEMANDADO', 'TERCERO', 'OTRO', name='tipo_parte'), nullable=False)
    rut = Column(String(15))
    causas = relationship('CausaParte', back_populates='parte')

# --- Modelos de Relación y Transaccionales ---

class CausaParte(Base):
    __tablename__ = 'CausaParte'
    id_causa = Column(Integer, ForeignKey('Causa.id_causa'), primary_key=True)
    id_parte = Column(Integer, ForeignKey('Parte.id_parte'), primary_key=True)
    representado_por = Column(Integer, ForeignKey('Usuario.id_usuario'), nullable=True)

    causa = relationship('Causa', back_populates='partes')
    parte = relationship('Parte', back_populates='causas')
    representante = relationship('Usuario', back_populates='causas_representadas')

class Documento(Base):
    __tablename__ = 'Documento'
    id_documento = Column(Integer, primary_key=True)
    id_causa = Column(Integer, ForeignKey('Causa.id_causa'), nullable=False)
    tipo = Column(Enum('RESOLUCIÓN', 'OFICIO', 'PRUEBA', 'OTRO', name='tipo_documento'), nullable=False)
    nombre_archivo = Column(String(255), nullable=False)
    ruta_storage = Column(String(255), nullable=False)
    fecha_subida = Column(DateTime, server_default=func.now())
    subido_por = Column(Integer, ForeignKey('Usuario.id_usuario'), nullable=True)

    causa = relationship("Causa", back_populates="documentos")
    subido_por_usuario = relationship("Usuario", back_populates="documentos_subidos")

    def to_json(self):
        return {
            'id_documento': self.id_documento,
            'id_causa': self.id_causa,
            'tipo': self.tipo,
            'nombre_archivo': self.nombre_archivo,
            'fecha_subida': self.fecha_subida.isoformat() if self.fecha_subida else None,
            'subido_por': self.subido_por
        }

class Movimiento(Base):
    __tablename__ = 'Movimiento'
    id_movimiento = Column(Integer, primary_key=True)
    id_causa = Column(Integer, ForeignKey('Causa.id_causa'), nullable=False)
    fecha = Column(DateTime, nullable=False, server_default=func.now())
    descripcion = Column(Text)
    tipo = Column(Enum('AUDIENCIA', 'RESOLUCIÓN', 'SUSPENSIÓN', 'VENCIMIENTO', 'OTRO', name='tipo_movimiento'), nullable=False)
    
    causa = relationship("Causa", back_populates="movimientos")

class Notificacion(Base):
    __tablename__ = 'Notificacion'
    id_notificacion = Column(Integer, primary_key=True)
    id_usuario = Column(Integer, ForeignKey('Usuario.id_usuario'), nullable=True)
    tipo = Column(Enum('ALERTA', 'VENCIMIENTO', 'MOVIMIENTO', 'REPORTE', name='tipo_notificacion'), nullable=False)
    destinatario = Column(String(100), nullable=False)
    asunto = Column(String(255), nullable=False)
    mensaje = Column(Text, nullable=False)
    caso_rit = Column(String(50), nullable=True)
    fecha_envio = Column(DateTime, server_default=func.now())
    estado = Column(Enum('PENDIENTE', 'ENVIADA', 'LEÍDA', 'ERROR', name='estado_notificacion'), default='PENDIENTE')
    leido = Column(Boolean, default=False)
    
    usuario = relationship("Usuario", back_populates="notificaciones")

    def to_json(self):
        return {
            "id": self.id_notificacion,
            "id_usuario": self.id_usuario,
            "tipo": self.tipo,
            "destinatario": self.destinatario,
            "asunto": self.asunto,
            "mensaje": self.mensaje,
            "caso_rit": self.caso_rit,
            "fecha_envio": self.fecha_envio.isoformat() if self.fecha_envio else None,
            "estado": self.estado,
            "leido": self.leido,
        }

class LogAccion(Base):
    __tablename__ = 'LogAccion'
    id_log = Column(BIGINT, primary_key=True)
    id_usuario = Column(Integer, ForeignKey('Usuario.id_usuario'), nullable=True)
    entidad = Column(String(100))
    accion = Column(Enum('INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'UPLOAD', 'REPORTE', name='accion_log'))
    fecha = Column(DateTime, server_default=func.now())
    detalle = Column(Text)
    
    usuario = relationship("Usuario", back_populates="logs")
