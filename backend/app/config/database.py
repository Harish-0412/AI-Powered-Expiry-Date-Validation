from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Auto-create database if it doesn't exist on the PostgreSQL server
try:
    default_url = "postgresql://postgres:devpass@localhost:5432/postgres"
    temp_engine = create_engine(default_url, isolation_level="AUTOCOMMIT")
    with temp_engine.connect() as conn:
        exists = conn.execute(text("SELECT 1 FROM pg_database WHERE datname='expiry_mvp'")).scalar()
        if not exists:
            conn.execute(text("CREATE DATABASE expiry_mvp"))
    temp_engine.dispose()
except Exception as e:
    # Print warning if DB server is not reachable, main engine will throw the actual connection error
    print(f"Warning: Could not check/create database 'expiry_mvp': {e}")

SQLALCHEMY_DATABASE_URL = "postgresql://postgres:devpass@localhost:5432/expiry_mvp"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
