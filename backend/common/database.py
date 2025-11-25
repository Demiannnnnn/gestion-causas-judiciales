import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager
import logging

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DatabaseManager:
    def __init__(self):
        self.engines = {}
        self.SessionLocals = {}

        # Roles definidos en tu sistema
        roles = ['ABOGADO', 'ASISTENTE', 'ADMINISTRADOR', 'SISTEMAS']

        # URL de la base de datos por defecto (para autenticación y otros usos)
        default_db_url = os.getenv('DATABASE_URL')
        if not default_db_url:
            raise ValueError("DATABASE_URL no está configurada.")
        
        logger.info("Configurando la conexión por defecto.")
        self.engines['default'] = self._create_engine(default_db_url)
        self.SessionLocals['default'] = sessionmaker(autocommit=False, autoflush=False, bind=self.engines['default'])

        # Configurar un motor de base de datos para cada rol
        for role in roles:
            role_db_url = os.getenv(f'DATABASE_URL_{role}')
            if role_db_url:
                logger.info(f"Configurando la conexión para el rol: {role}")
                self.engines[role] = self._create_engine(role_db_url)
                self.SessionLocals[role] = sessionmaker(autocommit=False, autoflush=False, bind=self.engines[role])
            else:
                logger.warning(f"La URL de la base de datos para el rol {role} no está configurada. Usará la conexión por defecto.")

    def _create_engine(self, db_url):
        """Crea una instancia de engine de SQLAlchemy con configuraciones optimizadas."""
        return create_engine(
            db_url,
            pool_pre_ping=True,
            pool_recycle=3600,
            pool_size=10,
            max_overflow=20,
            connect_args={
                'connect_timeout': 10,
                'read_timeout': 30,
                'write_timeout': 30
            }
        )

    @contextmanager
    def get_session(self, role=None):
        """
        Proporciona un scope transaccional para operaciones de base de datos.
        Selecciona la sesión basada en el rol del usuario.
        """
        session_local = self.SessionLocals.get(role, self.SessionLocals['default'])
        
        if role and role not in self.SessionLocals:
            logger.warning(f"No se encontró una configuración de sesión para el rol '{role}'. Usando la conexión por defecto.")
        
        session = session_local()
        logger.info(f"Sesión creada para el rol: {'default' if role not in self.SessionLocals else role}")
        
        try:
            yield session
            session.commit()
        except Exception as e:
            session.rollback()
            logger.error(f"Error en la sesión de base de datos: {e}", exc_info=True)
            raise
        finally:
            session.close()
            logger.info(f"Sesión cerrada para el rol: {'default' if role not in self.SessionLocals else role}")

db_manager = DatabaseManager()
