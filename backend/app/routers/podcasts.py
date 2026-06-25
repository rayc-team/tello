import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
from ..database import get_db
from ..models import User, Podcast
from ..schemas import PodcastResponse
from ..dependencies import get_current_user, get_current_admin

router = APIRouter(prefix="/podcasts", tags=["Podcasts"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# 1. Публикация подкаста (Только для Администратора)
@router.post("/", response_model=PodcastResponse, status_code=status.HTTP_201_CREATED)
async def create_podcast(
    title: str = Form(...),
    category: str = Form(...),
    description: str = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    # Проверка расширения файла (на сервере)
    if not file.filename.lower().endswith(".mp3"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Разрешены только файлы формата .mp3"
        )
    
    # Проверка MIME-типа (на сервере)
    if file.content_type != "audio/mpeg":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Неверный MIME-тип. Разрешен только audio/mpeg"
        )
    
    # Валидация размера файла (до 100 МБ)
    if file.size is not None:
        file_size = file.size
    else:
        # Резервный способ через прямое обращение к внутреннему файловому объекту
        file.file.seek(0, 2)
        file_size = file.file.tell()
        file.file.seek(0)
    
    if file_size > 100 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Размер файла превышает лимит в 100 МБ"
        )

    # Генерация уникального имени для исключения совпадений и сохранения анонимности путей
    unique_filename = f"{uuid.uuid4().hex}.mp3"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    try:
        with open(file_path, "wb") as buffer:
            while content := await file.read(1024 * 1024):  # Чтение порциями по 1 МБ
                buffer.write(content)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Не удалось сохранить файл на сервере"
        )

    # Относительный путь, по которому файл будет доступен статически
    static_url = f"/static/{unique_filename}"

    new_podcast = Podcast(
        title=title,
        category=category,
        description=description,
        file_path=static_url
    )
    db.add(new_podcast)
    db.commit()
    db.refresh(new_podcast)
    return new_podcast

# 2. Получение списка подкастов (Для всех авторизованных пользователей)
@router.get("/", response_model=List[PodcastResponse])
def list_podcasts(
    q: Optional[str] = None,
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Podcast)
    
    # Фильтрация по категории
    if category:
        query = query.filter(Podcast.category == category)
        
    # Поиск по названию ( SQLAlchemy защищает от SQL-инъекций за счет параметризованных запросов )
    if q:
        search_query = q[:255]  # Ограничение длины по ТЗ
        query = query.filter(Podcast.title.ilike(f"%{search_query}%"))
        
    return query.all()

# 3. Удаление подкаста (Только для Администратора)
@router.delete("/{podcast_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_podcast(
    podcast_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin)
):
    podcast = db.query(Podcast).filter(Podcast.id == podcast_id).first()
    if not podcast:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Подкаст не найден"
        )
        
    # Извлекаем имя файла и удаляем с физического диска
    filename = os.path.basename(podcast.file_path)
    disk_path = os.path.join(UPLOAD_DIR, filename)
    
    if os.path.exists(disk_path):
        try:
            os.remove(disk_path)
        except Exception:
            # Ошибка удаления физического файла не должна прерывать удаление записи из базы
            pass

    db.delete(podcast)
    db.commit()
    return None