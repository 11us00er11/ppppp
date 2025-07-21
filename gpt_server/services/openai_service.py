import openai
import os
import logging
import time

openai.api_key = os.getenv("OPENAI_API_KEY")
system_prompt = os.getenv("SYSTEM_PROMPT", "너는 마음을 어루만지는 챗봇이야.")

def get_chat_response(user_message):
    max_retries = 3
    delay = 2  # 초기 지연 시간 (초)

    for attempt in range(max_retries):
        try:
            logging.info(f"사용자 메시지 수신: {user_message}")

            response = openai.ChatCompletion.create(
                model=os.getenv("GPT_MODEL", "gpt-3.5-turbo"),
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message}
                ]
            )

            logging.info("GPT 응답 생성 성공")
            return response["choices"][0]["message"]["content"]

        except openai.error.RateLimitError as e:
            logging.warning(f"RateLimitError 발생 (시도 {attempt + 1}/{max_retries}), {delay}s 후 재시도")
            time.sleep(delay)
            delay *= 2  # 2, 4, 8초 지연

    logging.error("GPT 호출 실패: 재시도 끝", exc_info=True)
    raise openai.error.RateLimitError("GPT 호출 실패: 사용량 초과 및 재시도 실패")
