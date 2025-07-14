import sqlite3
from datetime import datetime

DB_NAME = "phishing_logs.db"

# DB 초기화
import sqlite3

def init_db():
    conn = sqlite3.connect("log.db")
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            text TEXT,
            score REAL,
            zcr REAL,
            sc REAL
        )
    ''')
    conn.commit()
    conn.close()
    
# 로그 저장
def save_log(text, score, zcr, sc):
    import sqlite3
    from datetime import datetime

    # 튜플이면 첫 번째 값만 사용하도록 변환
    if isinstance(score, tuple):
        score = score[0]
    if isinstance(zcr, tuple):
        zcr = zcr[0]
    if isinstance(sc, tuple):
        sc = sc[0]

    conn = sqlite3.connect("log.db")
    cursor = conn.cursor()
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    cursor.execute(
        "INSERT INTO logs (timestamp, text, score, zcr, sc) VALUES (?, ?, ?, ?, ?)",
        (timestamp, text, score, zcr, sc)
    )
    conn.commit()
    conn.close()
