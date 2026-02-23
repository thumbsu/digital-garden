---
title: "React Native Web에서 MSW 쓰려다 URL에 발목 잡힌 이야기"
type: blog
created: "2026-02-23"
tags: [msw, react-native-web, api-mocking, nextjs, troubleshooting]
source:
  - session-log

---

프론트엔드 개발하면서 가장 짜증나는 순간 중 하나가, 백엔드 API가 아직 안 나왔을 때다. 화면은 만들어야 하는데 데이터가 없으니 하드코딩하거나, 임시로 JSON 파일 만들어서 import하거나. 그러다 실제 API 연동하면 구조가 다르다든지 해서 또 고친다. 이 사이클이 너무 비효율적이라 API 모킹 시스템을 도입하기로 했다.

## 왜 MSW인가

API 모킹 도구는 꽤 많다. json-server 같은 가짜 서버를 띄우는 방법도 있고, axios 인터셉터를 쓰는 방법도 있다. 근데 MSW(Mock Service Worker)를 선택한 건 네트워크 레벨에서 요청을 가로채기 때문이다.

뭔 말이냐면, 앱 코드를 전혀 안 건드려도 된다는 거다. fetch든 axios든 어떤 HTTP 클라이언트를 쓰든, MSW가 브라우저의 Service Worker 레이어에서 요청을 잡아채서 가짜 응답을 돌려준다. 모킹 켜고 끄는 게 환경 변수 하나 차이라서, 프로덕션 코드에 if문 같은 게 안 들어간다. 깔끔하다.

근데 이게 "React Native Web + Next.js" 조합이 들어가면 이야기가 달라진다.

## 웹에서는 순조로웠다

프로젝트가 모노레포 구조라서, 모킹 로직을 공유 패키지로 만들었다. 핸들러(어떤 URL에 어떤 응답을 줄지)와 픽스처(가짜 데이터)를 한 곳에 모아두고, 웹이든 앱이든 가져다 쓰는 구조다.

웹 쪽(Next.js) 통합은 비교적 수월했다. CSR과 SSR 두 갈래로 나눠야 했는데:

**CSR (클라이언트 사이드)**: `_app.js`에서 useEffect로 모킹을 초기화한다. 브라우저에서 Service Worker를 등록하고, 이후 모든 fetch 요청을 가로챈다.

```javascript
useEffect(() => {
  if (Env.enableMocks) {
    const { setupMocks } = require('@lib/api-mock');
    setupMocks();
  }
}, []);
```

**SSR (서버 사이드)**: Next.js의 `instrumentation.ts`를 쓴다. 서버 런타임에서는 Service Worker가 없으니까, MSW의 Node.js용 서버를 띄워서 HTTP 요청을 인터셉트한다.

```typescript
export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { setupMockServer } = require('@lib/api-mock');
    setupMockServer();
  }
}
```

여기까지는 문서 읽고 따라하면 되는 수준이었다. 근데 진짜 삽질은 여기서부터 시작됐다.

## Service Worker가 i18n에 잡히다

Next.js로 다국어 지원을 하고 있었는데, Service Worker 파일 요청이 i18n 미들웨어에 잡혔다. 브라우저가 `/mockServiceWorker.js`를 요청하면, i18n이 이걸 `/en/mockServiceWorker.js`로 리다이렉트해버리는 거다. 당연히 404.

이건 솔직히 예상 못했다. Service Worker 등록 스크립트가 왜 로케일 라우팅 대상이 되는 건지. i18n 설정에서 해당 경로를 명시적으로 제외해야 했다.

```javascript
// next-i18next 설정
ignoreI18nRoutes: [
  '/mockServiceWorker.js',
]
```

한 줄 추가하면 해결되는 건데, 원인을 찾기까지가 좀 걸렸다. 브라우저 네트워크 탭에서 SW 등록이 실패하고, 콘솔에 별다른 에러도 안 뜨고, 그냥 조용히 모킹이 안 되는 상황이었다. "왜 안 되지?" 하고 한참 헤맸다.

## React Native로 넘어가니 URL이 터졌다

웹을 끝내고 React Native 쪽 통합을 시작했다. 같은 핸들러 패키지를 쓰니까 금방 되겠지 싶었는데, 실행하자마자 이런 에러가 떴다:

```
TypeError: URL.hostname is not implemented
```

처음엔 "뭔 소리지?" 싶었다. URL은 웹 표준 API고, React Native에도 있는데 왜 구현이 안 됐다는 건가.

파고 들어가보니 React Native의 URL 클래스가 불완전하다. `toString()`이랑 `href`는 되는데, `hostname`, `pathname`, `origin`, `protocol` 같은 getter들이 전부 "not implemented" 에러를 던진다. 자바스크립트 URL 객체의 껍데기만 있는 셈이다.

문제는 MSW 내부 코드가 `url.origin + url.pathname`으로 URL을 정규화한다는 거다. 브라우저에서는 당연히 되는 코드가, React Native에서는 터지는 것이다. MSW 입장에서도 "설마 URL.hostname이 안 되는 환경이 있겠어?"라고 생각했을 거다. 근데 있었다.

## URL.prototype 패치라는 우회로

MSW 소스를 직접 수정하는 건 옵션이 아니었다. 업데이트할 때마다 패치를 다시 해야 하니까. 대신 React Native의 URL.prototype을 패치하기로 했다.

아이디어는 간단하다. `toString()`은 되니까, 거기서 필요한 부분을 파싱해서 돌려주면 된다.

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

같은 방식으로 `pathname`, `origin`, `protocol`도 패치했다. 정규식으로 URL 문자열을 파싱하는 거라 좀 원시적이긴 한데, 동작한다.

한 가지 주의할 점은, getter에서 화살표 함수를 쓰면 안 된다는 거다. `this`가 URL 인스턴스를 가리켜야 하는데, 화살표 함수는 `this`를 바인딩하지 않으니까. ESLint가 화살표 함수 쓰라고 경고하지만, 이 경우는 `function` 문법이 맞다.

## 픽스처 있으면 목, 없으면 진짜 서버로

모킹 시스템을 쓸 때 불편한 점 하나가, 모킹을 켜면 모든 API가 가짜 데이터를 준다는 거다. 가끔은 특정 API만 모킹하고 나머지는 실제 서버를 쓰고 싶을 때가 있다.

MSW에는 `passthrough()`라는 기능이 있다. 핸들러 안에서 조건부로 "이 요청은 내가 안 잡을 테니 원래 서버로 보내"라고 할 수 있다.

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

이렇게 하면 픽스처 데이터가 있는 만화는 목 응답을 주고, 없는 건 실제 백엔드에서 가져온다. 개발 중에 새 API를 추가할 때 점진적으로 픽스처를 늘려가면 되니까 편하다.

참고로 MSW에는 `onUnhandledRequest: 'bypass'` 같은 서버 레벨 설정도 있다. 이건 핸들러가 아예 없는 URL에 대한 처리고, `passthrough()`는 핸들러 안에서 조건부로 쓰는 거다. 용도가 다르다.

## 핸들러 순서도 함정이 있다

MSW 핸들러는 위에서 아래로 매칭된다. 근데 URL 패턴에 파라미터가 있으면 순서가 중요하다.

```typescript
// 이 순서가 맞다
http.get('/api/comics/@:slug', slugHandler)
http.get('/api/comics/:id', idHandler)
```

`@:slug` 패턴을 `:id`보다 먼저 두지 않으면, `@my-comic-slug` 같은 요청이 `:id` 핸들러에 잡힌다. `:id`는 아무 문자열이나 매칭하니까. Express 라우터와 같은 원리인데, 막상 MSW에서 마주치면 "왜 슬러그 핸들러가 안 타지?" 하고 한참 디버깅하게 된다.

## 돌이켜보면

MSW 자체는 좋은 도구다. 네트워크 레벨 인터셉트라는 컨셉도 깔끔하고, API도 직관적이다. 근데 React Native Web처럼 "브라우저인 것 같으면서 아닌" 환경에서 쓰려면 예상 밖의 삽질을 각오해야 한다.

정리하면:

- **Next.js + i18n 환경**: Service Worker 파일이 로케일 라우팅에 잡힐 수 있다. 명시적으로 제외하자.
- **React Native의 URL 클래스는 불완전하다**: `hostname`, `pathname` 같은 기본 getter가 구현 안 돼 있다. MSW뿐 아니라 URL 속성에 의존하는 모든 라이브러리에서 문제가 될 수 있다.
- **CSR과 SSR은 초기화가 다르다**: 브라우저는 Service Worker, 서버는 MSW Server. 둘 다 세팅해야 풀커버리지.
- **passthrough() 패턴**: 모킹과 실제 API를 섞어 쓸 수 있어서, 점진적 도입에 좋다.
- **핸들러 순서 주의**: 구체적인 패턴을 먼저, 범용 패턴을 나중에.

React Native Web에서 MSW를 쓰려는 사람이 얼마나 될지 모르겠지만, 혹시 같은 상황이라면 URL.prototype 패치부터 준비하시길. 그게 제일 큰 벽이었다.
