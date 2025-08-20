import os
from datetime import datetime, timedelta
from typing import Optional
import base64, hashlib, hmac

import pymysql
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import (
    JWTManager, jwt_required, get_jwt_identity, verify_jwt_in_request
)
from werkzeug.security import check_password_hash, generate_password_hash
from dotenv import load_dotenv
from groq import Groq
from db import get_conn
from routes.auth import auth_bp
# 블루프린트: 인증은 auth.py로 통일 (/api/auth/...)
# C:\flutterproject\gpt_server\routes\__init__.py (빈 파일) 만들어 두세요.

# -------------------------------
# App & Env
# -------------------------------
load_dotenv()

app = Flask(__name__)
app.url_map.strict_slashes = False

# JWT
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "change_me_to_strong_secret")
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(
    hours=int(os.getenv("JWT_EXPIRE_HOURS", "24"))
)
jwt = JWTManager(app)

# CORS
origins_env = os.getenv("FRONTEND_ORIGIN", "*")
origin_list = [o.strip() for o in origins_env.split(",") if o.strip()]
_allow_all = (len(origin_list) == 1 and origin_list[0] == "*")
CORS(
    app,
    resources={r"/api/*": {"origins": "*" if _allow_all else origin_list}},
    supports_credentials=False if _allow_all else True,
    allow_headers=["Content-Type", "Authorization"],
    methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
)

# 인증 블루프린트 등록 (/api/auth/signup, /api/auth/login, /api/auth/me)
app.register_blueprint(auth_bp)  # auth.py 블루프린트(url_prefix="/api/auth")

# -------------------------------
# LLM (Groq)
# -------------------------------
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
MODEL_NAME = os.getenv("GPT_MODEL", "llama-3.1-70b-versatile")
SYSTEM_PROMPT = os.getenv("SYSTEM_PROMPT", "너는 마음을 어루만지는 챗봇이야.")
if not GROQ_API_KEY:
    raise RuntimeError("GROQ_API_KEY 환경변수가 설정되지 않았습니다.")
gclient = Groq(api_key=GROQ_API_KEY)

# -------------------------------
# DB
# -------------------------------
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

# -------------------------------
# Utils
# -------------------------------
def _b64decode_with_padding(s: str) -> bytes:
    pad = "=" * (-len(s) % 4)
    return base64.b64decode(s + pad)

def verify_password_compat(stored_hash: str, password: str) -> bool:
    """
    (참고용) PBKDF2/werkzeug 기본 해시 체크 + scrypt 포맷 수동 검증
    """
    try:
        if check_password_hash(stored_hash, password):
            return True
    except Exception:
        pass

    if stored_hash.startswith("scrypt:"):
        try:
            header, salt, hex_digest = stored_hash.split("$", 2)
            _, n_s, r_s, p_s = header.split(":")
            n, r, p = int(n_s), int(r_s), int(p_s)

            salt_bytes = _b64decode_with_padding(salt)
            dk = hashlib.scrypt(
                password.encode("utf-8"),
                salt=salt_bytes,
                n=n, r=r, p=p,
                maxmem=0,
                dklen=len(bytes.fromhex(hex_digest)),
            )
            return hmac.compare_digest(dk, bytes.fromhex(hex_digest))
        except Exception:
            return False
    return False

def parse_dt(s: Optional[str]) -> Optional[str]:
    """YYYY-MM-DD or YYYY-MM-DD HH:MM → 'YYYY-MM-DD HH:MM:SS'"""
    if not s:
        return None
    s = s.strip()
    for fmt in ("%Y-%m-%d %H:%M", "%Y-%m-%d"):
        try:
            return datetime.strptime(s, fmt).strftime("%Y-%m-%d %H:%M:%S")
        except ValueError:
            continue
    return None

# -------------------------------
# Health
# -------------------------------
@app.get("/api/health")
def health():
    return jsonify(ok=True, model=MODEL_NAME, time=datetime.utcnow().isoformat() + "Z")

# -------------------------------
# Chat (선택 인증: 게스트 허용)
# -------------------------------
@app.post("/api/chat")
def chat():
    # 토큰이 있으면 해석, 없어도 통과 → 게스트 허용
    verify_jwt_in_request(optional=True)
    # auth.py의 로그인은 identity=사용자 PK(int)로 발급하므로 int가 나옵니다.
    ident = get_jwt_identity()
    if isinstance(ident, int):
        uid = {"user_pk": ident}
    else:
        uid = {"user_pk": None, "role": "guest"}

    data = request.get_json(silent=True) or {}
    user_message = (data.get("message") or "").strip()
    history = data.get("history") or []  # [{role:"user"|"assistant", content:"..."}]
    if not user_message:
        return jsonify(error="message가 필요합니다."), 400

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    for turn in history:
        r = turn.get("role")
        c = (turn.get("content") or "").strip()
        if r in ("user", "assistant") and c:
            messages.append({"role": r, "content": c})
    messages.append({"role": "user", "content": user_message})

    try:
        completion = gclient.chat.completions.create(
            model=MODEL_NAME,
            messages=messages,
            temperature=0.8,
            max_tokens=1024,
        )
        reply = completion.choices[0].message.content
        return jsonify(reply=reply)
    except Exception as e:
        return jsonify(error=str(e)), 500

# 프리플라이트(OPTIONS)
@app.route("/api/chat", methods=["OPTIONS"])
def _chat_options():
    return ("", 204)

# -------------------------------
# Emotion Diary (로그인 필수)
#  - auth.py 로그인 토큰은 identity=정수(사용자 PK) 입니다.
#  - 따라서 get_jwt_identity() → int 를 user_pk로 사용하세요.
# -------------------------------
@app.get("/api/history")
@jwt_required()
def diary_list():
    user_pk = get_jwt_identity()   # int
    mood = (request.args.get("mood") or "").strip() or None
    q = (request.args.get("q") or "").strip() or None
    dt_from = parse_dt(request.args.get("from"))
    dt_to = parse_dt(request.args.get("to"))

    page = max(1, int(request.args.get("page", "1")))
    size_param = request.args.get("size", request.args.get("page_size", "20"))
    size = min(100, max(1, int(size_param)))
    offset = (page - 1) * size

    where = ["user_pk=%s", "deleted_at IS NULL"]
    params = [user_pk]
    if mood:
        where.append("mood=%s")
        params.append(mood)
    if q:
        where.append("(notes LIKE %s)")
        params.append(f"%{q}%")
    if dt_from:
        where.append("created_at >= %s")
        params.append(dt_from)
    if dt_to:
        where.append("created_at <= %s")
        params.append(dt_to)

    where_sql = " AND ".join(where)
    sql = f"""
        SELECT id, mood, notes, created_at, updated_at
        FROM emotion_diary
        WHERE {where_sql}
        ORDER BY created_at DESC
        LIMIT %s OFFSET %s
    """

    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(sql, (*params, size, offset))
        items = cur.fetchall()

        cur.execute(f"SELECT COUNT(*) AS cnt FROM emotion_diary WHERE {where_sql}", params)
        total = cur.fetchone()["cnt"]

    return jsonify(
        items=items,
        page=page,
        size=size,
        total=total,
        pages=(total + size - 1) // size
    )

@app.post("/api/history")
@jwt_required()
def diary_create():
    user_pk = get_jwt_identity()  # int
    data = request.get_json(silent=True) or {}
    mood = (data.get("mood") or "").strip()
    notes = (data.get("notes") or None)

    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            "INSERT INTO emotion_diary (user_pk, mood, notes) VALUES (%s,%s,%s)",
            (user_pk, mood, notes),
        )
        cur.execute("SELECT LAST_INSERT_ID() AS id")
        new_id = cur.fetchone()["id"]

        cur.execute(
            "SELECT id, mood, notes, created_at, updated_at FROM emotion_diary WHERE id=%s",
            (new_id,),
        )
        row = cur.fetchone()

    return jsonify(item=row), 201

@app.put("/api/history/<int:diary_id>")
@jwt_required()
def diary_update(diary_id: int):
    user_pk = get_jwt_identity()  # int
    data = request.get_json(silent=True) or {}
    mood = (data.get("mood") or "").strip() or None
    notes = (data.get("notes") or None)

    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            "UPDATE emotion_diary SET mood=%s, notes=%s WHERE id=%s AND user_pk=%s AND deleted_at IS NULL",
            (mood, notes, diary_id, user_pk),
        )
        if cur.rowcount == 0:
            return jsonify(error="수정할 항목이 없거나 권한이 없습니다."), 404

        cur.execute(
            "SELECT id, mood, notes, created_at, updated_at FROM emotion_diary WHERE id=%s",
            (diary_id,),
        )
        row = cur.fetchone()

    return jsonify(item=row)

@app.delete("/api/history/<int:diary_id>")
@jwt_required()
def diary_delete(diary_id: int):
    user_pk = get_jwt_identity()  # int
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            "UPDATE emotion_diary SET deleted_at=NOW() WHERE id=%s AND user_pk=%s AND deleted_at IS NULL",
            (diary_id, user_pk),
        )
        if cur.rowcount == 0:
            return jsonify(error="삭제할 항목이 없거나 권한이 없습니다."), 404

    return jsonify(ok=True)

# 프리플라이트(OPTIONS)
@app.route("/api/history", methods=["OPTIONS"])
@app.route("/api/history/", methods=["OPTIONS"])
def diary_options():
    return ("", 204)

@app.route("/api/history/<int:_id>", methods=["OPTIONS"])
def diary_item_options(_id):
    return ("", 204)

@app.after_request
def _add_cors_headers(resp):
    # /api/* 만 타겟
    if request.path.startswith("/api/"):
        origin = request.headers.get("Origin", "")
        # 1) *. 개발 편의: 와일드카드 (쿠키 안 쓸 때)
        resp.headers.setdefault("Access-Control-Allow-Origin", "*")
        # 2) 또는 특정 오리진만 허용하려면 아래처럼:
        # if origin in {"http://localhost:3000", "http://127.0.0.1:3000"}:
        #     resp.headers["Access-Control-Allow-Origin"] = origin

        resp.headers.setdefault("Vary", "Origin")
        resp.headers.setdefault("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        # Authorization, Content-Type 둘 다 포함!
        resp.headers.setdefault("Access-Control-Allow-Headers", "Authorization, Content-Type")
        # 쿠키 안 쓰면 False 유지
        # resp.headers.setdefault("Access-Control-Allow-Credentials", "false")
    return resp

# -------------------------------
# Run
# -------------------------------
if __name__ == "__main__":
    # 개발 시 0.0.0.0:5000
    app.run(host="0.0.0.0", port=5000)
