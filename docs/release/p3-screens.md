# P3 Screen Inventory (report screenshots)

Capture on an Android emulator (Pixel, API 34). Run:
```bash
cd linguaquest
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Then for each screen use Android Studio's screenshot tool or:
```bash
adb exec-out screencap -p > docs/screenshots/<file>.png
```

## Screenshot Inventory

| # | Category | Screen | Route | Screenshot |
|---|----------|--------|-------|-----------|
| 1 | Splash | SplashScreen | `/` | splash.png |
| 2 | Onboarding | OnboardingScreen | `/onboarding` | onboarding.png |
| 3 | Login | LoginScreen | `/login` | login.png |
| 4 | Register | RegisterScreen | `/register` | register.png |
| 5 | Home/Dashboard | HomeScreen | `/home` | home.png |
| 6 | List/Display | WordbookScreen | `/wordbook` | wordbook.png |
| 7 | Detail View | TargetWordDetailScreen | `/wordbook/:id` | word_detail.png |
| 8 | Add/Edit Form | AddEditCustomWordScreen | `/custom-words/new` | add_word.png |
| 9 | Profile | ProfileScreen | `/profile` | profile.png |
| 10 | Settings | SettingsScreen | `/settings` | settings.png |
| 11 | About/Info | AboutScreen | `/about` | about.png |
| 12 | Help/FAQ | HelpSupportScreen | `/help` | help.png |
| 13 | Search/Filter | SearchScreen | `/search` | search.png |
| 14 | Map (advanced) | StudyMapScreen | `/map` | study_map.png |
| 15 | Map list | StudySpotsListScreen | `/map/spots` | study_spots.png |

## Navigation Features Demonstrated

- **BottomNavigationBar** — Shell tabs: Home, Training, AI Learning, Discover, Profile, Quest
- **TabBar** — Leaderboard (`/leaderboard`) with filtering tabs
- **Drawer** — Hamburger navigation on AppShell for secondary features

## Advanced Features Covered

- **Map** — Study Spots map screen (`/map`) with geolocating and spot markers
- **Multimedia** — Pronunciation/TTS on word detail screen (`/wordbook/:id`)
- **Data Persistence** — Study spots via backend API + offline mock (SharedPreferences fallback)
- **Custom Words** — Add/edit custom word form with persistent storage

## Capture Instructions

1. **Build and run** against the API:
   ```bash
   cd linguaquest
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
   ```

2. **Navigate each route** and capture screenshots:
   - Use Android Studio's built-in screenshot tool (Run > Screenshot), or
   - Use `adb` command: `adb exec-out screencap -p > docs/screenshots/<filename>.png`

3. **Save to** `docs/screenshots/` with filenames exactly as listed in the table.

4. **Verify** all 15 screens are captured before submitting the report.
