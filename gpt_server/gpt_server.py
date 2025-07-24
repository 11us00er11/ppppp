from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import os
import logging

load_dotenv()

app = Flask(__name__)
CORS(app)

logging.basicConfig(level=logging.INFO)

@app.route("/chat", methods=["POST"])
def chat():
    try:
        user_message = request.json.get("message", "")
        if not user_message:
            return jsonify({"response": "입력 메시지가 없습니다."}), 400

        reply = get_chat_response(user_message)
        return jsonify({"response": reply})

    except Exception as e:
        logging.exception("서버 오류 발생")
        return jsonify({"response": "서버 오류가 발생했습니다."}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
