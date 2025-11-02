from sqlalchemy import create_engine, Column, Integer, String, Date, Enum, Text, ForeignKey
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

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

