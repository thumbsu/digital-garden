---
tags:
  - claude-code
  - ai-tools
  - productivity
  - guide
source: >-
  https://docs.google.com/document/d/1BG06oNOqCbzUFWXKY0-vOWbBHXNnwyVQ-3AyHyjlPJw
author: Manus AI (based on ykdojo & Ado Kukic)
created: '2025-01-01'
aliases:
  - Claude Code 70 Tips
  - Claude Code 완전 가이드

---
# Claude Code 완전 가이드: 70가지 파워 팁

> [!info] 출처
> - **저자**: Manus AI
> - **기반 자료**: ykdojo (Anthropic 해커톤 우승자) & Ado Kukic (Anthropic DevRel)
> - ykdojo: 10억 토큰 이상 소비, 시스템 프롬프트 19k→10k 토큰 슬림화, 음성 코딩 시스템 구축
> - Ado: "Advent of Claude" 31일 챌린지 진행

---

## 목차

- [[#Part 1 에이전틱 개발자의 사고방식]]
- [[#Part 2 환경 설정과 필수 명령어]]
- [[#Part 3 생산성 핵심 기술]]
- [[#Part 4 컨텍스트 관리]]
- [[#Part 5 Git과 GitHub 워크플로우]]
- [[#Part 6 고급 기능 - MCP, Hooks, Agents]]
- [[#Part 7 시스템 최적화와 자동화]]
- [[#Part 8 컨테이너와 샌드박스]]
- [[#Part 9 브라우저 통합과 웹 자동화]]
- [[#Part 10 실전 활용 사례]]
- [[#Part 11 고급 패턴과 철학]]
- [[#Part 12 고급 기능과 SDK]]
- [[#Part 13 학습 로드맵]]
- [[#부록 치트시트]]

---

## Part 1: 에이전틱 개발자의 사고방식

### 1.1 분해하고 정복하라 (ykdojo #3)

> [!tip] 핵심
> 큰 문제를 잘게 쪼개는 능력이 AI 협업의 핵심. AI는 **명확하고 구체적인 지시**에서 최고 성능 발휘.

**잘못된 접근**: "로그인 페이지를 만들어줘"

**에이전틱 접근 (단계적)**:
1. DB 스키마 설계 (필드 명시)
2. ORM 마이그레이션 파일 생성
3. 로그인 폼 UI 컴포넌트 작성
4. API 엔드포인트 POST 요청 로직
5. 로그인 성공 시 토큰 저장 + 리다이렉트
6. 실패 시나리오 테스트 코드

```
단계적 경로 (성공 확률 높음): A → A1 → A2 → A3 → B
각 단계에서 검증 → 문제 시 해당 단계만 수정
```

### 1.2 계획 모드 vs. 욜로 모드 (Ado #18, #19)

| 모드 | 진입 방법 | 사용 시점 |
|------|-----------|-----------|
| **Plan Mode** | `Shift+Tab` × 2 | 복잡한 작업, 대규모 리팩토링, 아키텍처 변경 |
| **YOLO Mode** | `claude --dangerously-skip-permissions` | 간단한 작업, 프로토타입, **컨테이너 안에서만** |

> [!warning] Ado의 조언
> "90%의 시간 동안 계획 모드를 기본으로 사용합니다."

### 1.3 컨텍스트 관리의 핵심 (ykdojo #5, #8, Ado #15)

> [!quote] ykdojo
> "AI 컨텍스트는 우유와 같다. 신선하고 압축된 상태를 유지하는 것이 핵심."

- **컨텍스트 드리프트**: 여러 주제를 섞으면 성능 **39%까지 저하**
- **전략 1**: 단일 목적 대화 - 하나의 세션에서 하나의 목표만
- **전략 2**: 선제적 압축 - HANDOFF.md 작성 후 `/clear`
- **전략 3**: `/context`로 사용량 확인
- **전략 4**: 자동 압축 비활성화 → 수동 관리 (45k 토큰 예약 방지)

### 1.4 올바른 추상화 수준 선택 (ykdojo #32)

| 레벨 | 설명 | 적합한 상황 |
|------|------|-------------|
| **Vibe Coding** (높은 추상화) | 전체 구조/흐름만 | 프로토타입, 일회성 프로젝트 |
| **Deep Dive** (낮은 추상화) | 파일, 함수, 코드라인 검토 | 프로덕션, 보안, 디버깅, 성능 최적화 |

### 1.5 미지의 영역에서 더 용감하게 (ykdojo #35)

반복적 문제 해결 과정:
1. 초기 시도 → 작동하지 않음
2. 속도 조절: "천천히 가자. 이 줄이 정확히 무슨 의미인지 설명해줘"
3. 방향 전환: 막다른 골목이면 다른 접근
4. 깊이 조절: 추상화 수준 조정
5. 최종 해결

---

## Part 2: 환경 설정과 필수 명령어

### 2.1 커스텀 상태 라인 (ykdojo #0)

```
~/project (main*) | Tokens: 45k/200k | Opus 4.5 | MCP: 3 active
```

`~/.claude/settings.json`에서 설정:
```json
{
  "statusLine": {
    "format": "{{dir}} {{git}} | {{tokens}} | {{model}}",
    "updateInterval": 1000
  }
}
```

### 2.2 필수 슬래시 명령어

**Tier 1: 생존 필수**

| 명령어 | 설명 | 사용 시점 |
|--------|------|-----------|
| `/usage` | 토큰 사용량 + 리셋 시간 | 매 세션 시작, 대화 길어질 때 |
| `/clear` | 대화 초기화 | 컨텍스트 오염 시 |
| `/stats` | GitHub 스타일 활동 분석 | 주간 회고 |
| `/context` | 컨텍스트 윈도우 X-Ray | 성능 저하 시 |

**Tier 2: 생산성 향상**

| 명령어 | 설명 |
|--------|------|
| `/chrome` | 크롬 브라우저 통합 |
| `/mcp` | MCP 서버 관리 |
| `/permissions` | 승인된 명령어 관리 |
| `/export` | 대화 마크다운 내보내기 |

**! Prefix** (Ado #4): `!git status` → Claude 처리 없이 즉시 실행, 토큰 절약

### 2.3 CLAUDE.md (Ado #1, #2, ykdojo #30)

- `/init`으로 자동 생성
- 자연어로 업데이트: `"Update Claude.md: always use bun instead of npm"`

> [!tip] ykdojo의 조언
> "처음에는 CLAUDE.md 없이 시작하세요. 같은 말을 반복하게 되면 그때 추가하세요."

### 2.4 터미널 별칭 (ykdojo #7)

```bash
alias c='claude'
alias cc='claude --continue'
alias cr='claude --resume'
alias ch='claude --chrome'
```

### 2.5 세션 관리 (Ado #9-12)

| 기능 | 명령어 |
|------|--------|
| 마지막 세션 이어가기 | `claude --continue` |
| 세션 이름 붙이기 | `/rename auth-system-refactor` |
| 이름으로 재개 | `claude --resume auth-system-refactor` |
| 원격 세션 가져오기 | `claude --teleport <session_id>` |
| 대화 내보내기 | `/export` |

---

## Part 3: 생산성 핵심 기술

### 3.1 음성으로 코딩하기 (ykdojo #2)

타이핑 40 WPM vs 말하기 150 WPM = **3.75배 속도 차이**

| 도구 | 플랫폼 | 가격 |
|------|--------|------|
| superwhisper | macOS | $30 일회성 |
| MacWhisper | macOS | 무료/프리미엄 |
| ykdojo's Custom Tool | macOS | 오픈소스 |

### 3.2 터미널 출력 추출 (ykdojo #6)

- `pbcopy/pbpaste`로 클립보드 복사
- VS Code로 임시 파일 열기
- GitHub Desktop으로 변경사항 시각적 검토

### 3.3 키보드 단축키 (Ado #5-8, ykdojo #38)

| 단축키 | 기능 |
|--------|------|
| `Esc Esc` | 되감기 (Undo) |
| `Ctrl+R` | 역방향 검색 (프롬프트 히스토리) |
| `Ctrl+S` | 프롬프트 임시 저장 (Stash) |
| `Tab` / `Enter` | 프롬프트 제안 수락 |
| `Ctrl+G` | 외부 에디터에서 편집 |
| `Ctrl+B` | 백그라운드로 보내기 |

**입력 박스 탐색**: `Ctrl+A` (줄 시작), `Ctrl+E` (줄 끝), `Ctrl+W` (단어 삭제)

### 3.4 Vim 모드 (Ado #13)

`/vim`으로 활성화. `hjkl`, `w/b`, `dd`, `yy`, `p` 등 지원.

### 3.5 마크다운과 Notion 활용 (ykdojo #19, #20)

- 마크다운으로 구조화된 요청 → Claude가 더 정확히 이해
- Slack → Notion → Claude Code: 링크 보존 워크플로우

---

## Part 4: 컨텍스트 관리

### 4.1 HANDOFF.md 기법 (ykdojo #8)

```
1. /context로 사용량 확인 (50k+ 토큰 시)
2. HANDOFF.md 생성 요청 (시도/성공/실패/다음단계)
3. /clear
4. @HANDOFF.md 로드하여 작업 이어가기
```

### 4.2 터미널 탭 멀티태스킹 (ykdojo #14)

| 탭 | 용도 |
|----|------|
| 탭 1 | 메인 개발 작업 |
| 탭 2 | 버그 수정 |
| 탭 3 | 리서치 및 실험 |
| 탭 4 | DevOps 및 배포 |

> [!warning] 작업을 섞지 마세요
> 각 탭은 독립적인 '두뇌'. 한 탭에서 인증 작업 중 갑자기 UI 디자인 요청 → 혼란.

### 4.3 대화 복제 (ykdojo #23)

- `/clone`: 전체 복제 (A/B 비교 실험, 백업)
- `/half-clone`: 반복제 (컨텍스트 절반 줄이기)
- 설치: `claude plugin install dx@ykdojo`

### 4.4 /context X-Ray (Ado #15)

```
Context Usage: 87,432 / 200,000 tokens (43.7%)
- System Prompt: 10,234 (11.7%)
- MCP Servers: 15,678 (18.0%)
- Memory Files: 2,345 (2.7%)
- Conversation History: 57,941 (66.3%)
```

> [!tip] 최적 수치
> MCP 서버 **10개 미만**, 활성 도구 **80개 미만** 유지.

### 4.5 realpath로 절대 경로 (ykdojo #24)

```bash
!realpath ../../config/database.ts
# → /Users/ykdojo/projects/myapp/config/database.ts
```

---

## Part 5: Git과 GitHub 워크플로우

### 5.1 Git + GitHub CLI 활용 (ykdojo #4)

- 자동 커밋 메시지: `git diff` 분석 → 커밋 메시지 생성
- Draft PR 자동 생성: `gh pr create --draft`
- `.github/pull_request_template.md` 활용

### 5.2 Git Worktrees 병렬 작업 (ykdojo #16)

```bash
git worktree add ../myapp-feature-auth feature/auth
```

- 브랜치 전환 없이 병렬 작업
- node_modules 재설치 / 빌드 재실행 불필요

### 5.3 대화형 PR 리뷰 (ykdojo #26)

1. `gh pr checkout 123` → 변경사항 요약
2. 파일별 심층 리뷰 (보안/성능)
3. 테스트 커버리지 확인
4. 자동 수정 + 테스트 실행

### 5.4 승인된 명령어 감사 (ykdojo #33)

```bash
npm install -g cc-safe
npx cc-safe ~/projects  # 위험한 승인 명령어 스캔
```

감지 패턴: `sudo`, `rm -rf`, `chmod 777`, `curl | sh`, `git push --force` 등

---

## Part 6: 고급 기능 - MCP, Hooks, Agents

### 6.1 MCP (Ado #22-25)

```bash
# Playwright (브라우저 자동화)
claude mcp add -s user playwright npx @playwright/mcp@latest

# Supabase (DB 직접 쿼리)
claude mcp add -s user supabase npx @supabase/mcp@latest

# Firecrawl (웹 크롤링)
claude mcp add -s user firecrawl npx @firecrawl/mcp@latest
```

> [!warning] MCP 성능 최적화
> 활성 MCP가 많을수록 컨텍스트 소모 ↑. **10개 미만 서버, 80개 미만 도구** 유지.

### 6.2 Hooks (Ado #26)

| Hook | 실행 시점 | 사용 사례 |
|------|-----------|-----------|
| `PreToolUse` | 도구 실행 전 | 위험한 명령어 차단 |
| `PostToolUse` | 도구 실행 후 | 로그 기록, 알림 |
| `PermissionRequest` | 권한 요청 시 | 자동 승인/거부 |
| `Notification` | 알림 시 | 외부 시스템 통합 |
| `SubagentStart/Stop` | 서브에이전트 시작/종료 | 모니터링 |

> [!quote] Ado
> "Hooks는 AI에게 '가드레일'을 제공합니다. 확률적으로 실수할 수 있는 AI에게 절대적인 규칙을 강제."

### 6.3 Skills (Ado #27)

`~/.claude/skills/`에 `skill.md` 작성. Claude가 필요 시 자동 호출.

### 6.4 Agents (서브에이전트) (Ado #28)

- 각자 독립적인 200k 컨텍스트 윈도우
- 병렬 실행 가능
- 전문화된 시스템 프롬프트

### 6.5 Plugins (Ado #29)

Hooks + Skills + Agents + MCP를 하나의 패키지로 묶어 배포.

### 6.6 기능 비교 (ykdojo #25)

| 기능 | 로딩 시점 | 주요 사용자 | 토큰 효율 |
|------|-----------|-------------|-----------|
| CLAUDE.md | 모든 대화 시작 시 | 개발자 | 낮음 (항상 로드) |
| Skills | 필요 시 자동 | Claude | 높음 |
| Slash Commands | 수동 호출 시 | 개발자 | 높음 |
| Plugins | 설치 시 | 개발자 | - |

---

## Part 7: 시스템 최적화와 자동화

### 7.1 시스템 프롬프트 슬림화 (ykdojo #15)

- 19k → 10k 이하로 58개 패치 적용
- 장황한 예시, 반복 지시, 과도한 경고, 미사용 도구 설명 제거
- `git clone https://github.com/ykdojo/claude-code-tips.git`

> [!danger] 전문가의 영역
> 잘못 수정하면 Claude 성능 심각하게 저하. 충분한 이해 없이 시도하지 말 것.

### 7.2 수동 지수 백오프 (ykdojo #17)

장시간 작업 시: 1분 → 2분 → 4분 → 8분 간격으로 확인. 토큰 절약 + 병렬 작업 가능.

### 7.3 백그라운드 실행 (ykdojo #36)

- `Ctrl+B`: 실행 중인 명령어를 백그라운드로
- 서브에이전트 백그라운드 실행 → 병렬 모듈 분석

### 7.4 자동화의 자동화 (ykdojo #41)

자동화 진화 레벨:
```
L0: ChatGPT → 복사 → 터미널
L1: ChatGPT 플러그인으로 자동 실행
L2: Claude Code 터미널 통합
L3: 음성 전사 → 타이핑 자동화
L4: CLAUDE.md → 반복 지시 자동화
L5: 슬래시 명령어 → 워크플로우 자동화
L6: Skills → Claude 자동 판단
L7: Hooks → 규칙 강제 자동화
```

### 7.5 Headless 모드 CI/CD (Ado #30)

```bash
claude -p "Fix the lint errors"           # 기본
git diff | claude -p "Explain changes"    # 파이프
echo "Review this PR" | claude -p --json  # JSON 출력
```

GitHub Actions 통합으로 PR 자동 리뷰 가능.

---

## Part 8: 컨테이너와 샌드박스

### 8.1 컨테이너 격리 (ykdojo #21)

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl git tmux vim nodejs npm python3
RUN curl -fsSL https://claude.ai/install.sh | sh
WORKDIR /workspace
CMD ["/bin/bash"]
```

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  claude-sandbox
```

**고급**: 메인 Claude → tmux → 컨테이너 내 워커 Claude 오케스트레이션

### 8.2 Sandbox 모드 (Ado #20)

`/sandbox` → 자동 승인할 명령어 정의. 와일드카드 지원 (`mcp__server__*`)

### 8.3 YOLO 모드 주의사항

| 사용 OK | 절대 금지 |
|---------|----------|
| 컨테이너 안 실험 | 호스트 시스템 직접 실행 |
| 장시간 자율 작업 | 중요 데이터 디렉토리 |
| 신뢰할 수 있는 반복 작업 | 프로덕션 환경 |

---

## Part 9: 브라우저 통합과 웹 자동화

### 9.1 네이티브 브라우저 (Ado #21)

`claude --chrome` → 페이지 탐색, 버튼 클릭, 콘솔 에러 읽기, DOM 검사, 스크린샷

### 9.2 Playwright MCP (Ado #22)

헤드리스 브라우저, 다중 브라우저 지원, 네트워크 요청 가로채기, E2E 테스트 자동화

### 9.3 Gemini CLI 대체 수단 (ykdojo #11)

Claude로 접근 불가한 사이트 → Gemini CLI로 크롤링 → 결과를 Claude에게 반환

> [!tip] 멀티 모델 오케스트레이션
> Claude Code가 여러 AI 모델을 조율하는 중앙 인터페이스 역할

---

## Part 10: 실전 활용 사례

### 10.1 작성-테스트 사이클 (ykdojo #9)
코드 작성 → 테스트 작성 → 실행 → 실패 시 수정 → 통과까지 반복

### 10.2 커스텀 워크플로우 투자 (ykdojo #12)
- 음성 전사, 커스텀 상태 라인, 자동 커밋, GHA 디버거, HANDOFF.md 생성기

### 10.3 대화 기록 검색 (ykdojo #13)
```bash
claude -r                                    # 대화 목록
claude --resume stripe-integration          # 이름으로 재개
grep -r "Stripe" ~/.claude/conversations/   # 내용 검색
```

### 10.4 글쓰기 도우미 (ykdojo #18)
API 문서, 블로그 포스트, 튜토리얼 작성

### 10.5 연구 도구 (ykdojo #27)
GHA 디버깅, Reddit 감정 분석, 서비스 대체 가능성 조사 (ykdojo $10,000 절약 사례)

### 10.6 출력 검증 (ykdojo #28)
1. 테스트 코드 작성
2. GitHub Desktop 시각적 검토
3. Draft PR 생성
4. Claude에게 자기 검증 요청: "모든 주장을 검증하고 표로 정리해줘"

### 10.7 DevOps 엔지니어 (ykdojo #29)
`/dx:gha <url>` → GHA 실패 자동 조사, Docker 이미지 최적화

### 10.8 범용 인터페이스 (ykdojo #31)
비디오 편집 (ffmpeg), 오디오 전사 (Whisper), 디스크 정리

### 10.9 TDD (ykdojo #34)
실패하는 테스트 → 커밋 → 최소 구현 → 통과 확인 → 커밋

### 10.10 복잡한 코드 단순화 (ykdojo #40)
"이 코드가 너무 복잡해. 왜 이렇게 작성했는지 설명하고, 더 간단하게 바꿀 수 있는지 확인해줘"

---

## Part 11: 고급 패턴과 철학

### 11.1 계획과 프로토타이핑의 균형 (ykdojo #39)
두 가지 접근 방식을 빠르게 프로토타입으로 비교

### 11.2 개인화된 소프트웨어 시대 (ykdojo #37)
원하는 것이 있으면 Claude Code에게 만들어달라고 요청. 1-2시간 내 완성 가능.

### 11.3 사용이 최고의 학습 (ykdojo #22)

> [!quote] 10억 토큰 규칙
> "10,000시간 규칙" 대신 "10억 토큰 규칙". AI를 진정으로 이해하려면 많은 토큰을 소비하세요.

### 11.4 지식 공유 및 기여 (ykdojo #42)
공유 과정에서 새로운 것을 배움. Anthropic에 기능 요청/버그 리포트 기여.

### 11.5 계속 학습하기 (ykdojo #43)
- Claude에게 직접 물어보기
- `/release-notes`로 최신 기능 확인
- r/ClaudeAI 서브레딧
- Ado(@adocomplete) 팔로우

---

## Part 12: 고급 기능과 SDK

### 12.1 Extended Thinking (Ado #19)

`ultrathink:` 키워드 → 최대 32k 토큰 내부 추론 할당

```json
{ "thinking": { "maxTokens": 5000 } }
```

### 12.2 LSP 통합 (Ado #31)

즉시 진단, 코드 탐색 (정의/참조), 타입 정보. 수정 즉시 에러 감지.

### 12.3 Claude Agent SDK (Ado #31)

```javascript
import { query } from '@anthropic-ai/claude-agent-sdk';

for await (const msg of query({
  prompt: "Generate markdown API docs for all public functions in src/",
  options: {
    allowedTools: ["Read", "Write", "Glob"],
    permissionMode: "acceptEdits"
  }
})) {
  if (msg.type === 'result') console.log("Docs generated:", msg.result);
}
```

### 12.4 팀 설정 공유 (Ado #30)

`.claude/team-settings.json`에 permissions, hooks, mcpServers 정의 → 저장소에 커밋

---

## Part 13: 학습 로드맵

### 초급 (1-3개월)
| 주차 | 학습 내용 |
|------|-----------|
| 1주 | 설치 + 기본 명령어 (`/usage`, `/clear`, `/stats`) |
| 2주 | CLAUDE.md 작성, `/init` |
| 3-4주 | 컨텍스트 관리 기초, 단일 목적 대화 |
| 5-6주 | Git 통합 (자동 커밋, PR 생성) |
| 7-8주 | 터미널 별칭, 키보드 단축키 |
| 9-12주 | 음성 코딩, 커스텀 명령어 1개 |

### 중급 (3-12개월)
| 월 | 학습 내용 |
|----|-----------|
| 3-4월 | MCP 서버 연동 (Playwright/Supabase) |
| 5-6월 | Hooks 설정, 위험 명령어 차단 |
| 7-8월 | Skills + Slash Commands 제작 |
| 9-10월 | 컨테이너 워크플로우, YOLO 안전 사용 |
| 11-12월 | Subagents 활용, 병렬 작업 |

### 고급 (1년+)
| 분기 | 학습 내용 |
|------|-----------|
| Q1 | 시스템 프롬프트 분석 + 패치 |
| Q2 | 맞춤형 MCP 서버 개발 |
| Q3 | 멀티 에이전트 오케스트레이션 |
| Q4 | Claude Agent SDK → CI/CD 통합 |

---

## 부록: 치트시트

### 필수 명령어

| 명령어 | 설명 |
|--------|------|
| `/init` | CLAUDE.md 자동 생성 |
| `/usage` | 토큰 사용량 확인 |
| `/context` | 컨텍스트 사용 현황 |
| `/clear` | 대화 지우기 |
| `/stats` | 사용 통계 |
| `/clone` | 대화 복제 |
| `/half-clone` | 대화 반복제 |
| `/export` | 마크다운 내보내기 |
| `/sandbox` | 권한 경계 설정 |
| `/mcp` | MCP 서버 관리 |
| `/permissions` | 승인 명령어 관리 |
| `/vim` | Vim 모드 |
| `/release-notes` | 최신 릴리스 노트 |

### 키보드 단축키

| 단축키 | 기능 |
|--------|------|
| `!command` | Bash 즉시 실행 |
| `Esc Esc` | 되감기 |
| `Ctrl+R` | 역방향 검색 |
| `Ctrl+S` | 프롬프트 임시 저장 |
| `Shift+Tab` ×2 | Plan 모드 |
| `Alt+P` / `Option+P` | 모델 전환 |
| `Ctrl+O` | Verbose 모드 |
| `Tab` / `Enter` | 제안 수락 |
| `Ctrl+B` | 백그라운드 전환 |
| `Ctrl+G` | 외부 에디터 |

### CLI 플래그

| 플래그 | 설명 |
|--------|------|
| `-p "prompt"` | Headless 모드 |
| `--continue` | 마지막 세션 이어가기 |
| `--resume` | 세션 선택 |
| `--resume name` | 이름으로 재개 |
| `--teleport id` | 웹 세션 가져오기 |
| `--chrome` | Chrome 통합 |
| `--dangerously-skip-permissions` | YOLO 모드 |

---

## 참고 자료

- [Claude Code 공식 문서](https://code.claude.com/docs/en/overview)
- [Anthropic Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [ykdojo claude-code-tips](https://github.com/ykdojo/claude-code-tips)
- [Ado's Advent of Claude](https://adocomplete.com/advent-of-claude-2025/)
- [r/ClaudeAI](https://www.reddit.com/r/ClaudeAI/)

> [!quote] 맺음말
> "AI는 부조종사이고, 주인공은 당신입니다. 최종 결정, 창의적인 방향, 그리고 책임은 여전히 여러분의 몫입니다."
> — Happy Agentic Coding!


---

## 보충: 정리 시 축약된 실용 내용

### 3.3 Cmd+A/Ctrl+A 전체 선택의 힘 (ykdojo #10) — 누락 복원

웹 페이지/문서 내용을 빠르게 컨텍스트에 넣을 때 `Cmd+A`로 전체 선택 → 복사 → 붙여넣기.

**접근 막힌 웹사이트 우회 워크플로우:**
1. Gemini CLI로 웹사이트 접근
2. 가져온 내용을 `Cmd+A`로 전체 선택
3. Claude Code에 붙여넣기하여 분석

### 이미지 붙여넣기 단축키 (플랫폼별)

> [!warning] Mac에서 Cmd+V가 아님에 주의

| 플랫폼 | 단축키 |
|--------|--------|
| **Mac** | `Ctrl+V` (Cmd+V 아님!) |
| **Linux** | `Ctrl+V` |
| **Windows** | `Alt+V` |

### 여러 줄 입력 방법

- `\` 입력 후 `Enter` → 새 줄 생성
- `/terminal-setup`으로 터미널별 설정 확인
- Mac Terminal.app: `Option+Enter`

### Hooks JSON 설정 예시

**tmux 없이 장시간 명령어 경고:**
```json
{
  "hooks": {
    "PreToolUse": {
      "command": "bash",
      "args": ["-c", "if [[ $TOOL_NAME == 'Bash' ]] && [[ ! $TMUX ]]; then echo '⚠️ Warning: Long running command without tmux'; fi"]
    }
  }
}
```

**위험한 명령어 차단:**
```json
{
  "hooks": {
    "PreToolUse": {
      "command": "bash",
      "args": ["-c", "if echo $TOOL_INPUT | grep -q 'rm -rf /'; then echo 'BLOCKED: Dangerous command'; exit 1; fi"]
    }
  }
}
```

### HANDOFF.md 생성 프롬프트 (ykdojo 원문)

```
"Put the rest of the plan in the system-prompt-extraction folder as HANDOFF.md. 
Explain what you have tried, what worked, what didn't work, so that the next agent 
with fresh context is able to just load that file and nothing else to get started 
on this task and finish it up."
```

### GitHub Actions CI/CD 통합 예시 (Ado #30)

```yaml
name: Claude Code Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Claude Code
        run: curl -fsSL https://claude.ai/install.sh | sh
      - name: Review PR
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          git diff origin/main...HEAD | \
          claude -p "Review this PR and identify potential issues" \
          > review.md
      - name: Comment on PR
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: review
            });
```

### 추가 참고 자료

- [The Pragmatic Engineer - How Claude Code is built](https://newsletter.pragmaticengineer.com/p/how-claude-code-is-built) — Claude Code 내부 구조 분석
- [Lenny's Newsletter - Everyone should be using Claude Code](https://www.lennysnewsletter.com/p/everyone-should-be-using-claude-code) — 비개발자도 사용해야 하는 이유
- [Jacob's Tech Tavern](https://blog.jacobstechtavern.com/p/claude-code-productivity) — "50-100% 생산성 향상" 실전 사례
- [Reddit - Complete Guide to Claude Code v2](https://www.reddit.com/r/ClaudeAI/comments/1qcwckg/) — CLAUDE.md, MCP, 고급 기능

### 로드맵 성공 지표

**초급 달성 기준:**
- 모든 새 프로젝트에 `/init`으로 CLAUDE.md 생성
- 주 3회 이상 Claude Code 사용
- 간단한 버그 수정을 Claude에게 맡길 수 있음
- 컨텍스트 오염 인식하고 `/clear` 사용

**중급 달성 기준:**
- 생산성 50% 이상 향상 (자가 평가)
- MCP 서버 실무 활용 중
- 커스텀 명령어 5개 이상 보유
- 대화 복제 및 HANDOFF.md 자연스럽게 사용

**고급 달성 기준:**
- 시스템 프롬프트 안전하게 수정 가능
- 맞춤형 MCP 서버 또는 플러그인 개발 경험
- 팀 전체 Claude Code 도입 주도
- Anthropic에 기능 요청/버그 리포트 기여
