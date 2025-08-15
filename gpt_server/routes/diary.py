# routes/diary.py
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db_connection

# 슬래시 유연 처리
diary_bp = Blueprint("diary", __name__, strict_slashes=False)

def _row_to_dict(row):
    return {
        "id": row[0],
        "user_pk": row[1],
        "mood": row[2],
        "notes": row[3],
        "created_at": row[4].isoformat() if row[4] else None,
        "updated_at": row[5].isoformat() if row[5] else None,
    }

# ✔ 컬렉션 엔드포인트: ''와 '/' 둘 다 매칭 + OPTIONS 포함
@diary_bp.route("",  methods=["GET", "POST", "OPTIONS"])
@diary_bp.route("/", methods=["GET", "POST", "OPTIONS"])
@jwt_required()
def diary_collection():
    if request.method == "OPTIONS":
        return ("", 200)

    user_pk = get_jwt_identity()

    if request.method == "POST":
        data = request.get_json(silent=True) or {}
        mood  = (data.get("mood")  or None)
        notes = (data.get("notes") or None)

        conn = get_db_connection()
        try:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO emotion_diary (user_pk, mood, notes)
                    VALUES (%s, %s, %s)
                """, (user_pk, mood, notes))
                diary_id = cur.lastrowid
                conn.commit()

                cur.execute("""
                    SELECT id, user_pk, mood, notes, created_at, updated_at
                    FROM emotion_diary
                    WHERE id=%s
                """, (diary_id,))
                created = _row_to_dict(cur.fetchone())
            return jsonify(created), 201
        finally:
            conn.close()

    # GET
    page = max(int(request.args.get("page", 1)), 1)
    page_size = min(max(int(request.args.get("page_size", 20)), 1), 100)
    from_ = request.args.get("from")
    to_   = request.args.get("to")
    q     = request.args.get("q")
    moods_raw = request.args.get("mood")
    moods = [m.strip() for m in moods_raw.split(",")] if moods_raw else []

    where = ["user_pk=%s", "deleted_at IS NULL"]
    params = [user_pk]

    if from_ and to_:
        where.append("DATE(created_at) BETWEEN %s AND %s")
        params += [from_, to_]
    elif from_:
        where.append("DATE(created_at) >= %s"); params.append(from_)
    elif to_:
        where.append("DATE(created_at) <= %s"); params.append(to_)

    if moods:
        where.append(f"mood IN ({', '.join(['%s']*len(moods))})")
        params += moods

    if q:
        where.append("notes LIKE %s")
        params.append(f"%{q}%")

    where_sql = " AND ".join(where)
    limit = page_size
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
            """, (*params, limit, offset))
            items = [_row_to_dict(r) for r in cur.fetchall()]
        return jsonify({"items": items}), 200
    finally:
        conn.close()

# ✔ 개별 리소스
@diary_bp.route("/<int:diary_id>", methods=["DELETE", "OPTIONS"])
@jwt_required()
def diary_delete(diary_id):
    if request.method == "OPTIONS":
        return ("", 200)

    user_pk = get_jwt_identity()
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE emotion_diary
                SET deleted_at = NOW()
                WHERE id=%s AND user_pk=%s AND deleted_at IS NULL
            """, (diary_id, user_pk))
            conn.commit()
        return ("", 204)
    finally:
        conn.close()
