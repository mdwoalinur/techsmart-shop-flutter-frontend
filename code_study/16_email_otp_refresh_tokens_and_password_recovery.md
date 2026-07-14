# 16. Email OTP, Refresh Tokens, and Password Recovery

## OTP and mail

Customer OTPs are secure six-digit values generated with SecureRandom. Only BCrypt hashes are stored. Registration and PASSWORD_RESET purposes are distinct. Expiry, attempt maximum, resend cooldown, and resend maximum are environment-driven; defaults are 10 minutes, five attempts, 45 seconds, and five resends. New OTPs consume prior active OTPs, and consumed codes cannot be reused.

`CustomerAuthMailService` sends TechSmart Shop HTML messages for registration, password reset, and password-change confirmation through existing Spring Mail settings. Passwords, JWTs, refresh/reset tokens, hashes, SMTP values, and database IDs are not included. Mail is mocked in tests. Delivery failure leaves the account pending and consumes the unusable OTP.

## Login and refresh sessions

Email is normalized lowercase. Invalid email and password use the same response. Pending and disabled accounts are denied; repeated failures cause configurable lockout. Success resets failures and updates last login. Access JWT default lifetime is 15 minutes.

Refresh tokens are 48 random bytes returned once. Persistence contains only SHA-256 hashes, a family ID, issue/expiry/revocation dates, replacement linkage, and bounded device description. Every refresh revokes the used token and issues a replacement. Reuse of a rotated/revoked token revokes the remaining family. Multiple device families are allowed. Logout revokes the submitted session; password reset and change password revoke all sessions.

## Password recovery

Forgot Password always returns the same generic message. Eligible accounts receive a hashed reset OTP. Successful OTP verification produces a narrow random reset authorization whose SHA-256 hash is stored; it is short-lived, one-time, and is not a customer JWT. Reset validates policy, hashes the new password with BCrypt, consumes authorization, revokes sessions, and sends confirmation. Safe event names/account IDs are logged without secrets. Deployment-level IP rate limiting is still recommended in addition to account/email controls.
