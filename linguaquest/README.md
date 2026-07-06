# LinguaQuest

LinguaQuest is a Flutter language-learning app prototype built around image word cards, a guided learning path, spaced review, quiz results, and cloud-ready custom word CRUD.

## App

Run from this directory:

```bash
flutter pub get
flutter run
```

By default the app uses an in-memory/mock repository so the full demo path works offline:

```text
Register -> Goal Setup -> Home -> Learn -> Lesson -> Quiz -> Result -> Wordbook -> Custom Words -> Review
```

To point the app at the Dart server API:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Use `10.0.2.2` for Android emulator access to a host-machine server.

### Release APK (production backend)

The distributable APK must be built with the production API base URL, otherwise
every repository silently falls back to the offline mock (no real accounts,
community, or AI):

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.vonlan233.top
```

Without `--dart-define`, `API_BASE_URL` is empty and the app runs fully offline
on mock data — fine for local UI work and the widget tests, not for a shipped build.

## Checks

```bash
flutter analyze
flutter test
```
