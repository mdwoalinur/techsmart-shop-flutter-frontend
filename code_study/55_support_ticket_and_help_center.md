# 55 - Support Ticket and Help Center

Phase 12 adds authenticated customer support tickets and a public help/FAQ center while keeping existing payment, fulfillment, order, cart, wishlist, wallet, notification, and offer logic unchanged.

## Support tickets

The support ticket flow uses authenticated mobile APIs under `/api/mobile/v1/support`:

- list current customer tickets
- create a new ticket
- open ticket detail
- reply to a ticket
- close a ticket

Customer identity comes from the JWT session. The client does not submit customer IDs. Ticket detail and messages are scoped to the authenticated customer by the backend.

Flutter support files:

- `SupportTicketSummary`, `SupportTicketDetail`, and `SupportTicketMessage`
- `SupportService`
- `SupportProvider`
- Help & Support ticket list, create form, detail, reply, and close screens

`SupportProvider` clears ticket list/detail state on logout to prevent account bleed between sessions.

## FAQ/help center

The FAQ layer is public/customer-safe and backend-driven:

- FAQ list/search screen
- FAQ detail screen
- `HelpFaq` model
- `HelpService`
- `HelpProvider`

Search is local over the loaded help-center dataset so the user can quickly filter questions by title, question, answer, category, or tags without changing backend state.

## Navigation

Menu and Profile now link to:

- My Reviews
- Help & Support
- FAQ / Help Center

Notification actions also understand support/review action types when backend notifications provide those actions.
