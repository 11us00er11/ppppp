# gpt_server.py
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity
)
from werkzeug.security import generate_password_hash, check_password_hash
import pymysql
import logging

# ---------------------- Flask App ----------------------
app = Flask(__name__)

# ★ 실제 서비스에서는 .env로 빼세요
app.config['JWT_SECRET_KEY'] = 'change_me_to_strong_secret'

# /api/diary 와 /api/diary/ 둘 다 허용
app.url_map.strict_slashes = False

# CORS: Flutter Web 대비
CORS(app,
     resources={r"/api/*": {"origins": "*"}},
     supports_credentials=False,
     expose_headers=["Content-Type", "Authorization"])

@app.after_request
def add_cors_headers(resp):
    origin = request.headers.get("Origin", "*")
    resp.headers["Access-Control-Allow-Origin"] = origin
    resp.headers["Vary"] = "Origin"
    resp.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
    resp.headers["Access-Control-Allow-Methods"] = "GET, POST, DELETE, PUT, OPTIONS"
    return resp

# 로깅(422 원인 등 확인용)
logging.basicConfig(level=logging.INFO)

# JWT는 app 생성 이후에 초기화해야 함 (NameError 방지)
jwt = JWTManager(app)

# 422/401 원인 진단 핸들러
@jwt.invalid_token_loader
def invalid_token_callback(reason):
    app.logger.error(f"[JWT invalid] {reason}")
    return jsonify(error=f"invalid_token: {reason}"), 422

@jwt.unauthorized_loader
def missing_token_callback(reason):
    app.logger.error(f"[JWT missing] {reason}")
    return jsonify(error=f"missing_token: {reason}"), 401

@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    app.logger.error("[JWT expired]")
    return jsonify(error="token_expired"), 401

# ---------------------- DB ----------------------
def get_db_connection():
    return pymysql.connect(
        host='localhost', user='root', password='aaaa', db='gpt_app',
        charset='utf8mb4', cursorclass=pymysql.cursors.DictCursor
    )

# ---------------------- Auth ----------------------
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
        return jsonify(error="이미 사용 중인 아이디입니다."), 409
    except Exception as e:
        app.logger.exception("signup error")
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
            cur.execute("""
                SELECT id, user_id, user_name, password_hash
                FROM users
                WHERE user_id=%s
            """, (user_id,))
            user = cur.fetchone()

        if not user or not check_password_hash(user["password_hash"], password):
            return jsonify(error="아이디 또는 비밀번호가 잘못되었습니다."), 401

        # ★ PyJWT 2.x: sub는 문자열 권장 → 문자열로 저장
        token = create_access_token(identity=str(user["id"]))

        return jsonify(
            token=token,
            user={"id": user["id"], "user_id": user["user_id"], "user_name": user["user_name"]}
        ), 200
    except Exception as e:
        app.logger.exception("login error")
        return jsonify(error=str(e)), 500
    finally:
        conn.close()

# ---------------------- Diary (list/create) ----------------------
@app.route("/api/diary", methods=["GET", "POST", "OPTIONS"])
@app.route("/api/diary/", methods=["GET", "POST", "OPTIONS"])
@jwt_required(optional=False)
def diary_collection():
    if request.method == "OPTIONS":
        return ("", 204)

    # ★ 토큰에서 문자열로 꺼낸 뒤 int로 변환
    try:
        user_id = int(get_jwt_identity())
    except Exception:
        return jsonify(error="Unauthorized"), 401

    if request.method == "GET":
        page = max(int(request.args.get("page", 1) or 1), 1)
        page_size = int(request.args.get("page_size", 20) or 20)
        page_size = max(1, min(page_size, 100))

        q = (request.args.get("q") or "").strip()
        from_str = (request.args.get("from") or "").strip()
        to_str = (request.args.get("to") or "").strip()
        moods_str = (request.args.get("mood") or "").strip()

        where = ["user_pk=%s", "deleted_at IS NULL"]
        params = [user_id]

        # 날짜(하루 전체 포함)
        if from_str:
            try:
                d = datetime.strptime(from_str, "%Y-%m-%d")
                where.append("created_at >= %s")
                params.append(d.strftime("%Y-%m-%d 00:00:00"))
            except:
                pass
        if to_str:
            try:
                d = datetime.strptime(to_str, "%Y-%m-%d") + timedelta(days=1)
                where.append("created_at < %s")
                params.append(d.strftime("%Y-%m-%d 00:00:00"))
            except:
                pass

        # 무드 필터
        if moods_str:
            moods = [m.strip() for m in moods_str.split(",") if m.strip()]
            if moods:
                where.append("mood IN (" + ",".join(["%s"] * len(moods)) + ")")
                params.extend(moods)

        # 키워드 검색
        if q:
            where.append("notes LIKE %s")
            params.append(f"%{q}%")

        where_sql = " AND ".join(where)
        offset = (page - 1) * page_size

        conn = get_db_connection()
        try:
            with conn.cursor() as cur:
                cur.execute(f"""
                    SELECT id, user_pk, mood, notes, created_at, updated_at
                    FROM emotion_diary
                    WHERE {where_sql}
                    ORDER BY created_at DESC, id DESC
                    LIMIT %s OFFSET %s
                """, params + [page_size, offset])
                rows = cur.fetchall()
            # Flutter는 data['items']를 읽음
            return jsonify({"items": rows}), 200
        except Exception as e:
            app.logger.exception("diary list error")
            return jsonify(error=str(e)), 500
        finally:
            conn.close()

    # POST (create)
    data = request.get_json(silent=True) or {}
    mood = (data.get("mood") or "").strip() or None
    notes = (data.get("notes") or "").strip() or None

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO emotion_diary (user_pk, mood, notes)
                VALUES (%s, %s, %s)
            """, (user_id, mood, notes))
            new_id = cur.lastrowid
            conn.commit()

            cur.execute("""
                SELECT id, user_pk, mood, notes, created_at, updated_at
                FROM emotion_diary
                WHERE id=%s
            """, (new_id,))
            row = cur.fetchone()

        # Flutter create()는 단일 객체 또는 {"item": {...}} 모두 처리
        return jsonify(row), 201
    except Exception as e:
        conn.rollback()
        app.logger.exception("diary create error")
        return jsonify(error=str(e)), 500
    finally:
        conn.close()

# ---------------------- Diary (delete) ----------------------
@app.route("/api/diary/<int:pk>", methods=["DELETE", "OPTIONS"])
@jwt_required(optional=False)
def diary_item(pk):
    if request.method == "OPTIONS":
        return ("", 204)

    try:
        user_id = int(get_jwt_identity())
    except Exception:
        return jsonify(error="Unauthorized"), 401

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            # 소프트 삭제 (deleted_at 사용). 없으면 물리 삭제로 대체 가능.
            cur.execute("""
                UPDATE emotion_diary
                SET deleted_at = NOW()
                WHERE id=%s AND user_pk=%s AND deleted_at IS NULL
            """, (pk, user_id))
            if cur.rowcount == 0:
                # 소프트 삭제가 반영 안되면 물리 삭제 시도(옵션)
                cur.execute("""
                    DELETE FROM emotion_diary
                    WHERE id=%s AND user_pk=%s
                """, (pk, user_id))
        conn.commit()
        return ("", 204)
    except Exception as e:
        conn.rollback()
        app.logger.exception("diary delete error")
        return jsonify(error=str(e)), 500
    finally:
        conn.close()

# ---------------------- Run ----------------------
if __name__ == "__main__":
    # 개발용 실행
    app.run(host="0.0.0.0", port=5000, debug=True)
