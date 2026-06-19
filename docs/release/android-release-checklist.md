# Android Release Checklist

## 0. Environment Prerequisites

Before starting a release build, verify all tools are at the locked versions:

| Tool | Required version |
|------|-----------------|
| Flutter SDK | 3.41.6 (stable) |
| Dart SDK | 3.11.4 (bundled with Flutter 3.41.6) |
| Android Studio | Ladybug (2024.2) or later |
| NDK | 27.0.12077973 (auto-installed by Gradle) |
| Java | 17 (Temurin recommended) |

```bash
flutter --version          # must print Flutter 3.41.6 • Dart 3.11.4
java -version              # must print openjdk 17.x.x
```

If Flutter version does not match, switch via `fvm` or re-install the SDK from
<https://docs.flutter.dev/release/archive>.

---

## 1. Generate Android Keystore

Run **once** and keep the keystore file secure (never commit it to git):

```bash
keytool -genkey -v \
  -keystore ~/keystores/linguaquest-release.keystore \
  -alias linguaquest \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

> Store the keystore file in a password manager or secure vault.  
> If the keystore is lost, you cannot update the Play Store listing.

---

## 2. key.properties File

Create `linguaquest/android/key.properties` (this file must NOT be committed — it is listed in `.gitignore`):

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=linguaquest
storeFile=/absolute/path/to/linguaquest-release.keystore
```

Verify `linguaquest/android/.gitignore` contains:

```
key.properties
*.keystore
*.jks
```

- [ ] `key.properties` created
- [ ] `key.properties` is **not** staged in `git status`

---

## 3. Build Commands

### Release APK (sideload / direct distribution)

```bash
cd linguaquest
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.linguaquest.app
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Release AAB (Google Play)

```bash
cd linguaquest
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.linguaquest.app
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Build without backend (demo / offline mode)

```bash
cd linguaquest
flutter build apk --release
# API_BASE_URL is empty → app runs in mock/offline mode
```

---

## 4. Pre-build Checklist

- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` passes
- [ ] Version and build number bumped in `linguaquest/pubspec.yaml` (`version: X.Y.Z+N`)
- [ ] `key.properties` in place and NOT staged for commit
- [ ] `API_BASE_URL` points to production endpoint
- [ ] Backend deployed and healthy (`curl https://api.linguaquest.app/health`)
- [ ] `dart test` passes in `server/`

---

## 5. Smoke Test Checklist

Run through all 12 items on a **fresh install** of the release APK before submitting to Play Store.
See `docs/release/smoke-test.md` for detailed steps per item.

- [ ] **1.** Registration + Email Verification OTP flow completes and lands on `/home`
- [ ] **2.** Wordbook selection shows HSK 1–6 books; selecting one saves the preference
- [ ] **3.** Learning session: complete one full lesson, XP is awarded, progress updates
- [ ] **4.** Review session: complete one spaced-repetition review pass
- [ ] **5.** AI Q&A: ask a question in the AI Learning tab (mock or live mode)
- [ ] **6.** AI Sentence Analysis: submit a Chinese sentence and see analysis output
- [ ] **7.** AI Fill-in-the-blank: a cloze exercise loads and accepts a correct answer
- [ ] **8.** AI Essay Correction: submit a short paragraph and receive feedback
- [ ] **9.** Community: create a post, comment on another post, like a post
- [ ] **10.** Analytics page: heatmap, achievements list, and leaderboard all render
- [ ] **11.** Public profile: view another user's public profile card
- [ ] **12.** Settings: toggle privacy setting, open Data settings and verify options

---

## 6. Server Deployment

### Development / staging

```bash
cd server
docker compose up --build -d
```

Health check:

```bash
curl http://localhost:8080/health
# expected: {"status":"ok"}
```

### Production

```bash
cd server
cp .env.example .env.prod
# Edit .env.prod — fill in real DATABASE_URL, JWT_SECRET, SMTP_PASSWORD, etc.

docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

Health check against production host:

```bash
curl https://api.linguaquest.app/health
# expected: {"status":"ok"}
```

---

## 7. Google Play Upload Steps

1. Open [Google Play Console](https://play.google.com/console)
2. Select **LinguaQuest** app → **Release** → **Production** (or Internal/Alpha for staged rollout)
3. Click **Create new release**
4. Upload the `.aab` file from step 3
5. Fill in **Release notes** (English + Chinese at minimum)
6. Complete the **Release checklist** in Play Console (content rating, target audience, etc.)
7. Submit for review

---

## 8. Environment Variables / Secrets Inventory

| Secret | Where stored | Notes |
|--------|-------------|-------|
| `KEYSTORE_FILE` | CI secret (base64-encoded) | GitHub Actions: `secrets.KEYSTORE_FILE` |
| `KEYSTORE_STORE_PASSWORD` | CI secret | GitHub Actions: `secrets.KEYSTORE_STORE_PASSWORD` |
| `KEYSTORE_KEY_PASSWORD` | CI secret | GitHub Actions: `secrets.KEYSTORE_KEY_PASSWORD` |
| `KEYSTORE_KEY_ALIAS` | CI secret | Default: `linguaquest` |
| `API_BASE_URL` | CI variable | Production API endpoint |
| `JWT_SECRET` | Server env / CI secret | Min 32 chars, random |
| `DATABASE_URL` | Server env / CI secret | PostgreSQL connection string |
| `SMTP_PASSWORD` | Server env / CI secret | Mail provider credential |
| `AI_API_KEY` | Server env / CI secret | AI provider key (optional) |

---

## 9. CI Signing Setup (GitHub Actions)

To enable automated signed builds, add a build step in `.github/workflows/flutter-apk.yml`:

```yaml
- name: Decode keystore
  run: |
    echo "${{ secrets.KEYSTORE_FILE }}" | base64 --decode \
      > linguaquest/android/app/linguaquest-release.keystore

- name: Write key.properties
  run: |
    cat > linguaquest/android/key.properties <<EOF
    storePassword=${{ secrets.KEYSTORE_STORE_PASSWORD }}
    keyPassword=${{ secrets.KEYSTORE_KEY_PASSWORD }}
    keyAlias=${{ secrets.KEYSTORE_KEY_ALIAS }}
    storeFile=../app/linguaquest-release.keystore
    EOF
```
