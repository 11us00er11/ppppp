# services/openai_service.py
import os
import logging
import time
from groq import Groq

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise RuntimeError("GROQ_API_KEY가 설정되지 않았습니다.")
client = Groq(api_key=GROQ_API_KEY)

system_prompt = os.getenv("SYSTEM_PROMPT", "너는 마음을 어루만지는 챗봇이야.")
default_model = os.getenv("GPT_MODEL", os.getenv("MODEL_NAME", "llama-3.1-70b-versatile"))

def get_chat_response(user_message: str) -> str:
    max_retries = 3
    delay = 2
    for attempt in range(max_retries):
        try:
            logging.info(f"사용자 메시지 수신: {user_message}")
            completion = client.chat.completions.create(
                model=default_model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                temperature=0.8,
                max_tokens=1024,
            )
            return completion.choices[0].message.content
        except Exception as e:
            logging.warning(f"Groq 호출 실패 (시도 {attempt+1}/{max_retries}): {e}")
            if attempt == max_retries - 1:
                raise
            time.sleep(delay)
            delay *= 2
