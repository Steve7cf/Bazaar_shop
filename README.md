# Bazaar — Flutter (UI stage)

This is the **UI-first pass**: onboarding → auth screens → home shell with
role-gated nav. No SQLite/drift, no real auth, no business logic yet — those
land in the next pass. `AuthController` and the session providers in
`lib/features/auth/providers/auth_provider.dart` are stubs (clearly marked)
so every screen is clickable end-to-end right now.

## Run it

```bash
flutter pub get
flutter run
```

No `android/` or `ios/` platform folders are included — run `flutter create .`
in this directory first if they're missing (it won't touch `lib/` or
`pubspec.yaml`), then `flutter pub get`.

## What's here

- **Design system** (`lib/core/theme/`) — the exact light/dark tokens from
  the spec (accent `#007AFF`/`#0A84FF`, always-dark sidebar, pill badges,
  soft/glow card shadows), as a Riverpod-driven `ThemeMode` with
  `shared_preferences` persistence.
- **Onboarding** (`lib/features/onboarding/`) — 3-page swipeable Lottie
  intro, skip/next, dot indicator, "seen" flag persisted locally. The three
  Lottie files in `assets/animations/` are small hand-built placeholders —
  swap them for real ones whenever you like, the `errorBuilder` fallback
  means the app won't crash if a file's ever missing.
- **Auth UI** (`lib/features/auth/`) — splash (routes to onboarding → admin
  setup → login → home based on stub providers), first-launch admin setup
  form, login form. Validation is real; the actual login/setup calls are
  stubbed with a fake delay and always succeed.
- **Home shell** (`lib/features/home/`) — dark drawer nav (role-filtered per
  spec's cashier/admin split), bottom nav for the 4 highest-traffic
  sections, and a fully-built Dashboard screen (stat cards, till tabs,
  7-day revenue chart via `fl_chart`, low-stock/top-products/recent-sales
  lists) running on mock data. Every other section (`New Sale`, `Products`,
  `Debts`, `Reports`, `Insights`, etc.) is a lightweight placeholder screen
  so the whole nav graph is navigable today.

## Next pass (business logic)

Per the spec, in this order: drift schema + DAOs → real auth (bcrypt hash,
users table) → POS cart/stock/till-split logic → sales history/void →
debts → dashboard wired to real queries → expenses/loans → reports +
PDF/Excel export → the insights math engine (Section 8) → staff/audit log.

`pubspec.yaml` already lists every package that stage needs (`drift`,
`sqlite3_flutter_libs`, `bcrypt`, `pdf`, `printing`, `excel`, `csv`,
`share_plus`, `flutter_local_notifications`) so nothing will need
re-fetching later.
