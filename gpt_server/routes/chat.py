# chat.py
from flask import Blueprint, request, jsonify
from services.openai_service import get_chat_response
import logging
import time

chat_bp = Blueprint("chat", __name__)
last_request_time = {}

@chat_bp.route("/chat", methods=["POST"])
def chat():
    try:
        user_ip = request.remote_addr
        now = time.time()
        gap = now - last_request_time.get(user_ip, 0)
        if gap < 2:
            logging.warning(f"429 제한: IP {user_ip}가 {gap:.2f}s 만에 다시 요청")
            return jsonify({"error": "요청이 너무 빠릅니다. 2초 후 다시 시도해주세요."}), 429

        last_request_time[user_ip] = now

        data = request.get_json()
        user_message = data.get("message")
        if not user_message:
            logging.warning("빈 메시지 요청 수신됨")
            return jsonify({"error": "메시지를 입력해주세요."}), 400

        reply = get_chat_response(user_message)
        return jsonify({"response": reply})

    except Exception as e:
        logging.exception("서버 오류")
        msg = str(e)
        status = 429 if "rate" in msg.lower() else 500
        return jsonify({"error": "서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요."}), status
