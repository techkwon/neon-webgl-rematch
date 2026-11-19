# neon-webgl-rematch

Gemini 4 Neon(2026-11-19 공개)과 Gemini 4 Hydrogen, Claude Sonnet 5.5, GPT-6.2 Sol 네 모델에게 같은 프롬프트를 한 번씩만 주고 결과물을 만들게 한 재대결 자료입니다.

- 1부: 11편과 같은 WebGL2 프롬프트 5개
- 2부: 구글이 Neon 발표 때 보여 준 데모 3개를 다시 만든 과제(몽블랑 스키, 튜링의 연구실, 원소 실험대). 구글은 프롬프트를 공개하지 않아서 블로그 설명을 바탕으로 직접 썼습니다.

- 페이지: https://techkwon.github.io/neon-webgl-rematch/
- 영상: (공개 후 추가)
- 페이지의 모든 숫자는 `data.json`에서 읽어 옵니다.

## 들어 있는 것

| 경로 | 내용 |
| --- | --- |
| `index.html` | 자료 페이지 (외부 라이브러리 없음, `data.json`을 fetch로 읽음) |
| `data.json` | 모델·단가·라운드별 시간/크기/토큰/비용·점수·심사 이유·합계·실패한 시도·한계. 라운드마다 `part`(1 또는 2)가 있고, `parts[]`에 부별 합계, `totals`에 1부+2부 합계가 있습니다 |
| `runs/<라운드>/<모델>/index.html` | 모델이 만든 결과물 원본. 브라우저에서 바로 실행됩니다 |
| `video/<라운드>-<모델>.mp4` | 결과물 녹화본 (960px, 소리 없음) |
| `poster/<라운드>-<모델>.jpg` | 녹화본 마지막 화면 |
| `prompts/<라운드>.txt` | 라운드별 프롬프트 전문 |
| `judge/<라운드>/` | 이름을 가린 A~D 심사 시트(`sheet.jpg`), 정답표(`mapping.json`), 심사위원별 투표(`vote-*.json`) |
| `scripts/` | 실행·녹화·심사·비용 계산에 쓴 스크립트 (로컬 경로는 `~`로 바꿈) |

라운드 id: 1부 `water`, `globe`, `store`, `city`, `blackhole` / 2부 `ski`, `turing`, `labbench`
모델 id: `neon`, `hydrogen`, `sonnet`, `sol`

## 채점 방식

AI 심사위원 4명(= 참가 모델 넷)이 이름을 가린 A·B·C·D 캡처 시트(작품마다 6프레임)를 보고 1~4위를 매겼습니다. 1위 4점부터 4위 1점까지, 라운드당 최대 16점입니다. 자기 작품에 준 표를 뺀 합계는 `data.json`의 `totals.points_excluding_self`에 있습니다. 심사가 덜 끝난 상태로 만든 경우 `judging.missing`에 빠진 표가 적혀 있습니다.

## 한계

- 1부: Hydrogen과 Sonnet 결과물은 11편 실행(2026-11-13)을 다시 썼습니다. Neon과 Sol은 2026-11-19에 같은 프롬프트로 새로 돌렸습니다.
- 도구 조건이 다릅니다. Sol(Codex CLI)은 명령 실행과 자기 결과 스크린샷 확인이 가능했고 `~/.codex/AGENTS.md`를 읽습니다. Sonnet은 파일 도구(Write/Edit/Read)만, Neon·Hydrogen은 agy 기본 도구를 샌드박스에서 썼습니다.
- Neon은 두 번 실패한 뒤 재시도로 성공했습니다(번개 지구본: 1012초 뒤 네트워크 시간 초과, 쇼핑몰: "model not recognized" 오류, 토큰 0). 실패 비용은 `failed_attempts`에 따로 있습니다.
- Hydrogen 심사는 Gemini API 프로젝트가 월 지출 한도에 걸려 Neon과 같이 agy(Google 계정)로 했습니다.
- 비용은 토큰 수 × 공식 단가 추정값입니다(Sonnet은 Claude Code 보고값). Neon은 캐시 입력 단가 포함, Hydrogen은 11편 방식(캐시 단가 없음) 그대로입니다.
- 무거운 페이지 몇 개는 녹화에서 초당 프레임이 적게 잡혔습니다(Neon 블랙홀·쇼핑몰·물과 유리, Hydrogen 물과 유리).
- 2부 프롬프트는 구글 원문이 아니라 블로그 데모 설명을 바탕으로 직접 쓴 것입니다.
- Neon은 high 설정으로 돌렸습니다. 구글이 내세운 Neon 점수는 xhigh 기준입니다.
- 구글 시트 데모는 한 번에 만드는 웹 페이지가 아니라서 뺐습니다.
- 2부는 네 모델 모두 2026-11-20 같은 날 새로 돌렸습니다(재사용 없음, 도구는 1부와 같음, 실패한 시도 없음). 2부 비용은 `costs-neon-demo.json` 기준입니다.
- 2부 원소 실험대의 Neon 심사 투표는 agy가 빈 답을 여러 번 돌려줘서 몇 차례 다시 요청한 끝에 받았습니다.
- 과제마다 한 번씩만 실행했고, 심사는 정지 화면만 보고 했습니다.

## 로컬에서 보기

`data.json`을 fetch로 읽기 때문에 파일을 직접 열면 동작하지 않습니다. 이 폴더에서 간단한 웹 서버를 띄워서 보세요.

```sh
python3 -m http.server 8000
```
