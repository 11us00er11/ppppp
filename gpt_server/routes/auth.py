# routes/auth.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
import re
import pymysql
from datetime import timedelta

# 당신 프로젝트의 DB 헬퍼를 그대로 사용
from db import get_db_connection as get_conn

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")

# 기존의 이름/비밀번호 검증 정책 유지
NAME_RE = re.compile(r'^[A-Za-z가-힣\s\-]{2,30}$')

def _json():
    return request.get_json(silent=True) or {}

@auth_bp.post("/signup")
def signup():
    data = _json()
    user_id   = (data.get("user_id")   or "").strip()
    user_name = (data.get("user_name") or "").strip()
    password  =  data.get("password")  or ""

    # 기본 검증 (당신 코드 유지)
    if not user_id or not user_name or not password:
        return jsonify({"message": "아이디, 이름, 비밀번호를 모두 입력해주세요."}), 400
    if not NAME_RE.match(user_name):
        return jsonify({"message": "이름 형식이 올바르지 않습니다. (2~30자, 한글/영문/공백/하이픈)"}), 400
    if len(password) < 8:
        return jsonify({"message": "비밀번호는 8자 이상이어야 합니다."}), 400

    # scrypt 해시 사용 (DB 초기 샘플도 scrypt 포맷입니다)
    pwd_hash = generate_password_hash(password, method="scrypt")

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM users WHERE user_id=%s", (user_id,))
            if cur.fetchone():
                return jsonify({"message": "이미 사용 중인 아이디입니다."}), 409

            cur.execute(
                "INSERT INTO users (user_id, user_name, password_hash) VALUES (%s,%s,%s)",
                (user_id, user_name, pwd_hash),
            )
            cur.execute("SELECT LAST_INSERT_ID() AS id")
            new_id = cur.fetchone()["id"]
        conn.commit()
    except pymysql.err.IntegrityError as e:
        conn.rollback()
        return jsonify({"message": f"회원가입 실패(중복): {str(e)}"}), 409
    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"회원가입 실패: {str(e)}"}), 500
    finally:
        conn.close()

    # 바로 로그인 토큰 발급: identity=정수 PK
    access = create_access_token(
        identity=new_id,
        additional_claims={"user_id": user_id, "user_name": user_name},
        expires_delta=timedelta(hours=24),
    )
    return jsonify(
        token=access,
        user={"id": new_id, "user_id": user_id, "user_name": user_name},
    ), 201

@auth_bp.post("/login")
def login():
    data = _json()
    user_id  = (data.get("user_id") or "").strip()
    password =  data.get("password") or ""
    if not user_id or not password:
        return jsonify({"message": "아이디와 비밀번호를 모두 입력해주세요."}), 400

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, user_id, user_name, password_hash FROM users WHERE user_id=%s",
                (user_id,),
            )
            row = cur.fetchone()
    finally:
        conn.close()

    # scrypt 포맷은 check_password_hash로 그대로 검증됩니다
    if not row or not check_password_hash(row["password_hash"], password):
        return jsonify({"message": "아이디 또는 비밀번호가 잘못되었습니다."}), 401

    access = create_access_token(
        identity=row["id"],  # ★ 핵심: 정수 PK로 identity 고정
        additional_claims={"user_id": row["user_id"], "user_name": row["user_name"]},
        expires_delta=timedelta(hours=24),
    )
    return jsonify(
        token=access,
        user={"id": row["id"], "user_id": row["user_id"], "user_name": row["user_name"]},
    ), 200

@auth_bp.post("/guest")
def auth_guest():
    """
    게스트 토큰 (권한 제한: /api/diary 등 보호 자원 접근 불가하게 운용)
    - identity는 문자열 'guest'로 발급하여, 서버측에서 int가 아닌 경우 보호 자원 차단/무시 가능
    - /api/chat 처럼 선택 인증(게스트 허용) 엔드포인트에만 사용하세요.
    """
    access = create_access_token(
        identity="guest",
        additional_claims={"user_id": "guest", "user_name": "게스트", "role": "guest"},
        expires_delta=timedelta(hours=6),
    )
    return jsonify(
        token=access,
        user={"id": None, "user_id": "guest", "user_name": "게스트", "role": "guest"},
    ), 200

@auth_bp.get("/me")
@jwt_required()
def me():
    """
    토큰의 identity(정수 PK)로 DB에서 최신 정보를 조회해서 반환
    """
    user_pk = get_jwt_identity()
    if not isinstance(user_pk, int):
        return jsonify({"message": "게스트는 사용자 정보가 없습니다."}), 403

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, user_id, user_name, created_at FROM users WHERE id=%s",
                (user_pk,),
            )
            row = cur.fetchone()
    finally:
        conn.close()

    return jsonify(user=row), 200
