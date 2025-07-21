from flask import Blueprint, request, jsonify
from services.openai_service import get_chat_response
import logging
import openai
import time

chat_bp = Blueprint("chat", __name__)

# 사용자 요청 간격 제한용 캐시 (IP 기준)
last_request_time = {}

@chat_bp.route("/chat", methods=["POST"])
def chat():
    try:
        user_ip = request.remote_addr
        now = time.time()
        gap = now - last_request_time.get(user_ip, 0)

        if gap < 2:  # 2초 이내에 또 요청한 경우
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

    except openai.error.RateLimitError:
        return jsonify({"error": "현재 GPT 사용량이 초과되었습니다. 잠시 후 다시 시도해주세요."}), 429

    except openai.error.AuthenticationError:
        return jsonify({"error": "서버 인증 오류입니다. 관리자에게 문의해주세요."}), 500

    except openai.error.OpenAIError:
        return jsonify({"error": "GPT 서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요."}), 500

    except Exception as e:
        logging.exception("알 수 없는 서버 오류")
        return jsonify({"error": "예기치 않은 오류가 발생했습니다."}), 500
