# LinguaQuest

<p align="center">
  <strong>词境星球 · A gamified Flutter language-learning app</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white"></a>
  <a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android-brightgreen?logo=android&logoColor=white">
  <img alt="Backend" src="https://img.shields.io/badge/API-Dart%20Shelf-2F74C0">
  <img alt="Status" src="https://img.shields.io/badge/status-active%20development-blue">
</p>

LinguaQuest is a mobile-first English learning app that combines **Baicizhan-style visual vocabulary memory** with **Duolingo-style game progression**. It uses a separated Flutter client and Dart API backend for onboarding, goal setup, word books, learning paths, quizzes, mistake review, spaced repetition, custom word cards, quests, and profile data.

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
- **Separated app/API runtime** - the Flutter app talks to the Dart `shelf` API by default; user data is persisted by the backend.
- **Cloud-ready API mode** - Dart `shelf` server with JWT auth, PostgreSQL persistence, word books, study plans, target word progress, custom words, study sessions, and review events.
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
| Local persistence | SharedPreferences for device settings and auth token only |
| Backend API | Dart `shelf`, `shelf_router` |
| Auth | JWT |
| Database | PostgreSQL |
| Deployment | Docker Compose, VPS deploy script |

## Project Structure

```text
.
├── LinguaQuest_PRD_Development_Guide.md # Product requirements and development guide
├── docs/
│   ├── development/                   # Development notes and research assets
│   └── reference/                     # Reference materials kept for future work
│       └── vocab_plans.zip            # Vocabulary plan source package
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
- Docker and Docker Compose for the backend database/API stack

### Run the backend

Start the API and PostgreSQL database first:

```bash
cd server
docker compose up --build
```

### Run the Flutter app

The Flutter app defaults to `http://127.0.0.1:8080` for desktop/web development.

```bash
cd linguaquest
flutter pub get
flutter run
```

For Android emulator testing, point the client at the host machine API:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

> `10.0.2.2` is the Android emulator address for the host machine. Use your machine IP when testing on a physical Android device.

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
| `POST` | `/auth/register` | Register a learner |
| `POST` | `/auth/login` | Login and receive JWT |
| `GET` | `/me` | Get current profile |
| `PATCH` | `/me` | Update profile and learning goals |
| `GET` | `/word-books` | List available word books and words |
| `GET` | `/study-plan` | Get the current learner study plan |
| `PUT` | `/study-plan` | Create or update the study plan |
| `DELETE` | `/study-plan` | Clear the study plan |
| `GET` | `/user-words` | List target word learning progress |
| `PUT` | `/user-words/:wordId` | Upsert target word learning progress |
| `GET` | `/custom-words` | List custom words |
| `POST` | `/custom-words` | Create a custom word |
| `PATCH` | `/custom-words/:id` | Update a custom word |
| `DELETE` | `/custom-words/:id` | Delete a custom word |
| `POST` | `/study-sessions` | Record lesson completion |
| `GET` | `/review/due` | Fetch due review words |
| `POST` | `/review-events` | Record review outcome |
| `GET` | `/activity/summary` | Sync today's learning counters |
| `GET` | `/classes` | List joined classes |
| `POST` | `/classes/join` | Join or create a class by code |
| `GET` | `/classes/progress` | Fetch class member, lesson, and weak-word progress |
| `GET` | `/rewards/tasks` | List claimable XP tasks |
| `POST` | `/rewards/claim` | Claim a reward task |
| `POST` | `/rewards/lottery` | Spend XP on a virtual lottery draw |
| `GET` | `/notifications` | List user notifications |
| `PATCH` | `/notifications/:id/read` | Mark a notification as read |
| `GET` | `/forum/posts` | List forum posts |
| `POST` | `/forum/posts` | Create a forum post |
| `GET` | `/forum/posts/:id` | Fetch a post with comments |
| `POST` | `/forum/posts/:id/comments` | Add a post comment |
| `POST` | `/forum/posts/:id/like` | Like or unlike a post |
| `GET` | `/ai/conversations` | List AI tutor conversations |
| `GET` | `/ai/conversations/:id` | Fetch AI conversation messages |
| `DELETE` | `/ai/conversations/:id` | Delete an AI conversation |
| `POST` | `/ai/complete` | Generate a backend AI tutor response |
| `GET` | `/analytics/summary` | Fetch learner analytics |
| `GET` | `/leaderboard` | Fetch XP leaderboard |
| `GET` | `/achievements` | List unlocked achievements |

## Roadmap

- [x] Core Flutter navigation and learning loop
- [x] Redesigned mobile UI for onboarding, home, learning, quiz, review, wordbook, quests, and profile
- [x] Custom word CRUD
- [x] Mistake Book and review entry points
- [x] Android release APK build
- [x] API-backed class mode, leaderboard, notifications, rewards, forum, analytics, and AI tutor routes
- [x] Training arena entries for speed challenge, gauntlet, spelling practice, and cloze-style timed sessions
- [x] Listening-word and listening-meaning timed quiz support in the training arena
- [x] Personal space with backend achievements and user forum posts
- [x] Server-side AI service layer with structured payloads, safety checks, and provider configuration
- [x] AI conversation history, message detail view, continuation, and server-side deletion
- [ ] Add real screenshot assets to `docs/screenshots/`
- [ ] Add CI workflow for analyze/test/build checks
- [ ] Add signed release configuration for production APK/AAB distribution
- [ ] Expand backend deployment documentation with production secrets, TLS, backups, and monitoring
- [ ] Connect production AI credentials and richer conversation management controls
- [ ] Add production pronunciation media and device audio playback beyond the current in-app pronunciation control

## Contributing

This is currently an academic/team project. For clean collaboration:

1. Create a feature branch from `main`.
2. Keep commits focused and reviewable.
3. Run `flutter analyze` and `flutter test` before opening a pull request.
4. Include screenshots or screen recordings for UI changes.
5. Document new environment variables in `.env.example`.

## License

No license file has been added yet. Add a license before public reuse or distribution outside the project team.
