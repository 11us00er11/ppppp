from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from db import get_db_connection

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.json
    email = data.get("email")
    password = data.get("password")  # 실제 구현 시 해싱 필수

    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("INSERT INTO users (email, password_hash) VALUES (%s, %s)", (email, password))
        conn.commit()
    conn.close()
    return jsonify({"message": "User registered"})

@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("SELECT id FROM users WHERE email=%s AND password_hash=%s", (email, password))
        user = cursor.fetchone()
    conn.close()

    if user:
        token = create_access_token(identity=user["id"])
        return jsonify({"token": token})
    else:
        return jsonify({"message": "Invalid credentials"}), 401
