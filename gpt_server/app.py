from flask import Flask
from flask_cors import CORS
from routes.chat import chat_bp
from config import load_env
from routes.auth import auth_bp
from routes.diary import diary_bp
import logging

logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(asctime)s - %(message)s",
    handlers=[
        logging.FileHandler("server.log", encoding="utf-8"),  # 로그 파일로 저장
        logging.StreamHandler()  # 콘솔에도 출력
    ]
)

load_env()

app = Flask(__name__)
CORS(app)
app.config['JWT_SECRET_KEY'] = SECRET_KEY
jwt = JWTManager(app)

# 블루프린트 등록
app.register_blueprint(chat_bp)
app.register_blueprint(auth_bp, url_prefix="/api/auth")
app.register_blueprint(diary_bp, url_prefix="/api/diary")

if __name__ == "__main__":
    app.run(debug=True, port=5000)
