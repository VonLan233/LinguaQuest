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

## Checks

```bash
flutter analyze
flutter test
```
