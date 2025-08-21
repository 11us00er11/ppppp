# config.py
from dotenv import load_dotenv
import os

load_dotenv()

DB_CONFIG = {
    'host': os.getenv('DB_HOST', '127.0.0.1'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', 'aaaa'),
    'database': os.getenv('DB_NAME', 'gpt_app'),
    'port': int(os.getenv('DB_PORT', 3306)),
}

SECRET_KEY = os.getenv("JWT_SECRET_KEY", os.getenv("SECRET_KEY", "fallback_key"))
