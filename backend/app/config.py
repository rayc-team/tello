import os

# Секретный ключ для подписи токенов JWT. Нужно будет потом убрать.
SECRET_KEY = os.getenv("SECRET_KEY", "your_super_secret_jwt_key_here_change_me_in_production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # Срок действия токена - 24 часа.