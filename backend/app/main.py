import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from .database import engine, Base
from .routers import auth, podcasts

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Podcast App API", version="1.0.0")

# Автоматически создаем папку для сохранения файлов, если её нет.
os.makedirs("uploads", exist_ok=True)

# Монтируем раздачу статических файлов по адресу /static.
app.mount("/static", StaticFiles(directory="uploads"), name="static")

# Подключаем роутеры.
app.include_router(auth.router)
app.include_router(podcasts.router)

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Podcast API is working"}