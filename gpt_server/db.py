# db.py
import os
import pymysql
from dotenv import load_dotenv

load_dotenv()

DB_CONF = dict(
    host=os.getenv("DB_HOST", "127.0.0.1"),
    user=os.getenv("DB_USER", "root"),
    password=os.getenv("DB_PASSWORD", "aaaa"),
    database=os.getenv("DB_NAME", "gpt_app"),
    port=int(os.getenv("DB_PORT", "3306")),
    charset="utf8mb4",
    cursorclass=pymysql.cursors.DictCursor,
    autocommit=True,
)

def get_conn():
    return pymysql.connect(**DB_CONF)