from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, description="Пароль должен быть не менее 8 символов")

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str

class UserResponse(BaseModel):
    id: int
    email: EmailStr
    role: str

    class Config:
        from_attributes = True

class PodcastResponse(BaseModel):
    id: int
    title: str
    category: str
    description: Optional[str] = None
    file_path: str  # Публичная ссылка на аудиофайл
    created_at: datetime

    class Config:
        from_attributes = True