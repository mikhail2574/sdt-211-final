# InsightShelf Mobile

InsightShelf Mobile is a Flutter mobile reading app for already purchased books. It now uses the real PDFs placed in the project root, parses them into readable mobile pages, supports offline download state, and sends selected text to a local Ollama model for AI reading help.

This is still a coursework/portfolio app, not a legal App Store bundle for redistributing the included commercial PDF. Before publishing publicly, replace the bundled PDF with content you own or load books from your own authenticated backend.

## What Works

- Email/password login flow with session state.
- Purchased library screen with the real PDF books from the project root.
- Book details with PDF metadata, progress, and offline download action.
- Runtime PDF text extraction using `syncfusion_flutter_pdf`.
- Reader with parsed PDF pages, selectable text, paging, progress saving, search, bookmarks, highlights, notes, reader preferences, and dark mode.
- Offline mode: books must be downloaded before they can be opened while offline; local reading edits are queued for sync.
- Local AI generation through Ollama instead of fake generated text.
- Settings screen for Ollama endpoint/model and a test button.
- Cubit-based state management with `AuthCubit`, `LibraryCubit`, and `ReaderCubit`.
- Repository/data layer with async operations, loading states, error handling, and separation from UI code.

Bundled local books:

- `Kafka_Streams_in_Action,_Second_Edition.pdf`
- `Grokking_Streaming_Systems.pdf`
- `Designing Software Architecture-2nd-Edition.pdf`
- `Streaming_Data_Pipelines_with_Kafka_v6_MEAP.pdf`

## Ollama Setup

Install and start Ollama on your laptop, then pull a small model:

```bash
ollama serve
ollama pull llama3.2:1b
```

Default app settings:

- Endpoint: `http://127.0.0.1:11434/api/generate`
- Model: `llama3.2:1b`

If you run on an Android emulator, use:

```text
http://10.0.2.2:11434/api/generate
```

If you run on a physical phone, use your laptop LAN IP, for example:

```text
http://192.168.1.20:11434/api/generate
```

Ollama must be reachable from the device. If generation fails, the app shows the actual connection/model error instead of silently returning mock content.

## Architecture

```text
lib/
  app.dart
  main.dart
  core/
    theme/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    library/
      data/
      domain/
      presentation/
    reader/
      data/
      domain/
      presentation/
```

Key classes:

- `MockInsightShelfApi`: simulates the existing bookstore backend and local offline cache.
- `PdfBookParser`: extracts text from the bundled PDF into reader pages.
- `OllamaInsightClient`: calls Ollama `/api/generate`.
- `LibraryRepository`: keeps UI code independent from data/API details.
- `ReaderCubit`: controls reader state, progress, notes, highlights, bookmarks, search, preferences, and AI generation.

## Course Requirements Coverage

| Requirement | Implementation |
| --- | --- |
| Project concept and scope | Mobile companion reader for purchased technical books. |
| UI and UX design | Login, library, details, reader, settings/sync, modals for search/preferences/notes. |
| State management | `flutter_bloc` Cubits with immutable state objects. |
| Data layer | Async repository/API layer, PDF parsing, Ollama API calls, CRUD actions, loading/error states, offline queue. |
| Documentation | This README explains setup, architecture, Ollama, and limitations. |
| Code quality | Feature-based folders, entities, repositories, Cubits, reusable widgets, tests, and analyzer-clean code. |

## Setup

```bash
flutter pub get
flutter run
```

Demo login:

- Email: `reader@insightshelf.dev`
- Password: `demo1234`

Run checks:

```bash
flutter analyze
flutter test
```

## App Store Notes

This project compiles for mobile, but App Store release still needs:

- Real backend authentication and purchased-book API.
- Secure token storage.
- Legal rights to distribute any bundled books.
- Persistent local storage for downloaded books and annotations.
- Production app icon, screenshots, privacy policy, signing, and store metadata.
