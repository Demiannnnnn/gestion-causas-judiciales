import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager

class DatabaseManager:
    def __init__(self):
        db_url = os.getenv('DATABASE_URL', 'mysql+pymysql://user:pass@localhost/db')
        self.engine = create_engine(
            db_url,
            pool_pre_ping=True,  # Verifica la conexión antes de usarla
            pool_recycle=3600,   # Recicla conexiones cada hora
            pool_size=10,        # Tamaño del pool
            max_overflow=20,     # Conexiones extra permitidas
            connect_args={
                'connect_timeout': 10,
                'read_timeout': 30,
                'write_timeout': 30
            }
        )
        self.SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine)

    @contextmanager
    def get_session(self):
        """Provide a transactional scope around a series of operations."""
        session = self.SessionLocal()
        try:
            yield session
            session.commit()
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()

db_manager = DatabaseManager()
