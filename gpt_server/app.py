# app.py
import os
import pymysql
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity
)
from dotenv import load_dotenv
from groq import Groq

load_dotenv()

app = Flask(__name__)

# === Config ===
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "change-me")
jwt = JWTManager(app)

CORS(app, resources={r"/api/*": {"origins": os.getenv("FRONTEND_ORIGIN", "*")}})

# === LLM ===
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
MODEL_NAME = os.getenv("MODEL_NAME", "llama-3.1-70b-versatile")
SYSTEM_PROMPT = os.getenv("SYSTEM_PROMPT", "너는 마음을 어루만지는 챗봇이야.")

if not GROQ_API_KEY:
    raise RuntimeError("GROQ_API_KEY가 설정되지 않았습니다.")

gclient = Groq(api_key=GROQ_API_KEY)

# === DB ===
def get_conn():
    return pymysql.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", "aaaa"),
        database=os.getenv("DB_NAME", "gpt_app"),
        charset="utf8mb4",
        autocommit=True,
        cursorclass=pymysql.cursors.DictCursor,
    )

# -------------------------------------------------------------------
#  Auth (데모용): 실제 비번 검증 로직은 프로젝트의 해시방식에 맞게 교체하세요.
#  - qurry.txt의 users 테이블: (user_id, user_name, password_hash)
#  - 여기서는 데모로 비밀번호 'pass'면 통과시킵니다.
# -------------------------------------------------------------------
@app.route("/api/auth/login", methods=["POST"])
def login():
    data = request.get_json(force=True) or {}
    user_id = (data.get("user_id") or "").strip()
    password = (data.get("password") or "").strip()

    if not user_id or not password:
        return jsonify({"error": "user_id, password가 필요합니다."}), 400

    with get_conn() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, user_id, user_name, password_hash FROM users WHERE user_id=%s", (user_id,))
        row = cur.fetchone()

    # TODO: 실제로는 row["password_hash"]와 입력 비번을 검증하세요.
    # (passlib 등으로 scrypt/pbkdf2 해시 검증. 여기선 데모로 'pass'만 허용)
    if not row or password != "pass":
        return jsonify({"error": "아이디 또는 비밀번호가 올바르지 않습니다."}), 401

    token = create_access_token(identity={"user_pk": row["id"], "user_id": row["user_id"], "user_name": row["user_name"]})
    return jsonify({"access_token": token, "user": {"user_id": row["user_id"], "user_name": row["user_name"]}})

# -------------------------------------------------------------------
#  Chat (Groq LLaMA 3)
# -------------------------------------------------------------------
@app.route("/api/chat", methods=["POST"])
@jwt_required()
def chat():
    uid = get_jwt_identity()  # {"user_pk", "user_id", "user_name"}
    data = request.get_json(force=True) or {}

    user_message = (data.get("message") or "").strip()
    history = data.get("history") or []  # [{role:"user"|"assistant", content:"..."}]

    if not user_message:
        return jsonify({"error": "message가 필요합니다."}), 400

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
            temperature=0.8,  # 공감/따뜻한 톤 강화
            max_tokens=1024,
        )
        reply = completion.choices[0].message.content
        return jsonify({"reply": reply})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -------------------------------------------------------------------
#  감정일기 (예시): 로그인 사용자 기준으로 저장/조회
# -------------------------------------------------------------------
@app.route("/api/diary", methods=["GET", "POST"])
@jwt_required()
def diary():
    uid = get_jwt_identity()
    user_pk = uid["user_pk"]

    if request.method == "POST":
        data = request.get_json(force=True) or {}
        mood = (data.get("mood") or "").strip()
        notes = data.get("notes") or None

        with get_conn() as conn, conn.cursor() as cur:
            cur.execute(
                "INSERT INTO emotion_diary (user_pk, mood, notes) VALUES (%s, %s, %s)",
                (user_pk, mood, notes),
            )
        return jsonify({"ok": True})

    # GET
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(
            "SELECT id, mood, notes, created_at, updated_at FROM emotion_diary WHERE user_pk=%s AND deleted_at IS NULL ORDER BY created_at DESC",
            (user_pk,),
        )
        rows = cur.fetchall()
    return jsonify({"items": rows})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
