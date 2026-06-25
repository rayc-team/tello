from sqlalchemy import Column, Integer, String, DateTime, func
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(150), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(String(50), default="listener", nullable=False)  # 'listener' или 'admin'.

class Podcast(Base):
    __tablename__ = "podcasts"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    category = Column(String(100), nullable=False)
    description = Column(String(1000), nullable=True)
    file_path = Column(String(500), nullable=False)  # Путь к MP3 файлу на сервере.
    created_at = Column(DateTime, server_default=func.now())