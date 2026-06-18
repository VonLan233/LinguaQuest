# Backend Reminder Updates Design

## Goal

Make reminder and notification behavior work correctly in API mode without mixing this work into the mobile UI bugfix branch. The backend remains a Dart Shelf API with PostgreSQL, and the mobile app stays offline-first by keeping mock repositories unchanged unless API parsing needs to match the server contract.

## Scope

- Persist API-mode reminder state through the existing `study_plans.reminder_time` and `study_plans.status` fields.
- Return notification `params` from the backend so the mobile client can render localized notification title/body from `AppNotificationType + params`.
- Generate deterministic daily backend notifications with the same params shape the mobile model already expects.
- Preserve existing notification CRUD: list, filter, mark one read, mark all read.
- Clean two existing duplicate statements in backend code found during exploration.

## Out Of Scope

- Remote FCM/APNs push delivery.
- Mobile visual UI changes.
- New reminder scheduling tables beyond the existing study plan fields.
- Changing mock notification semantics except where tests require contract parity.

## Data Model

`notifications` gains:

- `params TEXT NOT NULL DEFAULT '{}'`

The column stores JSON object text. It is intentionally text because the project already stores JSON-like lists in text columns and tests run without a real JSONB dependency.

Params by notification type:

- `learningReminder`: `{ "dailyGoal": 12 }`
- `reviewDue`: `{ "dueCount": 3 }`
- `checkInReminder`: `{}`
- `activity` daily refresh: `{ "kind": "activity" }`
- `activity` lottery result: `{ "kind": "lottery", "prizeName": "Gold Frame" }`

## API Contract

`GET /notifications` continues to validate `type`, `localDate`, and `timezoneOffsetMinutes`, generates/fills deterministic notifications for the client-local day, then returns notifications ordered by `createdAt DESC`.

Each notification DTO now includes:

```json
{
  "params": { "dueCount": 3 }
}
```

`PATCH /notifications/read-all` and `PATCH /notifications/<id>/read` keep their existing behavior.

Reminder settings are persisted through `PUT /study-plan`. The mobile controller already saves reminder enablement as plan `status` and time as `reminderTime`; this backend update keeps that path authoritative in API mode.

## Error Handling

- Invalid notification type still returns `400`.
- Invalid date or timezone offset still returns `400`.
- Malformed stored `params` decodes to `{}` rather than breaking notification listing.
- Upserts keep existing read state and read timestamp for daily notifications.

## Testing

- Server policy tests cover generated notification params.
- Server DTO tests cover decoding string JSON params and malformed params fallback.
- Server route/database tests continue to cover notification CRUD and study plan persistence.
- Flutter notification repository tests cover API parsing of `params`.
- Full gates: `cd server && dart test`, `cd linguaquest && flutter analyze`, `cd linguaquest && flutter test`.
