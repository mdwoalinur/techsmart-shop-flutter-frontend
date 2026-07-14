# 47. Flutter Notification Center and Badge

Phase 10 adds Flutter notification support without redesigning the existing app shell.

## Models and service

New files:

- `lib/model/notification/notification_models.dart`
- `lib/service/notification/notification_service.dart`
- `lib/provider/notification_provider.dart`

The service uses the shared authenticated `ApiClient`; no unauthenticated notification client is created. Enums parse unknown future backend values to `unknown` instead of crashing.

## Provider state

`NotificationProvider` tracks unread count, list loading, refresh, pagination, detail loading, preferences loading/saving, filters, errors, and selected detail. It avoids duplicate page loads, preserves list data on refresh failure, updates unread count after read mutations, and clears customer-specific state on logout/customer switch.

The provider now also records the initial authenticated customer if constructed after auth restoration, which prevents stale customer notifications from surviving logout.

## UI

New UI files:

- `NotificationBell`
- `NotificationCenterScreen`
- `NotificationDetailScreen`
- `NotificationPreferencesScreen`

The Home brand header includes the notification bell with a capped `99+` badge. The authenticated Menu includes a Notifications entry with unread count. Guest access shows a sign-in prompt and does not call protected APIs.

Notification Center supports pull-to-refresh, category filters, read/unread filters, empty state, safe error retry, mark all read, and load more. Detail opens the notification, marks it read, and shows an action button when a safe action exists.

## Action navigation

- Order/cancellation/return actions open the existing Order Detail screen using order number.
- Payment actions open the existing Payment screen using order number because the current Flutter payment UI is order-number based.
- Profile actions open the existing Profile screen.

Target APIs continue to enforce ownership.