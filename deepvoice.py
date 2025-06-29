import sunggevice as sd #실시간 오디오 입출력 라이브러리
import numpy as np
import soundfile as sf
import whisper

samplerate = 16000  # 샘플링 레이트 (Hz)
duration = 1.0      # 감지 주기 (초)
threshold = 0.01    # 음성 감지 임계값 (볼륨)

def detect_voice(indata) :
    volume_norm = np.linalg.norm(indata)
    return volume_norm > threshold

print(" 마이크 감지 시작 (Ctrl + C로 종료") # Interrupt Signal을 보내는 유닉스 전통


try:
    while True:
        audio_data = sd.rec(int(duration * samplerate), samplerate=samplerate, channels=1, dtype='float32')
        #channels은 노모타입의 음성
        sd.wait()  # 녹음 완료 대기



        if detect_voice(audio_data):
            print("음성 감지됨 -> 텍스트로 변환")
            sf.write("detected.wav", audio_data, samplerate)
            #Whisper로 텍스트변환
            result = model.transcribe("detected.wav")
            text = result["text"]
            print("📝 변환된 텍스트:", text)
        else:
            print("🤫 무음 상태")
except KeyboardInterrupt:
    print("⏹️ 음성 감지 종료")