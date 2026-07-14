# 40 - Flutter Payment State and UI

Phase 9 adds Flutter payment models, service, provider, and screen integration for backend-authoritative payment flows.

## Files

- `lib/model/payment/payment_models.dart`
- `lib/service/payment/payment_service.dart`
- `lib/provider/payment_provider.dart`
- `lib/ui/screen/payment/payment_screen.dart`
- Order detail integration in `lib/ui/screen/order/order_detail_screen.dart`

## Models

The Flutter models parse payment methods, initiation result, manual submission result, COD selection result, payment status, attempts, and timeline entries. Money uses `DecimalValue` rather than `double` for authoritative display.

Unknown future backend statuses are preserved as strings so the UI does not crash on future enum additions.

## Service

`PaymentService` uses the shared authenticated `ApiClient` and exposes:

- load methods
- initiate online payment
- submit manual payment
- select COD
- cancel pending payment
- fetch payment status

The initiation request does not send amount or success flags. Flutter stores no gateway secrets.

## Provider

`PaymentProvider` manages:

- methods and selected method
- current payment status
- initiation/manual/COD result
- idempotency key
- bounded polling
- manual draft
- safe error text
- logout/customer isolation

States include idle, loading methods, methods ready, initiating, awaiting gateway, pending, review required, paid, failed, cancelled, loading status, and error.

The provider only enters `paid` after backend status is `PAID`. It does not trust client return/deep-link success. Logout clears customer-specific payment state and cancels polling.

## UI

`PaymentScreen` loads backend methods, shows disabled ineligible methods, displays server amount as non-editable, supports method-specific actions, shows review/COD explanations, displays timeline entries, refreshes status, and exposes cancel only when backend status says the payment is cancellable.

`OrderDetailScreen` now includes a payment section with Pay/View Payment Details behavior while hiding payment action for terminal paid/cancelled/refunded states.

## Safety guarantees

- No raw card collection.
- No PAN or CVV storage.
- No gateway secret in Flutter.
- No ledger posting from Flutter.
- No client-supplied payment success.
- No editable authoritative amount.
