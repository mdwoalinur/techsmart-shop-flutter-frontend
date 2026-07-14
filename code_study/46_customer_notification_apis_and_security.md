# 46. Customer Notification APIs and Security

Phase 10 exposes customer notification APIs under `/api/mobile/v1/notifications`. Routes are protected by `ROLE_CUSTOMER` in `SecurityConfig` and use `CustomerAuthentication.accountId()` only. No endpoint accepts customer ID from the client.

## Endpoints

- `GET /api/mobile/v1/notifications`
- `GET /api/mobile/v1/notifications/unread-count`
- `GET /api/mobile/v1/notifications/{notificationNumber}`
- `POST /api/mobile/v1/notifications/{notificationNumber}/read`
- `POST /api/mobile/v1/notifications/read-all`
- `GET /api/mobile/v1/notifications/preferences`
- `PUT /api/mobile/v1/notifications/preferences`

List pagination defaults to page `0`, size `20`, and caps size at `50`. Sorting is newest first only. Optional filters are category and read status.

## Ownership

Every detail and mutation query scopes by `notificationNumber` and authenticated account ID. A notification owned by another customer is indistinguishable from not found. Preference reads and writes are also scoped to the authenticated account.

Anonymous requests return 401. Authenticated employee/non-customer principals return 403.

## Safe action links

The API returns safe action types and safe references only:

- `OPEN_ORDER` with order number
- `OPEN_PAYMENT` with order number for the existing payment screen
- `OPEN_RETURN_REQUEST` with order number
- `OPEN_CANCELLATION_REQUEST` with order number
- `OPEN_PROFILE`
- `NONE`

The target screens still fetch their own resources through secure APIs, so a notification action cannot bypass order/payment ownership checks.

## Email foundation

`CustomerNotificationEmailService` reuses the existing `JavaMailSender` configuration and environment-backed email flags. If email is disabled or sender/recipient configuration is missing, in-app notification creation still succeeds and delivery status becomes `EMAIL_DISABLED`. Email failures are caught and reported as `EMAIL_FAILED`; they do not roll back order, payment, or account transactions.

Email body content is customer-safe and does not include passwords, OTPs, access tokens, refresh tokens, gateway secrets, raw webhook payloads, buying price, stock quantity, or internal database IDs.