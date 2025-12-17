# Keymaps Cheat Sheet — macOS Notation (Command / Option / Shift)

> 단축키는 **Command / Option(Alt) / Shift** 표기로 통일했습니다.
> 기본 가정: `<leader>` = **Space**.

---

## 버퍼 / 파일 / 트리

- **Option+{** : 이전 버퍼
- **Option+}** : 다음 버퍼
- **Option+1** : 파일 트리 토글(Neo-tree)
- **Option+W** : 현재 버퍼 닫기
- **Option+Shift+W** : 현재 제외 좌/우 버퍼 닫기(Bufferline)
- **Option+Enter** : 아래에 빈 줄 추가(커서 유지)
- **Option+Backspace** : 현재 줄 삭제
- **Space+1..9** : N번째 버퍼로 이동(Bufferline)
- **Space+q** : 버퍼 닫기
- **Space+Q** : 현재만 남기고 전부 닫기

## 이동 / 선택 확장

- **w / b** : 스마트 토큰 이동(→ / ←)
- **W / B** : 스마트 토큰 이동 + 비주얼 확장
- **Option+H / Option+L** : 줄 시작 / 줄 끝 이동
- **Option+Shift+H / Option+Shift+L** : 줄 시작 / 줄 끝까지 선택 확장
- **H / J / K / L** : 비주얼 선택 확장(← / ↓ / ↑ / →)
- **m / ,** : `f/t` 반복 이전 / 다음
- **;** : 명령행 `:` 진입
- **%** : 매칭 괄호까지 비주얼 선택
- **Option+Shift+J / Option+Shift+K** : 현재 줄 아래 / 위로 스왑
- **Option+j / Option+k** : 반 페이지 스크롤(센터 유지)
- **Option+a** : 전체 선택

## LSP 기본

- **gd** : 정의로 이동 (Telescope 지원 시 미리보기)
- **gr** : 참조 찾기 (스마트: LSP → Telescope → ripgrep)
- **e** : Hover(심볼 정보)
- **Space+rn** : Rename symbol

## Code Action

- **Space+ca** : Code Action(미리보기)
- **Space+co** : Organize Imports(미리보기)

## 진단(에러/경고)

- **] d / \[ d** : 다음 / 이전 진단으로 이동 + 설명 팝업
- **g l** : 현재 커서 위치 진단 설명(이동 없음)
- **Space+dq** : 진단 Quickfix 열기

## 포맷팅 (Conform)

- **Space+f** : 포맷 — Normal: 파일 전체 / Visual: 선택 영역만

## 프로젝트 검색 (Telescope + ripgrep)

- **Space+ff** : 파일 찾기(루트 기준)
- **Space+sg** : 라이브 문자열 검색(루트, 숨김 포함·.git 제외)
- **Space+sw** : 커서 단어 검색(루트)

---

### In Termux

## FullScreen

**tfull** : 전체화면
**tunfull** : 전체화면 해제

**Ctrl + b + : ss** : 화면 세션 저장
**Ctrl + b + : ls** : 화면 세션 가져오기

### 참고

- 일부 키는 플러그인 의존: **Neo-tree**, **bufferline.nvim**, **telescope.nvim**, **telescope-ui-select.nvim**, **conform.nvim** 등.
- 세부 설정/코드는 리포지토리 설정 파일 참고.
