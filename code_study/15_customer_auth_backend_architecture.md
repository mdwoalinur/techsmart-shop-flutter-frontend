# 15. Customer Authentication Backend Architecture

## Scope and separation

Phase 5 runs only under `E:\Dart_flutter\flutter_project`. Customer authentication is implemented below `/api/mobile/v1/auth` and is separate from employee `/api/auth` authentication. Employee JWTs remain username-subject tokens resolved by `UserDetailsServiceImpl`; customer JWTs use a numeric CustomerAccount subject, `techsmart-customer` audience, `customer_access` type, and only `ROLE_CUSTOMER`. The customer filter processes only the mobile auth namespace, so customer tokens do not authenticate against internal APIs.

## Customer account model

`CustomerAccount` is one-to-one with the existing Customer business record and stores normalized unique email, BCrypt password hash, status, verification state, login-failure state, lock expiry, login/password timestamps, and audit timestamps. Statuses are PENDING_VERIFICATION, ACTIVE, LOCKED, and DISABLED. It has no employee Role relation. Controllers return DTOs, never entities.

Registration creates a RETAIL Customer only when no existing email match exists. One existing Customer may be linked after email ownership is proved through OTP. Because the inspected SQL dump contains duplicate historical Customer emails, multiple matches are rejected with `CUSTOMER_LINK_REVIEW_REQUIRED`; the service never guesses which record to claim. Customer codes use a distinct `CUST-APP-...` convention.

## Security configuration and schema

Catalog GETs remain public. Registration, verification, resend, login, refresh, forgot-password, reset verification, and reset-password are public exact POST paths. Logout, profile GET/PUT, and change-password require ROLE_CUSTOMER. Other mobile paths/methods are denied. Angular origin and employee login remain unchanged.

The project already uses Hibernate `ddl-auto=update`; the four new tables are `customer_accounts`, `customer_auth_otps`, `customer_refresh_tokens`, and `customer_reset_authorizations`, with unique/indexed email, customer relation, token hashes, status, purpose, and token family columns. Production migration review remains deployment work. No SQL dump was imported or modified.
