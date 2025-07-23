from db import get_db_connection

try:
    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("SELECT NOW() AS time;")
        result = cursor.fetchone()
        print("✅ DB 연결 성공:", result["time"])
    conn.close()
except Exception as e:
    print("❌ DB 연결 실패:", str(e))