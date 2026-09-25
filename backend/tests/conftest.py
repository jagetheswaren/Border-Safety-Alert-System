"""Tests use an isolated SQLite file unless an explicit integration URL is supplied."""
import os
import sys
import tempfile
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
_temporary = tempfile.TemporaryDirectory(prefix='bsas-tests-')
os.environ['ENVIRONMENT'] = 'testing'
os.environ['SECRET_KEY'] = 'isolated-bsas-test-secret-never-use-in-production'
os.environ['DATABASE_URL'] = os.getenv('BSAS_TEST_DATABASE_URL', 'sqlite:///' + (Path(_temporary.name) / 'test.db').as_posix())

from fastapi.testclient import TestClient
from app.main import app
from app.database import Base, engine, SessionLocal, init_db
from app.models.user import User
from app.security import get_password_hash
from app.api.auth import create_access_token


def pytest_sessionfinish(session, exitstatus):
    engine.dispose()
    _temporary.cleanup()


@pytest.fixture(autouse=True)
def isolated_database():
    init_db()
    with engine.begin() as conn:
        for table in reversed(Base.metadata.sorted_tables):
            conn.execute(table.delete())
    yield


@pytest.fixture
def client():
    with SessionLocal() as db:
        admin = User(email='operator@example.test', role='ADMIN', is_active=True,
                     hashed_password=get_password_hash('TestPassword123!'))
        db.add(admin)
        db.commit()
    with TestClient(app) as client:
        client.headers['Authorization'] = 'Bearer ' + create_access_token({'sub': 'operator@example.test'})
        yield client


@pytest.fixture
def anonymous():
    with TestClient(app) as client:
        yield client
