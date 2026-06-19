# Android Release Checklist

## 1. Generate Android Keystore

Run once and keep the keystore file secure (never commit it to git):

```bash
keytool -genkey -v \
  -keystore ~/keystores/linguaquest-release.keystore \
  -alias linguaquest \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

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

## 4. Pre-build Checklist

- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` passes
- [ ] Version and build number bumped in `linguaquest/pubspec.yaml` (`version: X.Y.Z+N`)
- [ ] `key.properties` in place and NOT staged for commit
- [ ] `API_BASE_URL` points to production endpoint
- [ ] Backend deployed and healthy (`curl https://api.linguaquest.app/health`)

## 5. Google Play Upload Steps

1. Open [Google Play Console](https://play.google.com/console)
2. Select **LinguaQuest** app → **Release** → **Production** (or Internal/Alpha for staged rollout)
3. Click **Create new release**
4. Upload the `.aab` file from step 3
5. Fill in **Release notes** (English + Chinese at minimum)
6. Complete the **Release checklist** in Play Console (content rating, target audience, etc.)
7. Submit for review

## 6. Environment Variables / Secrets Inventory

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

## 7. CI Signing Setup (GitHub Actions)

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
