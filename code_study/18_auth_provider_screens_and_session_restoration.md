# 18. AuthProvider, Screens, and Session Restoration

AuthProvider owns initializing, guest, pending registration verification, authenticated, loading/error-related state, safe profile, pending email, cooldown assistance, and short-lived reset authorization. It blocks duplicate submissions and never retains password or OTP values.

Startup loads secure session, refreshes an expired access token once, calls `/auth/me`, and authenticates only after profile success. Invalid/corrupt/expired sessions are cleared and the app continues as guest. Public Home and catalog remain available while restoration occurs or fails.

Screens include Login, Registration, registration OTP, Forgot Password, reset OTP, Reset Password, Profile, Edit Profile, and Change Password. Forms scroll in SafeArea, validate email/Bangladesh phone/password/confirmation/Terms/OTP, expose password visibility, disable during submission, and map safe server messages. Client cooldown is assistance only; server limits remain authoritative.

Guest Menu offers Login, Create Account, Continue Browsing, Wishlist, Compare, and current-session Cart. Authenticated Menu displays safe customer identity, Profile, Edit Profile, Change Password, and Logout. Profile excludes balances, credit limits, roles, permissions, password/OTP/token state, and audit internals. Email and customer code are read-only.

Cart, Wishlist, and Compare providers remain independent app-level in-memory providers. Login/logout never clear, upload, persist, order, or claim synchronization of Phase 4 state. Change Password clears authentication and returns to guest browsing.

## 2026-07-07 false-authenticated-state correction

AuthProvider now has an explicit `expireSession()` path for sessions invalidated during protected API calls after startup. It increments the generation guard, clears secure storage, removes the safe profile and pending auth state, switches to guest, and surfaces the session-expired message. App wiring registers this callback before initialization, so an expired or rejected restored token cannot leave Menu, Cart, Checkout, or My Orders believing the customer is still authenticated.

This preserves the Phase 4/6 provider structure while preventing stale customer UI state. Cart/Wishlist/Checkout/Orders providers use safe API messages rather than raw exception strings, so protected screens either continue with valid customer data or fall back to a clean guest/login-required state.
