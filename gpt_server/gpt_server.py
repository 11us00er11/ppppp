from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token
from werkzeug.security import generate_password_hash, check_password_hash
import pymysql

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = 'change_me_to_strong_secret'  # .env로 옮기세요
jwt = JWTManager(app)
CORS(app)

def get_db_connection():
    return pymysql.connect(
        host='localhost', user='root', password='aaaa', db='gpt_app',
        charset='utf8mb4', cursorclass=pymysql.cursors.DictCursor
    )

@app.post("/api/auth/signup")
def signup():
    data = request.get_json(silent=True) or {}
    user_id = (data.get("user_id") or "").strip()
    user_name = (data.get("user_name") or "").strip()
    password = data.get("password") or ""

    if not user_id or not user_name or not password:
        return jsonify(error="아이디/이름/비밀번호를 모두 입력해주세요."), 400
    if len(password) < 8:
        return jsonify(error="비밀번호는 8자 이상"), 400

    pw_hash = generate_password_hash(password, method="scrypt")

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO users (user_id, user_name, password_hash) VALUES (%s, %s, %s)",
                (user_id, user_name, pw_hash)
            )
        conn.commit()
        return jsonify(message="회원가입 성공"), 201
    except pymysql.err.IntegrityError:
        # UNIQUE(user_id) 충돌
        return jsonify(error="이미 사용 중인 아이디입니다."), 409
    except Exception as e:
        return jsonify(error=str(e)), 500
    finally:
        conn.close()

@app.post("/api/auth/login")
def login():
    data = request.get_json(silent=True) or {}
    user_id = (data.get("user_id") or "").strip()
    password = data.get("password") or ""

    if not user_id or not password:
        return jsonify(error="아이디/비밀번호를 입력하세요."), 400

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, user_id, user_name, password_hash FROM users WHERE user_id=%s", (user_id,))
            user = cur.fetchone()
        if not user or not check_password_hash(user["password_hash"], password):
            return jsonify(error="아이디 또는 비밀번호가 잘못되었습니다."), 401

        token = create_access_token(identity=user["id"])
        return jsonify(
            token=token,
            user={"id": user["id"], "user_id": user["user_id"], "user_name": user["user_name"]}
        ), 200
    except Exception as e:
        return jsonify(error=str(e)), 500
    finally:
        conn.close()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
