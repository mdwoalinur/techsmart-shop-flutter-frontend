# 45. Notification Domain and Templates

Phase 10 adds a customer-safe notification domain separate from the existing internal TradeMaster `notifications` table used by Angular and employee workflows.

## Tables

New Hibernate-managed tables:

- `customer_notifications`
- `customer_notification_templates`
- `customer_notification_preferences`

The customer notification table stores a generated `notificationNumber`, owning `CustomerAccount`, type, category, severity, read state, delivery status, safe related references, safe action type/reference, timestamps, optional expiry, optimistic version, and a unique `eventKey`.

Indexes cover customer + created date, customer + read status, customer + category, unique notification number, and unique event key.

## Types and categories

Implemented event types include order creation/confirmation, cancellation request, return request, payment initiated/paid/failed/review/rejected, COD pending, wallet success, manual payment submitted, system message, and security alert.

Categories are:

- ORDER
- PAYMENT
- RETURN
- CANCELLATION
- ACCOUNT
- SYSTEM

Severities are INFO, SUCCESS, WARNING, and ERROR. Channels are IN_APP, EMAIL, or BOTH.

## Templates

`CustomerNotificationService` seeds English templates on demand. The template engine only performs safe token replacement; it does not evaluate expressions. Supported variables include order number, payment number, amount, method, provider, and return request number.

Templates intentionally use customer-safe references such as `orderNumber`, `paymentNumber`, and `returnRequestNumber`. Internal database IDs, buying price, stock quantities, employee details, tokens, OTPs, and gateway payloads are not rendered.

## Preferences

Each customer gets one preference row per category. In-app is enabled by default for every category. Email defaults to enabled for order, payment, and account categories, but actual sending remains disabled unless mail configuration is enabled. ACCOUNT notifications keep in-app delivery enabled for safety.

## Duplicate prevention

Event keys prevent duplicated notification creation. Examples:

- `ORDER_CREATED:{orderNumber}`
- `PAYMENT_PAID:{paymentNumber}`
- `WALLET_PAYMENT_SUCCESS:{paymentNumber}`
- `RETURN_REQUESTED:{returnRequestNumber}`

Duplicate payment callbacks or repeated idempotent customer actions return the existing notification instead of creating another row.