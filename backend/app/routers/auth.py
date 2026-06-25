from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import User
from ..schemas import UserCreate, UserLogin, Token, UserResponse
from ..security import hash_password, verify_password, create_access_token
from ..dependencies import get_current_admin

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Проверяем, существует ли уже пользователь с таким email
    db_user = db.query(User).filter(User.email == user_data.email).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Пользователь с таким email уже зарегистрирован"
        )

    # Создаем нового пользователя
    hashed_pw = hash_password(user_data.password)
    new_user = User(
        email=user_data.email,
        hashed_password=hashed_pw,
        role="listener"  # По умолчанию регистрируем с ролью Слушателя
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login", response_model=Token)
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    # Поиск пользователя
    db_user = db.query(User).filter(User.email == user_data.email).first()
    if not db_user or not verify_password(user_data.password, db_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный email или пароль"
        )

    # Генерация JWT
    access_token = create_access_token(data={"sub": db_user.email, "role": db_user.role})
    return Token(access_token=access_token, role=db_user.role)

@router.get("/users", response_model=List[UserResponse])
def list_users(
    db: Session = Depends(get_db), 
    current_admin: User = Depends(get_current_admin)
):
    """Возвращает список всех зарегистрированных пользователей (только для Администратора)."""
    return db.query(User).all()