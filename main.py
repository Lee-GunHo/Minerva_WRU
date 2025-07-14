import sounddevice as sd
import soundfile as sf
import numpy as np
import whisper
import threading
import os
import queue
import tempfile
from datetime import datetime

from constants import *
from rules import count_suspicious_keywords
from audio_features import calculate_features
from llama import score_with_llama, adjust_score_with_audio_verbose, adjust_score_with_keywords
from database import init_db, save_log
from alert import alert_user
from dashboard import run_dashboard

model = whisper.load_model("base")
q = queue.Queue()
latest_text, latest_score = "", ""
latest_log_time = ""

# 문장 누적 버퍼
text_buffer = []

# 키워드 기반 감지
def check_rules(text):
    return any(keyword in text for keyword in SUSPICIOUS_KEYWORDS)

# 오디오 콜백
def audio_callback(indata, frames, time, status):
    if status:
        print("[오디오 상태]", status)
    q.put(indata.copy())

# 오디오 분석
def process_stream():
    buffer = np.empty((0, CHANNELS), dtype='int16')
    chunk_samples = int(RATE * CHUNK_DURATION)

    while True:
        chunk = q.get()
        buffer = np.concatenate((buffer, chunk), axis=0)

        if len(buffer) >= chunk_samples:
            data = buffer[:chunk_samples]
            buffer = buffer[chunk_samples:]

            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as f:
                wav_path = f.name
                sf.write(wav_path, data, RATE)

            try:
                result = model.transcribe(wav_path, language='ko')
                text = result.get("text", "").strip()
            except Exception as e:
                print("[Whisper 오류]", e)
                os.remove(wav_path)
                continue

            if not text:
                continue

            print("[텍스트]", text)
            text_buffer.append(text)

            if len(text_buffer) < 3:
                continue

            # 최근 3문장 기준 텍스트
            combined_text = " ".join(text_buffer[-3:])
            if check_rules(combined_text):
                alert_user("[RULE] 의심 키워드 탐지")

            # 전체 문장 기준 텍스트
            full_text = " ".join(text_buffer)

            try:
                # 전체 문장 기반 LLaMA 분석
                llm_score, llm_reason = score_with_llama(full_text)

                # 키워드 기반 점수 조정
                if llm_score < 30:
                    score = llm_score
                    reason_kw = "일상 문맥 - 키워드 점수 제외"
                    found_keywords = []
                elif llm_score < 60:
                    found_keywords = [kw for kw in SUSPICIOUS_KEYWORDS if kw in full_text]
                    score = min(llm_score + 2 * len(found_keywords), 100)
                    reason_kw = "키워드 약하게 적용: " + ", ".join(found_keywords) if found_keywords else "키워드 없음"
                else:
                    score, reason_kw, found_keywords = adjust_score_with_keywords(
                        full_text, llm_score, SUSPICIOUS_KEYWORDS
                    )

                # 오디오 특성 기반 보정
                zcr, sc = calculate_features(wav_path)
                score, audio_reason = adjust_score_with_audio_verbose(score, zcr, sc)

                # 로그 기록
                global latest_log_time
                latest_log_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                save_log(full_text, score, zcr, sc)

                # 대시보드 갱신
                update_dashboard(full_text, score)

                # 결과 출력
                print("\n[🔍 분석 결과]")
                print(f"- 위험 점수: {score}")
                print(f"- 문맥 판단: {llm_reason}")
                print(f"- 키워드 근거: {reason_kw}")
                print(f"- 오디오 근거: {audio_reason}")
                print(f"- 최근 3문장 기준: {combined_text}")
                print(f"- 전체 문장 기준: {full_text}")

                if score >= 100:
                    alert_user("[위험 감지] 전체 문장 기준 100%")

            except Exception as e:
                print("[분석 중 오류 발생]", e)

            os.remove(wav_path)

# 대시보드 값 전달
def update_dashboard(text, score):
    global latest_text, latest_score
    latest_text, latest_score = text, score

def get_latest():
    return latest_text, latest_score, latest_log_time

# 메인 실행
if __name__ == "__main__":
    init_db()
    threading.Thread(target=process_stream, daemon=True).start()
    with sd.InputStream(callback=audio_callback, channels=CHANNELS, samplerate=RATE, dtype='int16'):
        run_dashboard(get_latest)
