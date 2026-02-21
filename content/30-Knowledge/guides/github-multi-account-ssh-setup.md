---
title: GitHub 멀티 계정 SSH 설정
type: guide
created: '2026-02-09'
tags:
  - github
  - ssh
  - git
  - multi-account
  - devops

---
# GitHub 멀티 계정 SSH 설정

## 개요
개인 계정과 회사 계정을 SSH 키로 분리하여, 디렉토리 기반으로 자동 전환되도록 설정.

## 계정 정보

| 구분 | 계정 | 이메일 | SSH 키 |
|------|------|--------|--------|
| 개인 | `thumbsu` | `uumj222@gmail.com` | `~/.ssh/id_ed25519` |
| 회사 | `lu1ee` | `lulee@tappytoon.com` | `~/.ssh/id_ed25519_work` |

## 설정 파일

### `~/.ssh/config`
- `github.com` → 개인 키 (기본)
- `github.com-work` → 회사 키 (Host alias)

### `~/.gitconfig`
- 개인 정보 (기본)
- `includeIf "gitdir:~/work/"` → `~/.gitconfig-work` 로드

### `~/.gitconfig-work`
- 회사 user 정보
- URL 리라이트: `git@github.com:` → `git@github.com-work:` 자동 변환

## 동작 원리
- `~/work/` 안의 git repo → 회사 계정 자동 적용
- `~/projects/` 등 다른 경로 → 개인 계정 사용
- `~/work/`에서 `git clone git@github.com:org/repo.git` → URL 리라이트로 회사 SSH 키 자동 사용

## 검증
```bash
ssh -T git@github.com        # → Hi thumbsu!
ssh -T git@github.com-work   # → Hi lu1ee!
git -C ~/work/repo config user.email  # → lulee@tappytoon.com
```

## 설정일: 2026-02-09
