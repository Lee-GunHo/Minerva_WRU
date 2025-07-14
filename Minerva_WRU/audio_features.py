import numpy as np
import librosa
import numpy as np
import librosa

def calculate_features(audio_data, sr):
    """
    오디오에서 ZCR(Zero Crossing Rate)과 Spectral Centroid를 계산
    """
    zcr = np.mean(librosa.feature.zero_crossing_rate(y=audio_data).T)
    sc = np.mean(librosa.feature.spectral_centroid(y=audio_data, sr=sr).T)
    return round(zcr, 4), round(sc, 2)


def calculate_features(file_path):
    try:
        y, sr = librosa.load(file_path, sr=None)
        zcr = float(np.mean(librosa.feature.zero_crossing_rate(y)))
        sc = float(np.mean(librosa.feature.spectral_centroid(y=y, sr=sr)))
        print(f"[AI 분석] ZCR: {zcr:.4f}, SC: {sc:.2f}")
        return zcr, sc
    except Exception as e:
        print("[오디오 특징 추출 오류]", e)
        return 0.1, 1800  # 중립값
    
def adjust_score_with_audio_verbose(score, zcr, sc):
    """
    ZCR (zero crossing rate), SC (spectral centroid)를 이용해 점수를 보정
    """
    audio_score = 0

    # ZCR 기반 점수 보정
    if zcr < 0.1:
        audio_score += 30
    elif zcr < 0.12:
        audio_score += 20
    elif zcr < 0.14:
        audio_score += 10

    # SC 기반 점수 보정
    if sc < 1800:
        audio_score += 30
    elif sc < 2000:
        audio_score += 20
    elif sc < 2200:
        audio_score += 10

    final_score = min(score + audio_score, 100)
    return final_score, f"ZCR: {zcr:.4f}, SC: {sc:.2f}, 보정점수: +{audio_score}"
