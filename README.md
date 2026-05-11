# InsightShelf Mobile

InsightShelf Mobile is a Flutter mobile reading app for already purchased books. It reads PDF files from `assets/purchased_books/`, builds the library catalog from that folder, parses books into readable mobile pages, persists reader data in a local JSON backend store, and sends selected text to a local Ollama model for AI reading help.

This is still a coursework/portfolio app, not a legal App Store bundle for redistributing the included commercial PDF. Before publishing publicly, replace the bundled PDF with content you own or load books from your own authenticated backend.

## What Works

- Email/password login flow with session state.
- Purchased library screen built dynamically from `assets/purchased_books/`.
- Book details with PDF metadata, progress, and offline download action.
- Runtime PDF text extraction using `syncfusion_flutter_pdf`.
- Reader with parsed PDF pages, selectable text, paging, progress saving, search, bookmarks, highlights, notes, reader preferences, and dark mode.
- JSON-backed local backend for downloaded-book state, progress, bookmarks, highlights, notes, generated insights, and pending sync actions.
- Offline mode: books must be downloaded before they can be opened while offline; local reading edits are queued for sync.
- Local AI generation through Ollama instead of fake generated text.
- Settings screen for Ollama endpoint/model and a test button.
- Cubit-based state management with `AuthCubit`, `LibraryCubit`, and `ReaderCubit`.
- Repository/data layer with async operations, loading states, error handling, and separation from UI code.

Bundled local books:

- `assets/purchased_books/Kafka_Streams_in_Action,_Second_Edition.pdf`
- `assets/purchased_books/Grokking_Streaming_Systems.pdf`
- `assets/purchased_books/Designing Software Architecture-2nd-Edition.pdf`
- `assets/purchased_books/Streaming_Data_Pipelines_with_Kafka_v6_MEAP.pdf`

To add another purchased PDF, place it in `assets/purchased_books/` and run `flutter pub get`. The app discovers it through Flutter's asset manifest and extracts title/page metadata from the PDF.

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

- `PurchasedBooksCatalog`: discovers purchased PDFs from `assets/purchased_books/` and extracts metadata.
- `ReaderBackendStore`: persists reader/backend state to `insightshelf_backend.json` in the app support directory.
- `LocalInsightShelfBackend`: local backend facade over the purchased-book catalog, reader store, PDF parser, and Ollama client.
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
| Data layer | Dynamic PDF catalog, JSON-backed backend store, async repository/API layer, PDF parsing, Ollama API calls, CRUD actions, loading/error states, offline queue. |
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
- Production sync service replacing the local JSON backend if multi-device sync is required.
- Production app icon, screenshots, privacy policy, signing, and store metadata.
