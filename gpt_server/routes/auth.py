from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt
from werkzeug.security import generate_password_hash, check_password_hash
from db import get_db_connection
import re
from datetime import timedelta
import pymysql

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")

NAME_RE = re.compile(r'^[A-Za-z가-힣\s\-]{2,30}$')

@auth_bp.post("/signup")
def signup():
    data = request.get_json(silent=True) or {}
    user_id = (data.get("user_id") or "").strip()
    user_name = (data.get("user_name") or "").strip()
    password = data.get("password") or ""

    # 기본 검증
    if not user_id or not user_name or not password:
        return jsonify({"message": "아이디, 이름, 비밀번호를 모두 입력해주세요."}), 400
    if not NAME_RE.match(user_name):
        return jsonify({"message": "이름 형식이 올바르지 않습니다. (2~30자, 한글/영문/공백/하이픈)"}), 400
    if len(password) < 8:
        return jsonify({"message": "비밀번호는 8자 이상이어야 합니다."}), 400

    hashed_pw = generate_password_hash(password, method="scrypt")

    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id FROM users WHERE user_id = %s", (user_id,))
            if cursor.fetchone():
                return jsonify({"message": "이미 사용 중인 아이디입니다."}), 409

            cursor.execute(
                "INSERT INTO users (user_id, user_name, password_hash) VALUES (%s, %s, %s)",
                (user_id, user_name, hashed_pw)
            )
        conn.commit()
    except pymysql.err.IntegrityError as e:
        conn.rollback()
        return jsonify({"message": f"회원가입 실패(중복): {str(e)}"}), 409
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"회원가입 실패: {str(e)}"}), 500
    finally:
        conn.close()

    return jsonify({"message": "회원가입 성공"}), 201


@auth_bp.post("/login")
def login():
    data = request.get_json(silent=True) or {}
    user_id = (data.get("user_id") or "").strip()
    password = data.get("password") or ""

    if not user_id or not password:
        return jsonify({"message": "아이디와 비밀번호를 모두 입력해주세요."}), 400

    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT id, user_id, user_name, password_hash FROM users WHERE user_id = %s",
                (user_id,)
            )
            user = cursor.fetchone()
    finally:
        conn.close()

    if not user or not check_password_hash(user["password_hash"], password):
        return jsonify({"message": "아이디 또는 비밀번호가 잘못되었습니다."}), 401

    additional_claims = {
        "user_id": user["user_id"],
        "user_name": user["user_name"],
    }

    token = create_access_token(
        identity=user["id"],
        additional_claims=additional_claims,
        expires_delta=timedelta(hours=24)
    )

    return jsonify({
        "token": token,
        "user": {
            "id": user["id"],
            "user_id": user["user_id"],
            "user_name": user["user_name"],
        }
    }), 200


@auth_bp.get("/me")
@jwt_required()
def me():
    claims = get_jwt()
    return jsonify({
        "id": claims.get("sub"),
        "user_id": claims.get("user_id"),
        "user_name": claims.get("user_name"),
    })
