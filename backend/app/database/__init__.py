import os
import logging
from sqlalchemy import create_engine, text
from sqlalchemy.orm import declarative_base, sessionmaker
from app.config import settings

logger = logging.getLogger("bsas.database")

DATABASE_URL = settings.DATABASE_URL
is_sqlite = "sqlite" in DATABASE_URL.lower()
is_postgres = "postgresql" in DATABASE_URL.lower() or "postgres" in DATABASE_URL.lower()

connect_args = {}
engine_kwargs = {}

if is_sqlite:
    connect_args["check_same_thread"] = False
elif is_postgres:
    engine_kwargs["pool_size"] = 10
    engine_kwargs["max_overflow"] = 20
    engine_kwargs["pool_pre_ping"] = True

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    **engine_kwargs
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def init_db():
    from app.models import user, zone, incident, alert, device, location, audit, sync
    if is_postgres:
        with engine.connect() as conn:
            conn.execute(text('SELECT PostGIS_Version()'))
            revision = conn.execute(text('SELECT version_num FROM alembic_version')).scalar()
            if revision != '002_safety_events':
                raise RuntimeError('Run alembic upgrade head before starting BSAS')
    else:
        if settings.ENVIRONMENT in ('production', 'prod'):
            raise RuntimeError('SQLite is restricted to development and isolated tests')
        Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
