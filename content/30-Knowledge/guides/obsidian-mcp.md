---
tags:
  - mcp
  - obsidian
  - tools
created: '2026-02-09'

---
# Obsidian MCP 서버

> Obsidian vault에 AI가 직접 접근할 수 있게 해주는 MCP 서버 2종

현재 **2개의 Obsidian MCP**를 함께 사용 중:
1. **mcp-obsidian** (직접 파일 접근) - CRUD 전담
2. **obsidian-semantic** (시맨틱 검색) - 검색 전담

---

## 1. mcp-obsidian (@mauricio.wolff/mcp-obsidian)

### 개요
- **Repo**: https://github.com/bitbonsai/mcp-obsidian
- **패키지**: `@mauricio.wolff/mcp-obsidian`
- **특징**: 직접 vault 파일 접근, YAML frontmatter 보호, 토큰 최적화 응답 (40-60% 절약)

### 설치
```bash
claude mcp add obsidian -- npx @mauricio.wolff/mcp-obsidian@latest /path/to/vault
```

### 현재 설정
```
obsidian: npx @mauricio.wolff/mcp-obsidian@latest ~/GoogleDrive/Obsidian/second-brain
```

### 도구

| 도구 | 설명 |
|------|------|
| `read_note` | 노트 읽기 |
| `write_note` | 노트 작성 (overwrite/append/prepend) |
| `delete_note` | 노트 삭제 (경로 확인 필요) |
| `move_note` | 노트 이동 |
| `patch_note` | 노트 부분 수정 |
| `search_notes` | 텍스트 검색 |
| `list_directory` | 디렉토리 목록 |
| `get_notes_info` | 노트 메타정보 |
| `get_frontmatter` | Frontmatter 조회 |
| `update_frontmatter` | Frontmatter 수정 |
| `manage_tags` | 태그 관리 |
| `get_vault_stats` | Vault 통계 |

### 활용
- 노트 CRUD 작업
- 세션 로그 자동 기록
- Frontmatter 기반 노트 관리
- 디렉토리 구조 탐색

---

## 2. obsidian-semantic (Smart Connections MCP)

### 개요
- **Repo**: https://github.com/yejianye/ob-smart-connections-mcp
- **패키지**: `@yejianye/smart-connections-mcp`
- **의존**: Obsidian Smart Connections 플러그인의 임베딩 데이터 사용
- **데이터 소스**: `.smart-env/smart_sources.json` 또는 `.smart-env/multi/`

### 설치
```bash
claude mcp add obsidian-semantic -- npx -y @yejianye/smart-connections-mcp
```

### 현재 설정
```
obsidian-semantic: npx -y @yejianye/smart-connections-mcp
```

### 도구

| 도구 | 설명 |
|------|------|
| `connection` | 특정 노트와 의미적으로 유사한 노트 찾기 |
| `lookup` | 텍스트 쿼리로 시맨틱 검색 |
| `stats` | 임베딩 통계 및 vault 커버리지 |
| `validate` | 데이터 무결성 검증 |

### 활용
- 관련 노트 자동 발견
- 개념/주제 기반 광범위 검색
- 작업 시작 시 관련 과거 노트 탐색
- 지식 그래프 탐색

---

## 사용 전략

```
시맨틱 검색 (broad/conceptual)  →  obsidian-semantic의 lookup
직접 접근 (specific note)       →  obsidian의 read_note
텍스트 검색 (keyword)           →  obsidian의 search_notes
노트 작성/수정                   →  obsidian의 write_note/patch_note
```

### 전제 조건
- Obsidian Smart Connections 플러그인 설치 및 임베딩 완료 (semantic 사용 시)
- Vault 경로가 Google Drive 동기화 중이면 경로에 한글 포함 가능 (`내 드라이브`)

## 관련
- [[mcp-index]]
