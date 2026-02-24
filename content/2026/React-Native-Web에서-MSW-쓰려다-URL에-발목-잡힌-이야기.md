---
title: React Native Web에서 MSW 쓰려다 URL에 발목 잡힌 이야기
type: blog
created: 2026-02-23
tags:
  - msw
  - react-native-web
  - api-mocking
  - nextjs
  - troubleshooting
source:
  - session-log

---

프론트엔드 개발하다 보면 꽤 자주 겪는 상황이 있습니다. 백엔드 API는 아직 준비가 안 됐는데 화면은 만들어야 하는 경우요. 그러면 하드코딩하거나, 임시 JSON 파일 만들어서 import하거나 하게 되는데, 나중에 실제 API 연동할 때 구조가 달라서 또 수정하는 사이클이 반복됩니다. 이게 너무 비효율적이라서 API 모킹 시스템을 제대로 도입해보기로 했습니다.

## 왜 MSW인가

API 모킹 도구 선택지는 꽤 있습니다. json-server 같은 가짜 서버를 띄우는 방법도 있고, axios 인터셉터를 활용하는 방법도 있고요. 그중에서 MSW(Mock Service Worker)를 고른 건 네트워크 레벨에서 요청을 가로채는 방식이기 때문입니다.

쉽게 말하면, 앱 코드를 건드릴 필요가 없다는 겁니다. fetch든 axios든 어떤 HTTP 클라이언트를 쓰든 상관없이, MSW가 브라우저의 Service Worker 레이어에서 요청을 잡아채 가짜 응답을 돌려줍니다. 모킹을 켜고 끄는 게 환경 변수 하나 차이라서, 프로덕션 코드에 분기 처리가 전혀 들어가지 않습니다. 꽤 깔끔한 구조입니다.

근데 이게 "React Native Web + Next.js" 조합이 들어가면 이야기가 좀 달라집니다.

## 웹에서는 순조로웠다

프로젝트가 모노레포 구조라서, 모킹 로직을 공유 패키지로 만들었습니다. 핸들러(어떤 URL에 어떤 응답을 줄지)와 픽스처(가짜 데이터)를 한 곳에 모아두고, 웹이든 앱이든 가져다 쓰는 구조입니다.

웹 쪽(Next.js) 통합은 비교적 수월했습니다. CSR과 SSR 두 갈래로 나눠서 처리해야 했는데요.

**CSR (클라이언트 사이드)**: `_app.js`에서 useEffect로 모킹을 초기화합니다. 브라우저에서 Service Worker를 등록하고, 이후 모든 fetch 요청을 가로채는 방식입니다.

```javascript
useEffect(() => {
  if (Env.enableMocks) {
    const { setupMocks } = require('@lib/api-mock');
    setupMocks();
  }
}, []);
```

**SSR (서버 사이드)**: Next.js의 `instrumentation.ts`를 씁니다. 서버 런타임에서는 Service Worker가 없으니까, MSW의 Node.js용 서버를 띄워서 HTTP 요청을 인터셉트하는 방식입니다.

```typescript
export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { setupMockServer } = require('@lib/api-mock');
    setupMockServer();
  }
}
```

여기까지는 공식 문서 읽고 따라하면 되는 수준이었습니다. 진짜 삽질은 여기서부터 시작됐습니다.

## Service Worker가 i18n에 잡히다

프로젝트에서 Next.js로 다국어 지원을 하고 있었는데, Service Worker 파일 요청이 i18n 미들웨어에 잡히는 문제가 있었습니다. 브라우저가 `/mockServiceWorker.js`를 요청하면, i18n이 이걸 `/en/mockServiceWorker.js`로 리다이렉트해버리는 거더라고요. 당연히 404가 납니다.

솔직히 처음엔 예상하지 못했습니다. Service Worker 등록 스크립트가 왜 로케일 라우팅 대상이 되는 건지. i18n 설정에서 해당 경로를 명시적으로 제외해줘야 했습니다.

```javascript
// next-i18next 설정
ignoreI18nRoutes: [
  '/mockServiceWorker.js',
]
```

한 줄 추가하면 해결되는 건데, 원인을 찾기까지가 좀 걸렸습니다. 브라우저 네트워크 탭에서 SW 등록이 실패하는데, 콘솔에 별다른 에러도 안 뜨고, 그냥 조용히 모킹이 안 되는 상황이었거든요. "왜 안 되지?" 하고 한참 헤맸습니다.

## React Native로 넘어가니 URL이 터졌다

웹을 끝내고 React Native 쪽 통합을 시작했습니다. 같은 핸들러 패키지를 쓰니까 금방 되겠다 싶었는데, 실행하자마자 이런 에러가 떴습니다.

```
TypeError: URL.hostname is not implemented
```

처음엔 "뭔 소리지?" 싶었습니다. URL은 웹 표준 API이고, React Native에도 있는데 왜 구현이 안 됐다는 건지.

파고 들어가보니 React Native의 URL 클래스가 불완전하더라고요. `toString()`이랑 `href`는 되는데, `hostname`, `pathname`, `origin`, `protocol` 같은 getter들이 전부 "not implemented" 에러를 던집니다. 자바스크립트 URL 객체의 껍데기만 있는 셈이죠.

문제는 MSW 내부 코드가 `url.origin + url.pathname`으로 URL을 정규화한다는 겁니다. 브라우저에서는 당연히 되는 코드가, React Native에서는 터지는 거였습니다. MSW 입장에서도 "설마 URL.hostname이 안 되는 환경이 있겠어?" 하고 생각했을 텐데, 있었던 겁니다.

## URL.prototype 패치라는 우회로

MSW 소스를 직접 수정하는 건 선택지가 아니었습니다. 업데이트할 때마다 패치를 다시 해야 하니까요. 대신 React Native의 URL.prototype을 패치하는 방향으로 갔습니다.

아이디어는 단순합니다. `toString()`은 되니까, 거기서 필요한 부분을 파싱해서 돌려주면 됩니다.

```typescript
Object.defineProperty(URL.prototype, 'hostname', {
  get() {
    const match = this.toString().match(
      /^https?:\/\/([^/:]+)/
    );
    return match ? match[1] : '';
  },
  configurable: true,
});
```

같은 방식으로 `pathname`, `origin`, `protocol`도 패치했습니다. 정규식으로 URL 문자열을 파싱하는 거라 원시적이긴 한데, 동작합니다.

한 가지 주의할 점은 getter에서 화살표 함수를 쓰면 안 된다는 겁니다. `this`가 URL 인스턴스를 가리켜야 하는데, 화살표 함수는 `this`를 바인딩하지 않으니까요. ESLint가 화살표 함수 쓰라고 경고할 수 있는데, 이 경우는 `function` 문법이 맞습니다.

## 픽스처 있으면 목, 없으면 진짜 서버로

모킹 시스템을 쓰다 보면 불편한 점이 있습니다. 모킹을 켜면 모든 API가 가짜 데이터를 준다는 건데요. 특정 API만 모킹하고 나머지는 실제 서버를 쓰고 싶을 때가 생깁니다.

MSW에는 `passthrough()`라는 기능이 있습니다. 핸들러 안에서 조건부로 "이 요청은 내가 안 잡을 테니 원래 서버로 보내"라고 할 수 있습니다.

```typescript
http.get('/api/comics/:id', ({ params }) => {
  const comic = fixtures.find(c => c.id === Number(params.id));
  
  if (comic) {
    return HttpResponse.json(comic);
  }
  
  // 픽스처에 없는 ID는 실제 서버로
  return passthrough();
});
```

이렇게 하면 픽스처 데이터가 있는 만화는 목 응답을 주고, 없는 건 실제 백엔드에서 가져옵니다. 개발 중에 새 API를 추가할 때 픽스처를 점진적으로 늘려가면 되니까 꽤 편리합니다.

참고로 MSW에는 `onUnhandledRequest: 'bypass'` 같은 서버 레벨 설정도 있는데, 이건 핸들러가 아예 없는 URL에 대한 처리입니다. `passthrough()`는 핸들러 안에서 조건부로 쓰는 거라 용도가 다릅니다.

## 핸들러 순서도 함정이 있다

MSW 핸들러는 위에서 아래로 매칭됩니다. URL 패턴에 파라미터가 있으면 순서가 중요한데요.

```typescript
// 이 순서가 맞습니다
http.get('/api/comics/@:slug', slugHandler)
http.get('/api/comics/:id', idHandler)
```

`@:slug` 패턴을 `:id`보다 먼저 두지 않으면, `@my-comic-slug` 같은 요청이 `:id` 핸들러에 잡힙니다. `:id`는 아무 문자열이나 매칭하거든요. Express 라우터와 같은 원리인데, 막상 MSW에서 마주치면 "왜 슬러그 핸들러가 안 타지?" 하고 한참 디버깅하게 됩니다.

## 돌이켜보면

MSW 자체는 확실히 좋은 도구입니다. 네트워크 레벨 인터셉트라는 컨셉도 깔끔하고, API도 직관적이고요. 근데 React Native Web처럼 "브라우저인 것 같으면서 아닌" 환경에서 쓰려면 예상 밖의 삽질을 각오해야 합니다.

정리하면 이렇습니다.

- **Next.js + i18n 환경**: Service Worker 파일이 로케일 라우팅에 잡힐 수 있습니다. 명시적으로 제외해줘야 합니다.
- **React Native의 URL 클래스는 불완전합니다**: `hostname`, `pathname` 같은 기본 getter가 구현이 안 돼 있습니다. MSW뿐 아니라 URL 속성에 의존하는 모든 라이브러리에서 문제가 될 수 있습니다.
- **CSR과 SSR은 초기화가 다릅니다**: 브라우저는 Service Worker, 서버는 MSW Server. 둘 다 세팅해야 풀커버리지입니다.
- **passthrough() 패턴**: 모킹과 실제 API를 섞어 쓸 수 있어서, 점진적 도입에 유용합니다.
- **핸들러 순서 주의**: 구체적인 패턴을 먼저, 범용 패턴을 나중에 두세요.

React Native Web에서 MSW를 쓰려는 경우가 얼마나 될지 모르겠지만, 혹시 같은 상황이라면 URL.prototype 패치부터 준비해두시길 권합니다. 그게 제일 큰 벽이었습니다.
