# 마음톡 (HeartTalk)

AI 기반 감정일기 챗봇 앱으로, 사용자의 감정 상태를 기록하고 위로와 조언을 제공하는 정신 건강 지원 서비스입니다.

Flutter로 개발된 모바일 앱과 Flask 기반 GPT 서버를 통해 실시간 감정 분석 및 기록이 가능합니다.

# 주요 기능

회원가입 / 로그인 (사용자 관리)
감정 일기 작성, 수정, 삭제 (emotion_diary 테이블과 연동)
GPT 기반 챗봇 상담 (Flask 서버 중계)

# 사용기술
- Flutter (Dart) – 클라이언트 앱
- Flask (Python) – 백엔드 서버
- GPT API – 감정 분석 및 위로 텍스트 생성
- MariaDB – 사용자데이터 저장
- 
# 기대효과 및 활용분야
“정신 건강 관리 접근성 향상, 데이터 기반 개인화된 감정 분석 제공”

# 시스템 구조도
Flutter 앱 ↔ Flask 서버 ↔ MariaDB ↔ GPT API 흐름