import os
from datetime import datetime, timedelta
from typing import Optional

import pymysql
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity
)
from werkzeug.security import check_password_hash, generate_password_hash
from dotenv import load_dotenv
from groq import Groq

# -------------------------------
# Env & App Config
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
CORS(app,
     resources={r"/api/*": {"origins": os.getenv("FRONTEND_ORIGIN", "*")}},
     supports_credentials=True,
     allow_headers=["Content-Type", "Authorization"],
     methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"])

# Groq (LLM)
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
MODEL_NAME = os.getenv("GPT_MODEL", "llama-3.1-70b-versatile")
SYSTEM_PROMPT = os.getenv("SYSTEM_PROMPT", "너는 마음을 어루만지는 챗봇이야.")

if not GROQ_API_KEY:
    raise RuntimeError("GROQ_API_KEY 환경변수가 설정되지 않았습니다.")
gclient = Groq(api_key=GROQ_API_KEY)

# DB
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
def parse_dt(s: Optional[str]) -> Optional[str]:
    """YYYY-MM-DD or YYYY-MM-DD HH:MM 형태를 MySQL DATETIME 문자열로 정규화"""
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
# Auth
# 테이블: users(id, user_id, user_name, password_hash, created_at)
# qurry.sql의 예시 해시가 scrypt 형식일 수 있습니다.
# - Werkzeug의 check_password_hash로 검증을 시도하되,
#   형식 불일치 시 False를 돌려 "아이디/비번 오류"로 처리합니다.
# -------------------------------
@app.post("/api/auth/signup")
def signup():
    data = request.get_json(silent=True) or {}
    user_id = (data.get("user_id") or "").strip()
    user_name = (data.get("user_name") or "").strip()
    password = (data.get("password") or "").strip()

    if not user_id or not user_name or not password:
        return jsonify(error="user_id, user_name, password가 필요합니다."), 400

    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("SELECT id FROM users WHERE user_id=%s", (user_id,))
        if cur.fetchone():
            return jsonify(error="이미 존재하는 user_id 입니다."), 409

        # PBKDF2 해시 사용 (기본)
        pw_hash = generate_password_hash(password)
        cur.execute(
            "INSERT INTO users (user_id, user_name, password_hash) VALUES (%s,%s,%s)",
            (user_id, user_name, pw_hash),
        )

        cur.execute("SELECT id FROM users WHERE user_id=%s", (user_id,))
        row = cur.fetchone()

    token = create_access_token(identity={"user_pk": row["id"], "user_id": user_id, "user_name": user_name})
    return jsonify(access_token=token, user={"user_id": user_id, "user_name": user_name})


@app.post("/api/auth/login")
def login():
    data = request.get_json(silent=True) or {}
    user_id = (data.get("user_id") or "").strip()
    password = (data.get("password") or "").strip()
    if not user_id or not password:
        return jsonify(error="user_id, password가 필요합니다."), 400

    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, user_id, user_name, password_hash FROM users WHERE user_id=%s", (user_id,))
        row = cur.fetchone()

    if not row:
        return jsonify(error="아이디 또는 비밀번호가 올바르지 않습니다."), 401

    stored = row["password_hash"] or ""
    ok = False
    try:
        ok = check_password_hash(stored, password)
    except Exception:
        ok = False  # 해시 포맷 불일치 등

    if not ok:
        # 만약 기존에 '데모 로그인'을 쓰셨다면, 아래를 임시로 허용할 수 있습니다.
        # if password == "pass": ok = True
        return jsonify(error="아이디 또는 비밀번호가 올바르지 않습니다."), 401

    token = create_access_token(identity={"user_pk": row["id"], "user_id": row["user_id"], "user_name": row["user_name"]})
    return jsonify(access_token=token, user={"user_id": row["user_id"], "user_name": row["user_name"]})


# -------------------------------
# Chat (Groq LLM)
# -------------------------------
@app.post("/api/chat")
@jwt_required()
def chat():
    uid = get_jwt_identity()  # {"user_pk","user_id","user_name"}
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

# -------------------------------
# CORS Preflight (OPTIONS)
# -------------------------------
@app.route("/api/diary", methods=["OPTIONS"])
@app.route("/api/diary/", methods=["OPTIONS"])
def diary_options():
    return ("", 204)

@app.route("/api/diary/<int:_id>", methods=["OPTIONS"])
def diary_item_options(_id):
    return ("", 204)

# Chat
@app.route("/api/chat", methods=["OPTIONS"])
def _chat_options():
    return ("", 204)
# -------------------------------
# Emotion Diary
# 테이블: emotion_diary(id, user_pk, mood, notes, created_at, updated_at, deleted_at)
# -------------------------------
@app.get("/api/diary")
@jwt_required()
def diary_list():
    uid = get_jwt_identity()
    user_pk = uid["user_pk"]

    mood = (request.args.get("mood") or "").strip() or None
    q = (request.args.get("q") or "").strip() or None
    dt_from = parse_dt(request.args.get("from"))
    dt_to = parse_dt(request.args.get("to"))

    # ✅ page_size와 size 둘 다 지원
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


@app.post("/api/diary")
@jwt_required()
def diary_create():
    uid = get_jwt_identity()
    user_pk = uid["user_pk"]
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


@app.put("/api/diary/<int:diary_id>")
@jwt_required()
def diary_update(diary_id: int):
    uid = get_jwt_identity()
    user_pk = uid["user_pk"]
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


@app.delete("/api/diary/<int:diary_id>")
@jwt_required()
def diary_delete(diary_id: int):
    uid = get_jwt_identity()
    user_pk = uid["user_pk"]

    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            "UPDATE emotion_diary SET deleted_at=NOW() WHERE id=%s AND user_pk=%s AND deleted_at IS NULL",
            (diary_id, user_pk),
        )
        if cur.rowcount == 0:
            return jsonify(error="삭제할 항목이 없거나 권한이 없습니다."), 404

    return jsonify(ok=True)


# -------------------------------
# Run
# -------------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
