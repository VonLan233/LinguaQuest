# Notifications API

This document describes the P1-1 notification API contract. The backend stores
and syncs in-app notification data only. It does not push remote FCM/APNs
messages to devices.

## Notification Object

```json
{
  "id": "notification-id",
  "uid": "user-id",
  "type": "reviewDue",
  "title": "3 个词到期复习",
  "body": "先清理复习队列，答错词会自动进入强化阶段。",
  "targetRoute": "/study/review",
  "isRead": false,
  "sourceKey": "reviewDue:2026-06-02",
  "readAt": null,
  "createdAt": "2026-06-02T09:00:00.000Z"
}
```

Field mapping:

| API field | Database column | Notes |
| --- | --- | --- |
| `id` | `id` | Notification id. |
| `uid` | `uid` | Current user id. |
| `type` | `type` | One of the supported notification types. |
| `title` | `title` | Short display title. |
| `body` | `body` | Display body text. |
| `targetRoute` | `target_route` | Mobile route opened from the notification. |
| `isRead` | `is_read` | Read state. |
| `sourceKey` | `source_key` | Deterministic key for daily de-duplication. |
| `readAt` | `read_at` | Nullable read timestamp. |
| `createdAt` | `created_at` | Creation timestamp. |

## Types

| Type | Meaning | Default target |
| --- | --- | --- |
| `learningReminder` | Learning reminder | `/study/new` |
| `reviewDue` | Review due reminder | `/study/review` |
| `checkInReminder` | Check-in reminder | `/discover` |
| `activity` | Activity message | `/discover` |

## Endpoints

### `GET /notifications`

Returns the current user's notifications in descending `createdAt` order.

Supported query parameters:

| Parameter | Type | Example | Notes |
| --- | --- | --- | --- |
| `unreadOnly` | boolean | `true` | When true, only unread notifications are returned. |
| `type` | string | `reviewDue` | Optional notification type filter. |

Example:

```text
GET /notifications?unreadOnly=true&type=reviewDue
```

Response:

```json
[
  {
    "id": "notification-id",
    "uid": "user-id",
    "type": "reviewDue",
    "title": "3 个词到期复习",
    "body": "先清理复习队列，答错词会自动进入强化阶段。",
    "targetRoute": "/study/review",
    "isRead": false,
    "sourceKey": "reviewDue:2026-06-02",
    "readAt": null,
    "createdAt": "2026-06-02T09:00:00.000Z"
  }
]
```

Before returning, the backend generates or fills deterministic daily
notifications for the current user:

- `learningReminder` when the daily learning goal is not complete.
- `reviewDue` when there are due review words.
- `checkInReminder` when the user has not checked in today.
- `activity` once per day.

Daily de-duplication uses the unique `uid + source_key` constraint.

### `PATCH /notifications/read-all`

Marks every notification for the current user as read.

Response:

```json
{ "updated": 4 }
```

The update only affects the current user's notifications.

### `PATCH /notifications/<id>/read`

Marks one notification as read for the current user.

Response:

```json
{
  "notification": {
    "id": "notification-id",
    "uid": "user-id",
    "type": "activity",
    "title": "发现页积分任务已刷新",
    "body": "完成新学、复习和错词清理后可领取 XP。",
    "targetRoute": "/discover",
    "isRead": true,
    "sourceKey": "activity:2026-06-02",
    "readAt": "2026-06-02T09:30:00.000Z",
    "createdAt": "2026-06-02T09:00:00.000Z"
  }
}
```

The update only succeeds for a notification owned by the current user.

## Mobile Boundary

The mobile app still owns local scheduled system notifications through
`flutter_local_notifications`.

- Android requests `POST_NOTIFICATIONS`.
- iOS requests alert, badge, and sound permissions.
- Exact alarms are not used, so `SCHEDULE_EXACT_ALARM` is not required.
- Local notification payloads carry `targetRoute`.
- At most two local reminder categories are scheduled per day: combined
  learning/check-in and review due.

