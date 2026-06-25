from fastapi import FastAPI
from .database import engine, Base

# Создание таблиц в БД при запуске приложения
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Podcast App API", version="1.0.0")

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Podcast API is working"}