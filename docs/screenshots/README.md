# Screenshots Guide

## Naming Convention

```
<screen>_<theme>_<locale>.png
```

| Segment | Values | Example |
|---------|--------|---------|
| `screen` | snake_case screen name | `home`, `wordbook_select` |
| `theme` | `light` or `dark` | `light` |
| `locale` | ISO 639-1 language code | `en`, `zh` |

Examples:
- `home_light_en.png`
- `lesson_light_zh.png`
- `profile_light_en.png`

## Capture Methods

### Method A — Flutter screenshot (emulator / physical device)

```bash
# Run the app on an attached emulator or device
cd linguaquest
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# In the Flutter DevTools or via the 's' shortcut in the terminal to take a screenshot
# Or from another terminal:
flutter screenshot --out=docs/screenshots/home_light_en.png
```

### Method B — adb screencap (Android emulator / device)

```bash
# Capture to device, then pull
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png docs/screenshots/home_light_en.png
adb shell rm /sdcard/screenshot.png
```

### Method C — Android Emulator built-in

Use the camera icon in the Android Emulator toolbar. Save the file and rename according to the convention above.

## Required Screenshots List

The following screenshots are required for the Play Store listing and internal design reference. Minimum resolution: **1080 × 1920 px** (portrait).

| File name | Screen | Description |
|-----------|--------|-------------|
| `home_light_en.png` | Home dashboard | Streak card, daily progress ring, Word of the Day |
| `wordbook_select_light_en.png` | Wordbook selector | HSK level grid / list |
| `lesson_light_en.png` | Lesson preview | Lesson card with vocabulary list |
| `review_light_en.png` | Spaced repetition review | Flashcard with recall buttons |
| `ai_learning_light_en.png` | AI Learning tab | AI conversation / exercise screen |
| `profile_light_en.png` | Profile screen | Avatar, XP bar, streak stats |
| `quiz_light_en.png` | Quiz session | Word-choice question card |
| `training_light_en.png` | Training tab | Exercise type selector |

## Storage

Store raw screenshots in this directory (`docs/screenshots/`). Do not commit screenshots to the main repository — add `docs/screenshots/*.png` to `.gitignore` if file sizes become an issue. For Play Store assets use the Google Play Console upload workflow instead.
