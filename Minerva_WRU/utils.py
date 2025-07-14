import pandas as pd

EXCEL_PATH = "keyword.xlsx"

def load_keywords_from_excel(path):
    try:
        df = pd.read_excel(path)
        keywords = []
        for col in df.columns:
            for val in df[col].dropna():
                if isinstance(val, list):
                    keywords.extend(str(v).strip() for v in val)
                else:
                    keywords.append(str(val).strip())
        return list(set(keywords))  # 중복 제거
    except Exception as e:
        print(f"[에러] 키워드 엑셀 로딩 실패: {e}")
        return []