from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# Замените параметры подключения на ваши актуальные данные MySQL
DATABASE_URL = "mysql+pymysql://root:*<i51V7CEkgS@localhost:3306/podcast_db"

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True  # Проверка стабильности соединения перед запросом
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Генератор для получения сессии БД в эндпоинтах
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()