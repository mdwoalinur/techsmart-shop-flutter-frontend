# Customer Address Backend and Security

Phase 7 adds account-owned, soft-deleted addresses under `/api/mobile/v1/addresses`. The customer JWT supplies ownership; no DTO accepts customer/account IDs. Fields are trimmed, bounded, and Bangladesh phone numbers are normalized. A customer may keep ten active addresses. The first becomes default, choosing another unsets the old default, and deactivating the default promotes another active address.

Entities are never returned directly. Address responses contain only delivery fields and state. Employee JWTs cannot use customer endpoints, and owner-scoped repository queries make cross-customer reads and mutations indistinguishable from missing data.
