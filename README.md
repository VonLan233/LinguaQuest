# LinguaQuest

<p align="center">
  <strong>词境星球 · A gamified Flutter language-learning app</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white"></a>
  <a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-brightgreen?logo=android&logoColor=white">
  <img alt="Backend" src="https://img.shields.io/badge/API-Dart%20Shelf-2F74C0">
  <img alt="Status" src="https://img.shields.io/badge/status-active%20prototype-orange">
</p>

LinguaQuest is a mobile-first English learning prototype that combines **Baicizhan-style visual vocabulary memory** with **Duolingo-style game progression**. It provides a complete learning loop: onboarding, goal setup, learning paths, short quizzes, mistake review, spaced repetition, custom word cards, quests, profile data, and an optional Dart API backend.

## Table of Contents

- [Highlights](#highlights)
- [Product Flow](#product-flow)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Run with Backend API](#run-with-backend-api)
- [Testing](#testing)
- [Build an Android APK](#build-an-android-apk)
- [API Endpoints](#api-endpoints)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

## Highlights

- **Gamified learning path** - lesson cards, XP rewards, streaks, progress states, and short practice sessions.
- **Visual vocabulary learning** - word cards with meanings, examples, difficulty tags, and image-memory oriented design.
- **Quiz and result loop** - lesson preview, quiz session, result summary, accuracy feedback, and mistake collection.
- **Review center** - spaced repetition utilities, due words, weak words, and a dedicated Mistake Book.
- **Custom word CRUD** - add, edit, view, delete, and review personal vocabulary cards.
- **Offline-first demo mode** - the Flutter app runs with mock repositories by default, so the full flow works without a server.
- **Cloud-ready API mode** - optional Dart `shelf` server with JWT auth, PostgreSQL persistence, custom words, study sessions, and review events.
- **Production-oriented UI** - Material 3 theme, dark mode support, shared cards, empty states, metrics, and mobile-friendly navigation.

## Product Flow

```text
Splash
  -> Onboarding
  -> Register / Login
  -> Goal Setup
  -> Home Dashboard
  -> Learning Path
  -> Lesson Preview
  -> Quiz Session
  -> Lesson Result
  -> Review Center / Mistake Book
  -> Wordbook / Custom Words
```

The target daily learning loop is simple: open the app, check today's task, complete a short lesson, review mistakes, earn XP, and return the next day for spaced review.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Mobile app | Flutter, Dart, Material 3 |
| State management | Riverpod |
| Navigation | GoRouter |
| HTTP client | Dio |
| Local persistence | SharedPreferences / mock repositories |
| Backend API | Dart `shelf`, `shelf_router` |
| Auth | JWT |
| Database | PostgreSQL |
| Deployment | Docker Compose, VPS deploy script |

## Project Structure

```text
.
├── LinguaQuest_Product_Blueprint.md   # Product planning blueprint
├── linguaquest/                       # Flutter mobile app
│   ├── lib/
│   │   ├── core/                      # Routing, theme, state, shared widgets, utilities
│   │   ├── data/                      # Models, repositories, API client, seed lessons
│   │   └── features/                  # Auth, home, learning, quiz, review, wordbook, quests, profile
│   └── test/                          # Flutter widget and unit tests
└── server/                            # Dart Shelf API server
    ├── bin/
    ├── lib/src/                       # Routes, database, auth, config, review policy
    ├── deploy/                        # VPS deployment helper
    └── test/
```

## Getting Started

### Prerequisites

- Flutter SDK with Dart `^3.11.4`
- Android Studio or Android SDK for emulator/device builds
- Docker and Docker Compose if you want to run the backend

### Run the Flutter app

The app runs in offline demo mode by default.

```bash
cd linguaquest
flutter pub get
flutter run
```

Offline demo mode uses mock repositories, so you can test the complete user journey without starting the backend.

## Run with Backend API

Start the API and PostgreSQL database:

```bash
cd server
docker compose up --build
```

Then run the Flutter app against the API:

```bash
cd ../linguaquest
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

> `10.0.2.2` is the Android emulator address for the host machine. Use your machine IP when testing on a physical Android device.

To run the Flutter app against the deployed API on `intro-server`:

```bash
cd linguaquest
flutter run --dart-define=API_BASE_URL=http://64.90.1.138:8080
```

## Testing

Run Flutter checks:

```bash
cd linguaquest
flutter analyze
flutter test
```

Run server tests:

```bash
cd server
dart test
```

## Build an Android APK

Build a release APK for group testing:

```bash
cd linguaquest
flutter build apk --release
```

Build a release APK that points at the deployed API on `intro-server`:

```bash
cd linguaquest
flutter build apk --release --dart-define=API_BASE_URL=http://64.90.1.138:8080
```

Output path:

```text
linguaquest/build/app/outputs/flutter-apk/app-release.apk
```

For a smaller device-specific package, split by ABI:

```bash
flutter build apk --release --split-per-abi
```

Most modern Android phones can use:

```text
linguaquest/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## API Endpoints

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/health` | Health check |
| `GET` | `/wordbooks` | List available wordbooks |
| `GET` | `/wordbooks/:id` | Get one wordbook with words |
| `GET` | `/words` | Search/list words by wordbook and query |
| `GET` | `/words/:id` | Get one word entry |
| `POST` | `/auth/register` | Register a learner |
| `POST` | `/auth/login` | Login and receive JWT |
| `GET` | `/me` | Get current profile |
| `PATCH` | `/me` | Update profile and learning goals |
| `GET` | `/lessons` | Fetch backend-owned lesson catalog |
| `GET` | `/learning-progress` | Fetch completed lessons, today's review, and claimed rewards |
| `POST` | `/reward-claims` | Claim a daily XP reward once per local day |
| `GET` | `/custom-words` | List custom words |
| `POST` | `/custom-words` | Create a custom word |
| `PATCH` | `/custom-words/:id` | Update a custom word |
| `DELETE` | `/custom-words/:id` | Delete a custom word |
| `POST` | `/study-sessions` | Record lesson completion |
| `GET` | `/study-plan` | Fetch the current learner study plan |
| `PUT` | `/study-plan` | Create or update the learner study plan |
| `POST` | `/study-plan/reset` | Reset the learner study plan |
| `GET` | `/review/due` | Fetch due review words |
| `POST` | `/review-events` | Record review outcome |

## Roadmap

- [x] Core Flutter navigation and learning loop
- [x] Redesigned mobile UI for onboarding, home, learning, quiz, review, wordbook, quests, and profile
- [x] Custom word CRUD
- [x] Mistake Book and review entry points
- [x] Android release APK build
- [ ] Add real screenshot assets to `docs/screenshots/`
- [ ] Add CI workflow for analyze/test/build checks
- [ ] Add signed release configuration for production APK/AAB distribution
- [ ] Expand backend coverage and deployment documentation
- [ ] Implement class mode, leaderboard, and AI tutor as full production flows

## Contributing

This is currently an academic/team project. For clean collaboration:

1. Create a feature branch from `main`.
2. Keep commits focused and reviewable.
3. Run `flutter analyze` and `flutter test` before opening a pull request.
4. Include screenshots or screen recordings for UI changes.
5. Document new environment variables in `.env.example`.

## License

No license file has been added yet. Add a license before public reuse or distribution outside the project team.
