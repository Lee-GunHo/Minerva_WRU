# Minerva WRU — 딥보이스 보이스피싱 방지 앱

> 통화 음성을 실시간으로 받아 적고, LLaMA 문맥 분석·위험 키워드·음성 특징을 결합해 보이스피싱 위험도를 계산하고 경고하는 연구 프로젝트

![Python](https://img.shields.io/badge/Python-3.13-3776AB)
![Whisper](https://img.shields.io/badge/STT-Whisper-black)
![LLaMA](https://img.shields.io/badge/LLM-LLaMA%202%20(Ollama)-blueviolet)
![Flutter](https://img.shields.io/badge/App-Flutter-02569B)

🏆 **학부 우수논문 장려상** — 2026년도 한국통신학회 동계종합학술발표회
📄 이건호 외, 「Whisper와 LLaMA 기반 딥보이스 보이스피싱 방지 앱」 (제1저자)

---

## 연구 배경

생성형 음성 기술로 실제 사람의 목소리를 흉내 낸 딥보이스가 보이스피싱에 쓰일 위험이 커지고 있습니다. 위험 단어가 들어 있는지만 보는 키워드 탐지로는 자연스러운 대화 속 위협의 **문맥**과 **음성의 특징**을 함께 판단하기 어렵습니다. 이 프로젝트는 음성 인식, 언어 모델의 문맥 분석, 규칙 기반 점수, 음성 특징을 하나의 흐름으로 묶었습니다.

## 처리 흐름

```
마이크 입력 (16kHz, 모노)
   │  2초 단위로 잘라 임시 WAV 저장
   ▼
Whisper (base, 한국어) ── 텍스트 변환, 문장 누적
   │
   ├─ 최근 3문장 ── 위험 키워드 포함 시 즉시 경고 [RULE]
   │
   ▼
LLaMA 2 (Ollama) ── 누적 대화 전체의 보이스피싱 위험 점수와 이유
   │
   ▼
키워드 보정 ── LLM 점수 구간에 따라 키워드 가중치를 다르게 적용
   │
   ▼
음성 특징 보정 ── ZCR · Spectral Centroid (librosa)
   │
   ├─ SQLite 로그 저장 (텍스트, 점수, ZCR, SC)
   ├─ 대시보드 갱신 (tkinter)
   └─ 위험 점수 100 → 경고 알림
```

## 핵심 설계

### 1. LLM 점수에 따라 달라지는 키워드 가중치

키워드만 세면 일상 대화도 위험하다고 판단할 수 있어서, LLaMA의 문맥 점수를 먼저 보고 키워드 반영 정도를 정했습니다.

| LLaMA 점수 | 키워드 처리 |
|---|---|
| 30 미만 | 일상 대화로 보고 키워드 점수 제외 |
| 30 ~ 59 | 키워드 1개당 +2 (약하게 반영) |
| 60 이상 | 키워드 1개당 +5 |

### 2. 음성 특징으로 합성음 의심도 보정

`librosa`로 영교차율(ZCR)과 스펙트럼 중심(Spectral Centroid)을 구해 점수를 보정합니다.

| 조건 | 보정 | 해석 |
|---|---|---|
| ZCR < 0.07, SC > 2300 | +30 | AI 합성음 의심 |
| ZCR < 0.08, SC < 1600 | −20 | 자연 음성 |
| ZCR > 0.14 또는 SC > 2500 | +20 | 기계음 감지 |

### 3. 두 단계 경고

- **빠른 경고:** 최근 3문장에 위험 키워드(계좌, 송금, 인증번호 등)가 나오면 LLM 분석을 기다리지 않고 바로 알립니다
- **종합 경고:** 문맥·키워드·음성 특징을 모두 반영한 점수가 100에 이르면 경고합니다

### 4. 기록과 확인

분석 결과(문장, 점수, ZCR, SC)를 SQLite에 저장하고, 대시보드에서 최근 문장·위험 점수·분석 시각을 확인합니다. 위험 경고는 경고 창(`messagebox`)으로 띄웁니다.

### 5. Flutter 앱

`flutter_application_1/`은 전화 앱 형태의 화면(키패드, 최근 기록, 연락처, 메시지, 채팅방)과 로컬 SQLite DB로 구성한 앱 인터페이스입니다. 메시지마다 위험 점수(`risk_score`)를 담을 수 있게 설계해, 분석 결과를 사용자에게 보여 줄 수 있도록 했습니다.

## 폴더 구조

```
Minerva_WRU/
├── main.py              실시간 음성 입력 → 분석 → 경고 전체 흐름
├── llama.py             Ollama LLaMA 점수, 키워드·음성 보정
├── audio_features.py    ZCR · Spectral Centroid
├── rules.py             키워드 개수 기반 위험도 (엑셀 키워드 목록 로드)
├── database.py          SQLite 로그
├── dashboard.py         tkinter 대시보드
├── alert.py             경고 알림
└── constants.py         샘플링 레이트, 청크 길이, 기본 키워드
flutter_application_1/   Flutter 앱 화면
```

## 실행 방법

1. Python 패키지를 설치합니다: `openai-whisper`, `sounddevice`, `soundfile`, `librosa`, `numpy`, `pandas`
2. [Ollama](https://ollama.com)를 설치하고 `ollama pull llama2`로 모델을 받습니다
3. `Minerva_WRU/` 폴더에서 `python main.py`를 실행하면 마이크 입력 분석과 대시보드가 시작됩니다

## 배운 점

- AI 모델의 출력 하나만 믿지 않고, 규칙 기반 판정과 음성 특징으로 보완하는 구조를 설계했습니다
- 연구 아이디어를 동작하는 코드로 만든 뒤, 문제 정의와 시스템 설계로 정리해 논문으로 발표하는 과정을 경험했습니다
