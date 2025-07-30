from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from werkzeug.security import generate_password_hash, check_password_hash
from db import get_db_connection

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.json
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"message": "아이디와 비밀번호를 모두 입력해주세요."}), 400

    hashed_pw = generate_password_hash(password)

    conn = get_db_connection()
    with conn.cursor() as cursor:
        try:
            cursor.execute(
                "INSERT INTO users (username, password_hash) VALUES (%s, %s)",
                (username, hashed_pw)
            )
            conn.commit()
        except Exception as e:
            conn.rollback()
            return jsonify({"message": f"회원가입 실패: {str(e)}"}), 400
        finally:
            conn.close()

    return jsonify({"message": "회원가입 성공"}), 201

@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.json
    username = data.get("username")
    password = data.get("password")

    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("SELECT id, password_hash FROM users WHERE username = %s", (username,))
        user = cursor.fetchone()
    conn.close()

    if user and check_password_hash(user["password_hash"], password):
        token = create_access_token(identity=user["id"])
        return jsonify({"token": token, "user_id": user["id"]}), 200
    else:
        return jsonify({"message": "아이디 또는 비밀번호가 잘못되었습니다."}), 401
