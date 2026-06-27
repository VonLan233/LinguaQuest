# LinguaQuest — Test Plan & Execution Report

- **Date:** 2026-06-27
- **App version:** 1.0.0+1 · Flutter 3.41.6 (stable)
- **Build under test:** `linguaquest/build/app/outputs/flutter-apk/app-release.apk` (release, 66.5 MB)
- **Backend under test:** `http://vonlan233.top:8080` (and offline/demo mode — the app runs fully without a backend)
- **Branch:** `feat/P2-roadmap`

## 1. Scope & strategy

Two layers:

1. **Automated tests** (executed by CI / `flutter test` + `dart test`) — unit + widget + policy tests. **Executed here; results in §2.**
2. **Manual functional tests** (§4) — black-box test cases to be executed by hand on the release APK by a tester. Each case has steps, expected result, and a Pass/Fail/Notes column.

Persistence note: the app is **offline-first** — every data domain has a Mock (offline) and an Api (backend) implementation. Manual tests can be run **offline** (install APK, no backend) for all features except those marked *(backend)*, which need the app pointed at `http://vonlan233.top:8080` (built with `--dart-define=API_BASE_URL=...`).

## 2. Automated test execution (results)

| Suite | How to run | Files | Tests | Result |
|---|---|---|---|---|
| Flutter unit + widget | `cd linguaquest && flutter test` | 113 | **540** | ✅ All passed |
| Dart backend | `cd server && dart test` | 26 | **164** | ✅ All passed |
| Static analysis | `cd linguaquest && flutter analyze` | — | — | ✅ No issues found |
| Release build | `flutter build apk --release` | — | — | ✅ Built (66.5 MB) |

Representative automated coverage (not exhaustive):
- **Models/data:** wordbook parsing (HSK 1-6, JLPT N5-N1 — counts, no-CJK-in-meaning, kana/romaji), Article model + loader, language dimension, analytics model round-trips.
- **Progress isolation:** scope-key migration (copy-don't-delete, idempotent), per-scope isolation (writing one wordbook's progress doesn't wipe siblings).
- **Theme:** dark/light wiring, chip-label contrast/luminance.
- **Widgets:** language map, About company map, two-level picker, reading list/reader, comprehension flow, AI error/retry, analytics charts, asset inventory, community filter.
- **Server policies:** lottery probabilities sum to 100, achievements (incl. first_japanese_lesson/first_reading), analytics aggregation, study-plan (HSK+JLPT ids), forum, AI routes (incl. /ai/reading-explain validation).

> Re-run command for evidence: `cd linguaquest && flutter test && flutter analyze && cd ../server && dart test`.

## 3. Backend smoke (executed 2026-06-27, live)

| Endpoint | Expected | Result |
|---|---|---|
| `GET /health` | 200 | ✅ 200 |
| `POST /ai/reading-explain` (no auth) | 401 (live, auth-protected) | ✅ 401 |
| `GET /achievements` (no auth) | 401 | ✅ 401 |
| `GET /analytics` (no auth) | 401 | ✅ 401 |
| `POST /auth/login` (bad creds) | 401 (DB reachable, not 500) | ✅ 401 |

Confirms the redeploy booted cleanly and the idempotent DB migrations (multi-language `language` columns, `first_map_language_at`, etc.) applied.

---

## 4. Manual functional test cases (hand-off to tester)

**Setup:** install `app-release.apk` on an Android device/emulator. Register a new account (or use offline/demo mode). Mark each case Pass/Fail and add notes.

### 4.1 Onboarding, auth & navigation
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| NAV-1 | Launch app, register a new account | Account created, lands on Home | | |
| NAV-2 | Tap each bottom-tab (Home, Training, AI Learning, Discover, Profile, Quest) | Each screen loads without error | | |
| NAV-3 | Open the side **Drawer** (menu button on Home) | Drawer shows Study Map / Search / Profile / Settings / Help / About / Choose Language | | |
| NAV-4 | Log out, log back in | Session restored, progress intact | | |

### 4.2 Dark mode (§1)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| THM-1 | Settings → Theme → select **Dark** | Whole app switches to dark immediately (no restart) | | |
| THM-2 | Visit Home, Reading, Analytics (charts), Maps, AI screens in dark | Text/icons/cards/charts readable, no white-on-white | | |
| THM-3 | Select **Follow system**, toggle device theme | App follows the system setting | | |
| THM-4 | Kill & relaunch app | Last theme choice persisted | | |

### 4.3 Language & wordbook selection (§2, §3.1)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| LANG-1 | Profile/Home → open the language→wordbook picker | Level 1 shows **Chinese** + **Japanese** (both selectable) | | |
| LANG-2 | Pick Chinese → choose HSK 3 | Current target becomes HSK 3; Home reflects it | | |
| LANG-3 | Pick Japanese → choose JLPT N5 | Switches to JLPT N5; Japanese content shows | | |
| LANG-4 | Switch back to a Chinese wordbook | Previous Chinese progress is intact (not wiped) | | |
| LANG-5 | Drawer → **Choose Language** → tap **China** on the map | Opens Chinese wordbook selection | | |
| LANG-6 | On the language map, tap **Japan** | Opens Japanese (JLPT) wordbook selection | | |
| LANG-7 | Tap another country pin (e.g. France) | Shows "coming soon", no change | | |

### 4.4 Wordbooks & word detail (§2.3, §2.4, §2.5)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| WB-1 | Open a Chinese word's detail | Shows hanzi + **pinyin** + English meaning | | |
| WB-2 | Open a Japanese word's detail | Shows word + **kana + romaji** (no pinyin row) + meaning | | |
| WB-3 | Search a Chinese word by pinyin/hanzi | Found | | |
| WB-4 | Search a Japanese word by kana/romaji/kanji | Found | | |

### 4.5 Learning, quiz & training
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| LRN-1 | Start a lesson, complete a quiz | Score shown; XP/progress updates | | |
| LRN-2 | On quiz result, tap **Explain with AI** on a mistake *(backend)* | Opens AI Q&A pre-filled with that word | | |
| LRN-3 | Training → run Word Rush / Survival / Spelling | Game plays, results recorded | | |
| LRN-4 | Mistake book → **Explain with AI** | Opens AI for that word | | |

### 4.6 Reading module (§4)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| RD-1 | Discover → **Reading** | Article list shows; filter by level + theme works | | |
| RD-2 | Open an article | Paragraphs render; title shown | | |
| RD-3 | Toggle **translation** / **reading (pinyin/kana)** | Each toggles per paragraph | | |
| RD-4 | Tap a paragraph **audio** button | Pronunciation plays (zh-CN / ja-JP) | | |
| RD-5 | Tap a **highlighted word** | Meaning popup; "Add to vocab notebook" works | | |
| RD-6 | Toggle **highlight** on/off | Known/new/key/unknown coloring appears/disappears | | |
| RD-7 | Tap **Start comprehension**, answer questions | Score summary; counts into stats | | |
| RD-8 | Tap **Explain with AI** on a paragraph *(backend)* | Structured explanation (gist/keywords/grammar/structure/translation/practice) + retry on error | | |
| RD-9 | Reopen article | Reading progress remembered | | |

### 4.7 AI Learning (§5)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| AI-1 | AI Learning hub | The 4 tools (Q&A, Sentence Analysis, Cloze, Writing Review) show **Available** (not "Coming Soon") | | |
| AI-2 | Run AI Q&A *(backend)* | Structured answer; loading state; error shows retry card | | |
| AI-3 | While learning Japanese, run AI Q&A *(backend)* | Explanation is about Japanese (kana/romaji/grammar) | | |
| AI-4 | AI Writing Review — submit short essay *(backend)* | Scored feedback; the exam-type pills are readable | | |

### 4.8 Multimedia / audio (§9)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| AUD-1 | Play audio on a Chinese word (detail / lesson / training) | Mandarin pronunciation plays | | |
| AUD-2 | Play audio on a Japanese word | Japanese (ja-JP) pronunciation plays | | |
| AUD-3 | Play with no network | Falls back to TTS or shows a friendly "unavailable, retry" | | |

### 4.9 Map features (rubric: Map)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| MAP-1 | Drawer → **Study Map** | OpenStreetMap renders; "© OpenStreetMap" attribution visible | | |
| MAP-2 | Tap the locate button | Requests location; blue marker appears (or denied banner, no crash) | | |
| MAP-3 | About page | Read-only company-location map + marker + company info | | |

### 4.10 Analytics (§3, §6)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| AN-1 | Open the learning analytics / progress screen | Charts render: line, bar, pie/ring, radar + metric cards | | |
| AN-2 | Note the **scope** label | Shows current language + wordbook (e.g. "HSK 4" / "JLPT N5") | | |
| AN-3 | Complete a reading comprehension, return | "Reading" metrics (articles read, accuracy, themes) update | | |

### 4.11 Achievements & lottery (§7, §10)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| ACH-1 | Open Achievements | List shows; unlocked vs locked | | |
| ACH-2 | Study a Japanese word *(backend)* | `First Japanese` achievement unlocks | | |
| ACH-3 | Complete a reading comprehension *(backend)* | `First Reading` achievement unlocks | | |
| LOT-1 | Discover → Lucky Draw → draw | Prize awarded (≥15-prize pool, grouped by rarity); duplicates accumulate/convert to fragments | | |
| LOT-2 | Open the **Asset inventory** | Owned assets grouped by category with quantities | | |

### 4.12 Community (§5, §8)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| COM-1 | Discover → Community | Post cards show author + time + tag + like/comment counts | | |
| COM-2 | Filter by a tag (Grammar / Progress / a scope tag like "HSK 4") | List narrows; "All" restores | | |
| COM-3 | Create a post; like / favorite / comment *(backend for persistence)* | Post appears; like/favorite/comment work | | |

### 4.13 Offline (§7, rubric: Persistence)
| ID | Steps | Expected | P/F | Notes |
|---|---|---|---|---|
| OFF-1 | Enable airplane mode, open a cached wordbook/lesson/article | Content available offline | | |
| OFF-2 | Settings → Data & Account → **Offline content** | Status shows current scope "Available offline" | | |
| OFF-3 | Tap **Refresh content** | Confirmation; content reloads | | |
| OFF-4 | Earn XP / complete a lesson, kill app, relaunch | Progress persisted | | |

---

## 5. Requirements traceability (coursework + plan → tests)

| Requirement | Automated | Manual |
|---|---|---|
| Map feature (rubric) | language-map / about-map widget tests | MAP-1..3, LANG-5..7 |
| Multimedia (rubric) | PronunciationService/controls tests | AUD-1..3, RD-4 |
| Data persistence (rubric) | scope-migration / isolation tests | OFF-1..4 |
| ≥10 screens + navigation (rubric) | widget tests across screens | NAV-1..4 |
| §1 Dark mode | theme tests | THM-1..4 |
| §2/§3.1 Multi-language + Japanese | wordbook/loader/picker/map tests | LANG-1..7, WB-1..4 |
| §4 Reading module | article/reader/comprehension/AI-explain tests | RD-1..9 |
| §5 AI Learning | askAi/reviewWriting language tests | AI-1..4, LRN-2/4 |
| §6 Analytics | analytics model/aggregation/charts tests | AN-1..3 |
| §7/§10 Achievements + lottery | policy/inventory tests | ACH-1..3, LOT-1..2 |
| §8 Community | forum filter/tag tests | COM-1..3 |

## 6. Known limitations / not under test
- JFT-Basic Japanese wordbook deferred (JLPT N5-N1 shipped).
- HSK Chinese definitions are English glosses; Chinese definitions + example sentences not yet filled.
- Reading toggle preferences are per-session (not globally persisted).
- AI features require the backend (`API_BASE_URL`) or show demo/mock responses offline.
