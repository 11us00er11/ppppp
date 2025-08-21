# routes/auth.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import timedelta
from flask_cors import cross_origin
import re, pymysql
from db import get_conn

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")
NAME_RE = re.compile(r'^[A-Za-z가-힣\s\-]{2,30}$')

def _json():
    return request.get_json(silent=True) or {}

def _success_payload(uid: int, user_id: str, user_name: str, status=200):
    access = create_access_token(
        identity=uid,
        additional_claims={"user_id": user_id, "user_name": user_name, "user_pk": uid},
        expires_delta=timedelta(hours=24),
    )
    return jsonify({
        "ok": True,
        "token": access,            # 과거/현재 클라 호환
        "access_token": access,     # 선호 스키마
        "user": {                   # 객체형으로 받는 경우
            "id": uid,
            "user_id": user_id,
            "user_name": user_name,
            "user_pk": uid          # ← login_screen이 우선 탐색
        },
        "userPk": uid,              # 평면형으로 받는 경우
        "userName": user_name
    }), status

@auth_bp.post("/signup")
@cross_origin(origins="*",
              allow_headers=["Content-Type", "Authorization"],
              methods=["GET","POST","PUT","DELETE","OPTIONS"])
def signup():
    d = _json()
    user_id   = (d.get("user_id")   or "").strip()
    user_name = (d.get("user_name") or "").strip()
    password  =  d.get("password")  or ""
    if not user_id or not user_name or not password:
        return jsonify(ok=False, message="아이디, 이름, 비밀번호를 모두 입력해주세요."), 400
    if not NAME_RE.match(user_name):
        return jsonify(ok=False, message="이름 형식이 올바르지 않습니다."), 400
    if len(password) < 8:
        return jsonify(ok=False, message="비밀번호는 8자 이상이어야 합니다."), 400

    pwd_hash = generate_password_hash(password, method="scrypt")

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM users WHERE user_id=%s", (user_id,))
            if cur.fetchone():
                return jsonify(ok=False, message="이미 사용 중인 아이디입니다."), 409
            cur.execute(
                "INSERT INTO users (user_id, user_name, password_hash) VALUES (%s,%s,%s)",
                (user_id, user_name, pwd_hash)
            )
            cur.execute("SELECT LAST_INSERT_ID() AS id")
            new_id = cur.fetchone()["id"]
        conn.commit()
    except pymysql.err.IntegrityError as e:
        if conn: conn.rollback()
        return jsonify(ok=False, message=f"회원가입 실패(중복): {e}"), 409
    except Exception as e:
        if conn: conn.rollback()
        return jsonify(ok=False, message=f"회원가입 실패: {e}"), 500
    finally:
        conn.close()

    return _success_payload(new_id, user_id, user_name, status=201)

@auth_bp.post("/login")
@cross_origin(origins="*",
              allow_headers=["Content-Type", "Authorization"],
              methods=["GET","POST","PUT","DELETE","OPTIONS"])
def login():
    d = _json()
    user_id  = (d.get("user_id") or "").strip()
    password =  d.get("password") or ""
    if not user_id or not password:
        return jsonify(ok=False, message="아이디와 비밀번호를 모두 입력해주세요."), 400

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, user_id, user_name, password_hash FROM users WHERE user_id=%s",
                (user_id,)
            )
            row = cur.fetchone()
    finally:
        conn.close()

    if not row or not check_password_hash(row["password_hash"], password):
        return jsonify(ok=False, message="아이디 또는 비밀번호가 잘못되었습니다."), 401

    return _success_payload(row["id"], row["user_id"], row["user_name"], status=200)

@auth_bp.post("/guest")
def guest():
    access = create_access_token(
        identity=0,
        additional_claims={"user_id":"guest","user_name":"게스트","user_pk":0},
        expires_delta=timedelta(hours=1),
    )
    return jsonify(ok=True, access_token=access), 200

@auth_bp.get("/me")
@jwt_required()
def me():
    uid = get_jwt_identity()
    if not isinstance(uid, int):
        return jsonify(ok=False, message="게스트는 사용자 정보가 없습니다."), 403

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, user_id, user_name, created_at FROM users WHERE id=%s",
                (uid,)
            )
            row = cur.fetchone()
    finally:
        conn.close()

    return jsonify(ok=True, user=row), 200
