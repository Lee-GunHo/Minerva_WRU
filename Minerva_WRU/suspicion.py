import os
from collections import deque
from utils import load_keywords_from_excel

MIN_SENTENCES = 3
KEYWORD_THRESHOLD = 3

class SuspicionDetector:
    def __init__(self, min_sentences=MIN_SENTENCES):
        self.recent_sentences = deque(maxlen=min_sentences)

        # 경로 지정 (현재 폴더에 keyword.xlsx가 있는 경우)
        excel_path = os.path.join(os.path.dirname(__file__), 'keyword.xlsx')
        self.keywords = load_keywords_from_excel(excel_path)

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

        score = min(int((hit_count / KEYWORD_THRESHOLD) * 100), 100)
        return score