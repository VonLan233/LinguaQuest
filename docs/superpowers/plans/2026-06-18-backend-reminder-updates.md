# Backend Reminder Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist and localize API-mode reminder notifications through backend notification params and existing study plan reminder fields.

**Architecture:** Extend the existing notifications table and DTO with JSON params stored as text. Keep daily notification generation deterministic and source-key deduplicated. Reuse the existing mobile `AppNotification.params` renderer rather than adding remote push.

**Tech Stack:** Dart Shelf backend, PostgreSQL via `postgres`, Flutter/Dio API repositories, `dart test`, `flutter test`.

---

### Task 1: Server Notification Params

**Files:**
- Modify: `server/lib/src/notification_policy.dart`
- Modify: `server/lib/src/database.dart`
- Modify: `server/lib/src/routes.dart`
- Test: `server/test/notification_policy_test.dart`
- Test: `server/test/routes_test.dart`

- [ ] **Step 1: Write failing server tests**

Add assertions that generated notifications include params:

```dart
expect(learning['params'], {'dailyGoal': 12});
expect(review['params'], {'dueCount': 3});
expect(activity['params'], {'kind': 'activity'});
```

Add DTO assertions:

```dart
expect(notificationDto({'params': '{"dueCount":3}'})['params'], {'dueCount': 3});
expect(notificationDto({'params': '{bad json'})['params'], <String, dynamic>{});
```

- [ ] **Step 2: Verify RED**

Run: `cd server && dart test test/notification_policy_test.dart test/routes_test.dart`

Expected: fails because generated notifications and DTOs do not include params.

- [ ] **Step 3: Implement params**

Add `params TEXT NOT NULL DEFAULT '{}'` to migrations, include `params` in notification upserts, decode it in `notificationDto`, and add params in generated and lottery notifications.

- [ ] **Step 4: Verify GREEN**

Run: `cd server && dart test test/notification_policy_test.dart test/routes_test.dart`

Expected: all selected tests pass.

- [ ] **Step 5: Commit**

Run:

```bash
git add server/lib/src/notification_policy.dart server/lib/src/database.dart server/lib/src/routes.dart server/test/notification_policy_test.dart server/test/routes_test.dart docs/superpowers/specs/2026-06-18-backend-reminder-updates-design.md docs/superpowers/plans/2026-06-18-backend-reminder-updates.md
git commit -m "feat(server): return notification params"
```

### Task 2: Mobile API Params Parsing

**Files:**
- Modify: `linguaquest/test/notification_test.dart`
- Confirm: `linguaquest/lib/data/models/app_notification.dart`
- Confirm: `linguaquest/lib/data/repositories/api_repositories.dart`

- [ ] **Step 1: Write failing API repository test**

Add a static API response containing:

```json
[
  {
    "id": "n-api",
    "uid": "api-user",
    "type": "reviewDue",
    "title": "3 个词到期复习",
    "body": "先清理复习队列",
    "targetRoute": "/study/review",
    "isRead": false,
    "sourceKey": "reviewDue:2026-06-18",
    "createdAt": "2026-06-18T00:00:00.000Z",
    "params": { "dueCount": 3 }
  }
]
```

Assert `notifications.single.params` equals `{'dueCount': 3}`.

- [ ] **Step 2: Verify RED or existing pass**

Run: `cd linguaquest && flutter test test/notification_test.dart`

Expected: pass if the model already parses params from API JSON, otherwise fail and then implement parsing.

- [ ] **Step 3: Implement only if needed**

If needed, update `AppNotification.fromJson` to preserve `params` maps from API responses.

- [ ] **Step 4: Verify GREEN**

Run: `cd linguaquest && flutter test test/notification_test.dart`

Expected: all notification tests pass.

- [ ] **Step 5: Commit**

Run:

```bash
git add linguaquest/test/notification_test.dart linguaquest/lib/data/models/app_notification.dart
git commit -m "test(notification): cover api params parsing"
```

### Task 3: Backend Cleanup And Full Verification

**Files:**
- Modify: `server/lib/src/database.dart`
- Modify: `server/lib/src/routes.dart`

- [ ] **Step 1: Remove duplicate statements**

Remove the duplicated `Sql.named('SELECT * FROM user_words...')` in `database.dart` and the duplicate `return jsonResponse({'error': 'user not found'})` in `routes.dart`.

- [ ] **Step 2: Run full verification**

Run:

```bash
cd server && dart test
cd ../linguaquest && flutter analyze
flutter test
```

Expected:

- `server`: `All tests passed!`
- `flutter analyze`: `No issues found!`
- `flutter test`: `All tests passed!`

- [ ] **Step 3: Commit cleanup if not included earlier**

Run:

```bash
git add server/lib/src/database.dart server/lib/src/routes.dart
git commit -m "chore(server): clean duplicate statements"
```
