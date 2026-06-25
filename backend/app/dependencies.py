from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import jwt
from .database import get_db
from .models import User
from .config import SECRET_KEY, ALGORITHM

# HTTPBearer автоматически генерирует поле ввода Bearer-токена в Swagger UI!
security_scheme = HTTPBearer()

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme), 
    db: Session = Depends(get_db)
) -> User:
    """Проверка валидности токена и возвращение текущего пользователя."""
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Недействительный токен авторизации",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Недействительный токен авторизации",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Пользователь не найден"
        )
    return user

def get_current_admin(current_user: User = Depends(get_current_user)) -> User:
    """Дополнительная проверка: является ли пользователь администратором."""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Доступ запрещен. Требуются права администратора."
        )
    return current_user