import re
from suspicion import SuspicionDetector
from rules import adjust_score_with_keywords
from audio_features import adjust_score_with_audio_verbose
from alert import alert_user
from llama import score_with_llama

# 초기화
detector = SuspicionDetector()
print("테스트용 문장을 입력하세요. (종료하려면 'exit' 입력)")

text_buffer = []

while True:
    text = input("입력 > ").strip()
    if text.lower() == "exit":
        print("종료합니다.")
        break
    if not text:
        continue

    # 문장 누적
    text_buffer.append(text)
    detector.add_sentence(text)

    
    # ✅ 전체 문장 기준으로 문맥 판단
    full_text = " ".join(text_buffer)

    # 1. LLaMA 문맥 점수
    llm_score, llm_reason = score_with_llama(full_text)

    # 2. 키워드 기반 점수 조정
    if llm_score < 30:
        score = llm_score
        reason_kw = "일상 문맥 - 키워드 점수 제외"
        found_keywords = []
    elif llm_score < 60:
        found_keywords = [kw for kw in detector.keywords if kw in full_text]
        score = min(llm_score + 2 * len(found_keywords), 100)
        reason_kw = "키워드 약하게 적용: " + ", ".join(found_keywords) if found_keywords else "키워드 없음"
    else:
        score, reason_kw, found_keywords = adjust_score_with_keywords(
            full_text, llm_score, detector.keywords
        )

    # 3. 오디오 피처 기반 보정 (모의 값 사용)
    score, reason_audio = adjust_score_with_audio_verbose(score, zcr=0.12, sc=1700)

    # 4. 결과 출력
    print(f"\n[ 분석 결과]")
    print(f"- 위험 점수: {score}")
    print(f"- 문맥 판단: {llm_reason}")
    print(f"- 키워드 근거: {reason_kw}")
    print(f"- 오디오(모의) 근거:")
    if isinstance(reason_audio, list):
        for i, reason in enumerate(reason_audio, 1):
            print(f"  {i}. {reason}")
    else:
    # 만약 문자열로 들어왔을 때 (예외적 방어코드)
        reasons = re.split(r'[\n,]', reason_audio)
        for i, reason in enumerate(filter(None, (r.strip() for r in reasons)), 1):
            print(f"  {i}. {reason}")

    # 5. 경고 발생
    alert_user(score)
    print("\n---\n")

