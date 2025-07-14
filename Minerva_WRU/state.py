# 대시보드에 전달할 최근 텍스트와 점수를 저장
latest_text = ""
latest_score = 0

def update_dashboard(text, score):
    global latest_text, latest_score
    latest_text = text
    latest_score = score

def get_latest():
    return latest_text, latest_score

