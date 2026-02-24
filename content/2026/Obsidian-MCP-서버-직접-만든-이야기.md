---
title: Obsidian MCP 서버 직접 만든 이야기
type: blog
created: 2026-02-21
tags:
  - mcp
  - obsidian
  - claude-code
  - typescript
  - cdp
source:
  - https://github.com/modelcontextprotocol/specification

---

# Obsidian MCP 서버 직접 만든 이야기

## 파일 읽기/쓰기로는 부족했습니다

Claude Code를 쓰면서 Obsidian vault를 지식 베이스로 활용하기 시작했습니다. 기술 가이드, 의사결정 기록, 트러블슈팅 로그 같은 것들을 노트로 쌓아두고, AI한테 "이전에 이거 어떻게 해결했더라?" 하고 물어보는 식이었거든요.

처음에는 다른 사람이 만든 Obsidian MCP 서버를 가져다 썼습니다. 파일을 읽고 쓰고 검색하는 기본적인 기능은 충분했어요. 근데 쓰다 보니 한계가 보이기 시작했습니다.

가장 답답했던 건 Obsidian이 이미 알고 있는 정보를 활용할 수 없다는 거였어요. Obsidian은 내부적으로 엄청난 양의 메타데이터를 캐싱해둡니다. 어떤 노트가 어떤 노트를 링크하는지, frontmatter에 뭐가 들어있는지, 태그 구조가 어떻게 되는지. 이런 걸 `metadataCache`라는 이름으로 다 들고 있거든요. 근데 파일 시스템만 건드리는 MCP 서버는 이걸 전혀 못 씁니다. 마크다운 파일을 직접 파싱해야 하고, 백링크 관계를 알아내려면 vault 전체를 뒤져야 해요. 비효율적인 거죠.

멀티 vault 지원도 문제였습니다. 저는 지식용 vault, 블로그용 vault, 시스템 로그용 vault를 따로 쓰는데, 기존 MCP 서버는 vault 하나당 서버 인스턴스 하나를 띄워야 했어요. 서버가 세 개씩 돌아가는 건 좀 과하다 싶었습니다.

그래서 직접 만들기로 했습니다.

## Electron이면 CDP가 됩니다

어떻게 접근할지 고민하다가 Figma MCP 서버를 보게 됐습니다. Figma 데스크톱 앱도 Electron 기반인데, 이 MCP 서버는 Chrome DevTools Protocol(CDP)로 Figma 내부에 접근하고 있었어요. JavaScript를 앱 안에 주입해서 내부 API를 호출하는 방식이었습니다.

그 순간 떠오른 거예요. Obsidian도 Electron 앱이잖아요.

CDP는 원래 Chrome 브라우저를 외부에서 제어하기 위한 프로토콜입니다. 개발자 도구에서 디버깅할 때 쓰는 그거예요. Electron 앱은 Chromium 기반이니까 같은 프로토콜을 쓸 수 있습니다. Obsidian을 `--remote-debugging-port=9222` 옵션으로 실행하면, 외부에서 WebSocket으로 연결해서 앱 내부의 JavaScript 컨텍스트에 접근할 수 있거든요.

이게 되면 `app.vault.read()`로 파일을 읽고, `app.metadataCache`로 캐싱된 메타데이터를 가져오고, `app.workspace`로 현재 열려있는 파일 목록까지 알 수 있습니다. 파일 시스템을 직접 건드리는 것과는 차원이 다른 수준의 접근이 가능해지는 셈이죠.

## 근데 Obsidian이 항상 켜져 있진 않잖아요

CDP 방식의 문제가 하나 있었습니다. Obsidian이 실행 중이어야 한다는 거예요. 당연한 얘기지만, 터미널에서 Claude Code를 쓰다가 노트를 참조하고 싶을 때 Obsidian이 꺼져있을 수도 있거든요. CDP 포트를 안 열어뒀을 수도 있고요.

그래서 hybrid 구조를 설계했습니다. CDP가 되면 CDP로, 안 되면 파일 시스템으로 자동 전환하는 방식이에요. 코드로 보면 이런 패턴입니다.

```typescript
private async withFallback<T>(
  operation: string,
  fn: (backend: Backend) => Promise<T>
) {
  if (this.cdpBackend) {
    try {
      return await fn(this.cdpBackend);
    } catch (error) {
      console.error(`CDP ${operation} failed, falling back to FS`);
    }
  }
  return fn(this.fsBackend);
}
```

매 요청마다 CDP를 먼저 시도하고, 실패하면 파일 시스템 백엔드로 넘어갑니다. Obsidian이 중간에 꺼져도 서비스가 끊기지 않아요. 다시 켜면 자동으로 CDP 연결이 복구됩니다.

이 패턴이 생각보다 잘 맞았어요. 실제로 쓰다 보면 Obsidian을 켜놨을 때와 껐을 때 기능 차이가 좀 있긴 합니다. 백링크 조회나 워크스페이스 상태 같은 건 CDP에서만 되니까요. 근데 노트 읽기/쓰기/검색 같은 핵심 기능은 어느 쪽이든 동일하게 동작합니다. 사용하는 입장에서는 대부분의 경우 차이를 못 느끼더라고요.

## 백엔드 세 개, 인터페이스 하나

내부 구조를 좀 더 풀어보면 이렇습니다.

기본은 **파일 시스템 백엔드(FsBackend)** 입니다. Node.js의 파일 I/O를 씁니다. 마크다운 파싱은 `gray-matter` 라이브러리로 처리하고, frontmatter 추출이나 텍스트 검색을 직접 구현했어요. Obsidian 없이도 완전히 독립적으로 동작합니다.

**CDP 백엔드(CdpBackend)** 는 Obsidian의 내부 API를 직접 호출합니다. `chrome-remote-interface` 라이브러리로 CDP에 연결해서, `Runtime.evaluate`로 JavaScript를 Obsidian 안에서 실행하는 방식이에요. `app.vault`, `app.metadataCache`, `app.workspace` 같은 내부 객체에 접근할 수 있습니다. 파일 시스템 백엔드가 마크다운을 파싱해서 frontmatter를 추출하는 동안, CDP 백엔드는 Obsidian이 이미 파싱해둔 캐시를 그냥 가져다 씁니다.

**하이브리드 백엔드(HybridBackend)** 가 이 둘을 묶습니다. 위에서 본 `withFallback` 패턴으로 CDP를 우선 시도하고 파일 시스템으로 폴백하는 식이에요. 세 백엔드 모두 같은 `Backend` 인터페이스를 구현하니까, 상위 레이어에서는 어떤 백엔드가 실제로 동작하는지 신경 쓸 필요가 없습니다.

## vault 하나에 서버 하나? 서버 하나에 vault 전부

멀티 vault 지원은 처음부터 핵심 목표였습니다. 해결 방식은 이렇게 됐어요.

서버가 시작되면 Obsidian의 설정 파일(`obsidian.json`)을 읽어서 등록된 vault 목록을 자동으로 찾아냅니다. macOS라면 `~/Library/Application Support/obsidian/obsidian.json`에 있어요. 환경 변수(`OBSIDIAN_VAULTS`)로 수동 지정도 됩니다.

모든 MCP 도구에 `vault` 파라미터가 있어서, 호출할 때마다 어떤 vault를 대상으로 할지 지정합니다. vault가 하나뿐이면 파라미터를 생략해도 돼요. 자동으로 그 하나를 씁니다.

CDP 모드에서는 좀 더 복잡한 일이 벌어집니다. Obsidian은 vault마다 별도의 윈도우(프로세스)를 띄우거든요. CDP 타겟도 여러 개가 됩니다. 그래서 `TargetResolver`라는 걸 만들어서, 각 CDP 타겟에 `app.vault.getName()`을 실행해보고 vault 이름을 매칭합니다. vault 이름이 "second-brain"이면 그 이름을 반환하는 타겟이 second-brain vault의 윈도우인 거예요.

Health Monitor가 30초마다 이 매핑을 갱신합니다. Obsidian에서 vault를 열거나 닫으면 자동으로 감지됩니다.

## 20개 도구

최종적으로 도구가 20개가 됐습니다. 기본 도구 13개는 CDP든 파일 시스템이든 상관없이 동작합니다.

노트 읽기/쓰기/삭제/이동 같은 CRUD는 당연히 있고, `patch_note`로 노트 일부만 교체하는 것도 됩니다. `search_notes`는 정규식 검색을 지원하고, `read_multiple_notes`로 최대 10개 파일을 한 번에 읽을 수 있어요. frontmatter 조회/수정, 태그 관리, vault 통계까지요.

CDP 전용 도구가 7개 더 있습니다. 현재 열려있는 파일 목록(`get_open_files`), 워크스페이스 상태(`get_workspace_state`), 백링크 조회(`get_backlinks`), Obsidian 커맨드 실행(`execute_command`), 메타데이터 기반 검색(`search_metadata`), 설치된 플러그인 정보(`get_plugin_info`), 그리고 등록된 vault 목록(`list_vaults`)입니다.

백링크 조회가 특히 쓸모 있더라고요. "이 노트를 참조하는 다른 노트가 뭐가 있지?" 같은 질문에 바로 답할 수 있습니다. 파일 시스템만으로는 vault 전체를 스캔해야 하는 작업인데, Obsidian의 캐시를 쓰면 즉시 나옵니다.

## 보안은 신경 써야 했습니다

MCP 서버가 vault에 읽기/쓰기 권한을 갖는다는 건, 잘못하면 vault 밖의 파일에 접근하거나 시스템 파일을 건드릴 수 있다는 뜻입니다.

경로 순회(path traversal) 방어를 넣었습니다. 상대 경로를 풀었을 때 vault 루트 밖으로 나가면 차단합니다.

```typescript
const relativeToVault = relative(this.vaultPath, fullPath);
if (relativeToVault.startsWith('..')) {
  throw new Error(`Path traversal not allowed: ${relativePath}`);
}
```

`.obsidian/`, `.git/`, `node_modules/` 같은 시스템 폴더도 필터링합니다. 처리 가능한 파일 확장자도 `.md`, `.markdown`, `.txt`로 제한했습니다.

CDP 쪽에서는 코드 인젝션 방어가 중요했습니다. 외부에서 받은 파라미터를 JavaScript 코드 안에 넣어서 실행하는 구조니까, 파라미터를 반드시 `JSON.stringify`로 이스케이프합니다. 직접 문자열 결합은 하지 않습니다.

## 실제로 어떻게 쓰는가

설정은 간단합니다. Claude Code의 MCP 설정에 서버를 추가하면 됩니다.

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "obsidian-cdp-mcp"
    }
  }
}
```

CDP 기능을 쓰고 싶으면 Obsidian을 실행할 때 옵션을 하나 붙입니다.

```bash
open -a Obsidian --args --remote-debugging-port=9222
```

이러면 자동으로 CDP 모드가 활성화됩니다. 옵션 없이 Obsidian을 켜면 파일 시스템 모드로 동작하고요. 둘 다 안 켜놔도 됩니다. 파일만 있으면 기본 기능은 전부 됩니다.

저는 이걸 Claude Code 워크플로우의 지식 레이어로 쓰고 있습니다. 세션이 시작되면 AI가 vault에서 관련 노트를 찾아보고, 작업이 끝나면 배운 것을 노트로 정리합니다. 이전 세션에서 같은 문제를 해결한 적이 있으면 그 기록을 참조하고요. vault가 세 개(지식, 블로그, 시스템)인데 서버 하나로 전부 커버됩니다.

## 만들면서 배운 것들

**Electron 앱은 CDP로 열립니다.** 이건 Obsidian뿐 아니라 다른 Electron 앱에도 적용 가능한 패턴이에요. VS Code, Slack, Discord 같은 앱도 이론적으로는 같은 방식으로 내부 API에 접근할 수 있습니다. Figma MCP가 먼저 이 길을 열었고, 저는 Obsidian에 적용한 거예요.

**fallback 패턴은 생각보다 중요합니다.** CDP만 지원했으면 "Obsidian 안 켜놨는데요"라는 상황에서 서버가 완전히 무용지물이 됐을 겁니다. 파일 시스템 폴백이 있으니까 최소한의 기능은 항상 보장됩니다. 편의 기능이 아니라 필수 기능이었어요.

**MCP 서버 만드는 것 자체는 어렵지 않습니다.** `@modelcontextprotocol/sdk`가 프로토콜 처리를 다 해주니까, 실제로 신경 쓸 건 도구 정의와 비즈니스 로직뿐이에요. 도구 스키마 정의하고, 핸들러 연결하고, 결과 반환하면 됩니다. 진짜 어려웠던 건 CDP 연결 관리였어요. 타겟 매칭, 연결 끊김 감지, 자동 재연결 같은 부분에서 시간을 많이 썼습니다.

TypeScript와 `chrome-remote-interface` 라이브러리, 그리고 MCP SDK 세 가지 조합으로 만들었습니다. 의존성이 적은 편이라 유지보수 부담도 크지 않습니다.

아직 완벽하진 않습니다. 에러 메시지를 더 다듬어야 하고, 테스트 커버리지도 올려야 하거든요. 근데 일단 쓰는 데는 충분하고, 매일 실제로 쓰면서 개선하고 있습니다. 직접 만든 도구를 직접 쓰는 것만큼 좋은 피드백 루프는 없더라고요.

---

*obsidian-cdp-mcp는 MIT 라이선스로 공개되어 있습니다.*
- [Model Context Protocol](https://github.com/modelcontextprotocol/specification)
- [chrome-remote-interface](https://github.com/cyrus-and/chrome-remote-interface)
