from collections import deque
import pandas as pd
from utils import load_keywords_from_excel

EXCEL_PATH = "keyword.xlsx"
MIN_SENTENCES = 3
KEYWORD_THRESHOLD = 3  # 위험도 100% 기준 키워드 수

def count_suspicious_keywords(text_list):
    keywords, negations = load_keywords_from_excel()
    count = 0

    for sentence in text_list:
        sentence_lower = sentence.lower()
        for keyword in keywords:
            if keyword.lower() in sentence_lower:
                # 부정어가 같이 있는지 확인
                if not any(neg.lower() in sentence_lower for neg in negations):
                    count += 1

    return count


# 키워드 엑셀 불러오기
def load_keywords_from_excel(path=EXCEL_PATH):
    try:
        df = pd.read_excel(path)
        keywords = []
        for col in df.columns:
            keywords.extend(df[col].dropna().astype(str).tolist())
        return list(set(keywords))  # 중복 제거
    except Exception as e:
        print(f"[에러] 키워드 엑셀 로딩 실패: {e}")
        return []

# 누적 문장 기반 보이스피싱 탐지 클래스
class SuspicionDetector:
    def __init__(self, min_sentences=MIN_SENTENCES):
        self.recent_sentences = deque(maxlen=min_sentences)
        self.keywords = load_keywords_from_excel()

    def add_sentence(self, text):
        self.recent_sentences.append(text)

    def is_ready(self):
        return len(self.recent_sentences) >= self.recent_sentences.maxlen

    def calculate_risk_score(self):
        if not self.is_ready():
            return 0

        combined_text = " ".join(self.recent_sentences).lower()
        hit_count = sum(
                1 for kw in self.keywords
                if isinstance(kw, str) and kw.lower() in combined_text
                )
        # 위험도 계산 (ex. 3개 이상 키워드면 100점)
        score = min(int((hit_count / KEYWORD_THRESHOLD) * 100), 100)
        return score
# rules.py

import pandas as pd

def load_keywords_from_excel(path):
    try:
        df = pd.read_excel(path)
        keywords = []
        for col in df.columns:
            for val in df[col].dropna():
                if isinstance(val, list):
                    # 리스트가 들어있는 경우 펼쳐서 추가
                    keywords.extend([str(v).strip() for v in val])
                else:
                    keywords.append(str(val).strip())
        return list(set(keywords))  # 중복 제거
    except Exception as e:
        print(f"[에러] 키워드 엑셀 로딩 실패: {e}")
        return []
    
def adjust_score_with_keywords(text, base_score, keyword_list):
    found = [kw for kw in keyword_list if kw in text]
    adjusted_score = base_score + 5 * len(found)
    adjusted_score = min(adjusted_score, 100)
    reason = "키워드 감지: " + ", ".join(found) if found else "키워드 없음"
    return adjusted_score, reason, found  # 세 개 반환