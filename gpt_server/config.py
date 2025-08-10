# config.py
from dotenv import load_dotenv
import os

# .env 파일 로드
load_dotenv()

# DB 접속 정보 딕셔너리
DB_CONFIG = {
    'host': os.getenv('DB_HOST', '127.0.0.1'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'database': os.getenv('DB_NAME', 'gpt_app'),
    'port': int(os.getenv('DB_PORT', 3306)),
}

# JWT 시크릿 키
SECRET_KEY = os.getenv("JWT_SECRET_KEY", os.getenv("SECRET_KEY", "fallback_key"))
