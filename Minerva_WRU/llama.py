import subprocess

# 보이스피싱 여부 판단을 위한 프롬프트 템플릿
PROMPT_TEMPLATE = (
    "다음 문장이 보이스피싱과 관련 있는지 판단하고 위험도를 0~100점으로 숫자로만 출력해줘.\n"
    "- 반드시 전체 길이가 3문장 이상인 경우에만 판단해. 그보다 짧으면 0점 줘.\n"
    "- 단어 하나나 단문이면 판단하지 말고 0점 처리해.\n"
    "- 단순 인사, 친구 간 대화, 뉴스, 일반 대화: 0~30점\n"
    "- 모호한 요청, 신원 확인, 금융 관련 언급이 일부 포함된 경우: 40~60점\n"
    "- 계좌, 송금, 돈 요구, 개인정보 요구, 협박, 사칭 등이 문맥 안에서 분명할 경우: 70~100점\n"
    "- 반드시 숫자만 출력해. 설명이나 문장은 쓰지 마.\n"
    "- 무의미하거나 이상한 문장, 불완전한 문장일 경우에도 0점.\n"
    "문장: {text}"
)

# LLaMA2 분석
def score_with_llama(text):
    prompt = PROMPT_TEMPLATE.format(text=text)
    try:
        result = subprocess.run(["ollama", "run", "llama2", prompt],
                                capture_output=True, text=True, timeout=20, encoding='utf-8')
        
        stdout = result.stdout or ""

        score_str = stdout.strip().split("\n")[-1].strip()

        digits = ''.join(filter(str.isdigit, score_str))

        score = min(int(digits), 100) if digits else 0

        reason = "문맥 기반 위험 판단"
        if score == 0:
            reason = "단문 또는 비정상 문장"
        elif score <= 30:
            reason = "일반적인 대화"
        elif score <= 60:
            reason = "모호한 요청 또는 금융 언급"
        else:
            reason = "고위험 문맥 (금전/사칭 등)"

        return score, reason
    
    except Exception as e:
        print("[LLM 오류]", e)
        return 0, "판단 실패"

# 오디오 피처 기반 보정 + 이유 출력
def adjust_score_with_audio_verbose(score, zcr, sc):
    
    reason = []
    
    if isinstance(score, tuple):
        score = score[0]  # 튜플이면 첫 번째 요소 사용

    if zcr < 0.07 and sc > 2300:
        score = min(score + 30, 100)
        reason.append("AI 의심 (ZCR 낮고 SC 높음)")
    elif zcr < 0.08 and sc < 1600:
        score = max(score - 20, 0)
        reason.append("자연 음성 (ZCR 낮고 SC 낮음)")
    elif zcr > 0.14 or sc > 2500:
        score = min(score + 20, 100)
        reason.append("기계음 감지 (ZCR 높음 or SC 매우 높음)")
    else:
        reason.append("오디오 영향 없음")
    return score, reason

# 키워드 기반 점수 조정
def adjust_score_with_keywords(text, base_score, keywords):
    found = [kw for kw in keywords if kw in text]
    adjusted_score = base_score + 5 * len(found)
    adjusted_score = min(adjusted_score, 100)
    reason = "키워드 감지: " + ", ".join(found) if found else "키워드 없음"
    return adjusted_score, reason, found
