# peachtalk

다양한 캐릭터와 대화하는 AI챗 앱.

## 실행 방법

채팅 화면은 OpenAI Chat Completions API를 LangChain(`langchain`/`langchain_openai` 패키지)으로 호출합니다.
API 키는 코드에 하드코딩하지 않고, 실행 시 `OPENAI_API_KEY` 환경 변수 값을 `--dart-define`으로 앱에 전달합니다.
(모바일 앱은 PC의 OS 환경 변수를 직접 읽을 수 없어서, `--dart-define`이 데스크톱/모바일 모두에서 동작하는 유일한 방법입니다.)

```bash
# PowerShell
flutter run -d windows --dart-define=OPENAI_API_KEY=$env:OPENAI_API_KEY

# bash
flutter run -d windows --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY"
```

에뮬레이터/실기기에서 실행할 때도 `-d <device-id>`만 바꾸고 `--dart-define` 부분은 동일하게 붙입니다.
`OPENAI_API_KEY`가 비어 있으면 채팅 화면에 안내 문구가 뜨고 전송이 비활성화됩니다.

빌드(`flutter build ...`)할 때도 동일하게 `--dart-define=OPENAI_API_KEY=...`를 붙여야 합니다.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
