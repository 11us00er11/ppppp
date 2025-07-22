from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db_connection

diary_bp = Blueprint("diary", __name__)

@diary_bp.route("/", methods=["POST"])
@jwt_required()
def save_entry():
    user_id = get_jwt_identity()
    data = request.json
    mood = data.get("mood")
    notes = data.get("notes")

    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("INSERT INTO emotion_diary (user_id, mood, notes) VALUES (%s, %s, %s)", (user_id, mood, notes))
        conn.commit()
    conn.close()
    return jsonify({"message": "Entry saved"})

@diary_bp.route("/", methods=["GET"])
@jwt_required()
def get_entries():
    user_id = get_jwt_identity()

    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM emotion_diary WHERE user_id=%s ORDER BY created_at DESC", (user_id,))
        entries = cursor.fetchall()
    conn.close()
    return jsonify(entries)
