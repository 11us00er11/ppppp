from dotenv import load_dotenv
import os

load_dotenv()  # .env 파일 로드

DB_CONFIG = {
    'host': os.getenv('DB_HOST'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'database': os.getenv('DB_NAME'),
    'port': int(os.getenv('DB_PORT', 3306))
}

SECRET_KEY = os.getenv("SECRET_KEY", "fallback_key")