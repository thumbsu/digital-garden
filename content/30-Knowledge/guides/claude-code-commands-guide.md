---
tags:
  - claude-code
  - guide
  - dev-tools
created: '2026-02-10'

---
# Claude Code 커스텀 커맨드 가이드

Claude Code 슬래시 커맨드 레퍼런스. 글로벌 커맨드는 Obsidian vault에서 관리하고, 프로젝트 커맨드는 각 프로젝트의 `.claude/commands/`에 위치한다.

## 커맨드 구조

| 범위 | 경로 | 동기화 |
|------|------|--------|
| 글로벌 | `~/.claude/commands/` ← vault symlink | Google Drive로 머신 간 동기화 |
| 프로젝트 | `{project}/.claude/commands/` | Git으로 관리 |

- 파일명이 커맨드명 (예: `commit.md` → `/commit`)
- `$ARGUMENTS`로 사용자 입력 수신
- YAML frontmatter는 선택사항 (`allowed-tools` 등 설정 가능)

## 글로벌 커맨드 (vault 기반)

### /commit
- **용도**: Tappytoon 컨벤션에 맞는 git 커밋 생성
- **사용법**: `/commit [message]`
- **위치**: `99-System/claude-config/commands/commit.md`

### /pr
- **용도**: `gh` CLI로 draft PR 생성 (Tappytoon 컨벤션)
- **사용법**: `/pr [title]`
- **위치**: `99-System/claude-config/commands/pr.md`

### /code-review
- **용도**: 프론트엔드 코드 설계 관점 리뷰 (Pre-PR/PR)
- **사용법**: `/code-review`
- **위치**: `99-System/claude-config/commands/code-review.md`
- **참고**: `allowed-tools: [Read, Grep, Glob, Bash]` 제한

### /review-backend-pr
- **용도**: JVM 서비스 백엔드 PR을 설계/아키텍처 관점에서 리뷰
- **사용법**: `/review-backend-pr`
- **위치**: `99-System/claude-config/commands/review-backend-pr.md`
- **참고**: review-modules, review-examples 하위 리소스 포함

### /add-event-tracking
- **용도**: Tappytoon 이벤트 트래킹 추가 (local-rag + 코드 검색 하이브리드)
- **사용법**: `/add-event-tracking {이벤트명 또는 기능 설명}`
- **위치**: `99-System/claude-config/commands/add-event-tracking.md`
- **참고**: Phase 1(검색) → 2(계획) → 3(수정) 순서로 실행

## 프로젝트 커맨드 (tappytoon)

### /fix-coderabbit
- **용도**: CodeRabbit 리뷰 코멘트 자동 fetch 및 수정
- **사용법**: `/fix-coderabbit [pr-number]`
- **위치**: `tappytoon/.claude/commands/fix-coderabbit.md`
- **참고**: PR 번호 미입력 시 현재 브랜치에서 자동 감지, severity 순서대로 처리

## 새 커맨드 추가하기

1. `.md` 파일 생성 (파일명 = 커맨드명)
2. 글로벌: vault `99-System/claude-config/commands/`에 추가
3. 프로젝트: `{project}/.claude/commands/`에 추가
4. `$ARGUMENTS`로 사용자 입력 받기
5. `allowed-tools` frontmatter로 사용 가능 도구 제한 (선택)
