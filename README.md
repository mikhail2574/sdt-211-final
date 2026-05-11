# InsightShelf Mobile

InsightShelf Mobile is a Flutter mobile reader for users who already purchased books on a web bookstore. The app demonstrates a complete API-style architecture with authentication, a purchased library, offline reading behavior, progress sync, notes, highlights, bookmarks, search, configurable reader preferences, and AI-style reading support.

The repository is self-contained for coursework and portfolio review. Because no real backend credentials are included, the data layer uses a mock API client that behaves like a backend: every operation is asynchronous, failures are handled, offline mode blocks network-only actions, downloaded books remain readable, and local edits are queued for later sync.

## Course Requirements Coverage

| Requirement | Implementation |
| --- | --- |
| Project concept and scope | Companion mobile e-reader for purchased books with AI-enhanced study tools. |
| UI and UX design | Multi-screen Material 3 app: login, purchased library, book details, reader, search/preferences sheets, sync/account. |
| State management | `flutter_bloc` Cubits: `AuthCubit`, `LibraryCubit`, and `ReaderCubit`. |
| Data layer | Repository pattern over `MockInsightShelfApi`, async/await, try/catch, loading/error/empty states, CRUD actions, offline queue. |
| Documentation | This README explains purpose, setup, architecture, and feature coverage. |
| Code quality | Feature-based folders, entities, repositories, Cubits, reusable widgets, themed UI, and focused tests. |

## Features

- Login with session restoration through `AuthRepository`.
- Purchased-only book library with search, filters, cover cards, metadata, progress, format labels, and download status.
- Book detail screen with description, chapters, progress, and offline download action.
- Reader screen with scrolling text, chapter navigation, progress saving, selectable text, font size, line height, margins, dark theme, and business/fiction mode toggle.
- Bookmarks, highlights, and notes with create/delete behavior.
- Search inside the current book.
- Offline mode simulation: downloaded books open offline, network-only actions show errors, and local reading actions are queued.
- Sync screen showing connection state, pending action count, and account/logout.
- AI reading actions: summarize, visualize, explain simpler, and create action steps from selected paragraph text.
- Passive smart augmentation prompt for supported business/education reading mode.

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
      domain/
      presentation/
```

The app follows a layered, feature-based architecture:

- Presentation: Flutter screens, widgets, navigation, and Material theme.
- State: Cubits emit immutable state objects for authentication, library, and reader flows.
- Domain: entities such as `Book`, `BookChapter`, `ReadingPreferences`, `Bookmark`, `Highlight`, `Note`, and `InsightCard`.
- Data: repositories call the mock API client and isolate async data behavior from UI code.

## Setup

1. Install Flutter and open this folder.
2. Install packages:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

4. Run verification:

```bash
flutter analyze
flutter test
```

## Demo Login

The login screen is prefilled for fast testing:

- Email: `reader@insightshelf.dev`
- Password: `demo1234`

Any email containing `@` with a password of at least four characters is accepted by the mock API.

## Notes for Real App Store Release

This project is structured like a production client, but real App Store submission requires connecting the repository layer to a production backend, adding real secure token storage, real EPUB/PDF parsing, signed app identifiers, privacy policy URLs, store screenshots, app icons, and platform-specific release configuration.
