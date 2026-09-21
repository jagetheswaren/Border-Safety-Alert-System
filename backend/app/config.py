import os
import logging
from pathlib import Path
from typing import List
from pydantic import BaseModel

logger = logging.getLogger("bsas.config")

BACKEND_DIR = Path(__file__).resolve().parent.parent
DEFAULT_DB_PATH = (BACKEND_DIR / "bsas.db").as_posix()

class Settings(BaseModel):
    PROJECT_NAME: str = "Border Safety Alert System"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development").lower().strip()
    
    # In production, SECRET_KEY MUST be provided via environment variable.
    # In development, if SECRET_KEY is not provided, a dev-only key is used with an explicit warning.
    SECRET_KEY: str = os.getenv("SECRET_KEY", "")
    
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", str(60 * 24 * 8)))
    DATABASE_URL: str = os.getenv("DATABASE_URL", f"sqlite:///{DEFAULT_DB_PATH}")
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379")
    
    # Configurable CORS origins (comma-separated list)
    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "")

    def get_cors_origins(self) -> List[str]:
        if self.CORS_ORIGINS:
            return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]
        if self.ENVIRONMENT in ("production", "prod"):
            # In production, require explicit origins or default to safe localhost for staging
            return ["http://localhost:3000", "http://127.0.0.1:3000"]
        return ["*"]

    def validate_production_security(self) -> None:
        """
        Validates security settings at startup.
        Fails fast if production requirements are violated.
        Never logs or exposes the actual secret value.
        """
        is_prod = self.ENVIRONMENT in ("production", "prod")
        
        if is_prod:
            if not self.SECRET_KEY or len(self.SECRET_KEY) < 32:
                raise RuntimeError(
                    "FATAL CONFIGURATION ERROR: Running in PRODUCTION mode, but SECRET_KEY "
                    "environment variable is missing or too short (must be at least 32 characters). "
                    "Application startup aborted to prevent authentication compromise."
                )
            if self.SECRET_KEY in ("super-secret-key-for-dev", "secret", "changeme", "default", "password"):
                raise RuntimeError(
                    "FATAL CONFIGURATION ERROR: Running in PRODUCTION mode with a known weak "
                    "or development SECRET_KEY. Startup aborted."
                )
        else:
            if not self.SECRET_KEY:
                self.SECRET_KEY = "bsas-insecure-dev-only-secret-do-not-use-in-production"
                logger.warning(
                    "[SECURITY WARNING] No SECRET_KEY configured. Running in %s mode with an "
                    "insecure development-only fallback key. Do NOT use this in production!",
                    self.ENVIRONMENT
                )

settings = Settings()
settings.validate_production_security()
