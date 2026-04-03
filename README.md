# iMessage Utilities

A Flutter companion app for a future Messages-first utility product.

This first slice is centered on a `When2Meet`-style availability utility, but the app is structured around a reusable `utility` model so we can expand into polls, checklists, and other group-chat tools later.

## Current architecture

- `Flutter app`
  - cross-platform companion app for iPhone, Android, desktop, and web
  - seeded availability prototype
  - deep-link routing for utility handoff
- `Future native iMessage extension`
  - compact in-chat utility UI
  - launches the app for deeper workflows
- `Future AWS backend`
  - auth, shared utility records, responses, notifications, and analytics

## Run locally

```bash
flutter pub get
flutter run -d macos
```

You can also run it in Chrome:

```bash
flutter run -d chrome
```

## Current deep link

The app is ready to open utility links like:

`chatutilitieshub://utility/design-sprint-sync?kind=availability`

## Verification

```bash
flutter analyze
flutter test
```

## Notes

- The iMessage extension is not built yet.
- AWS/Amplify integration is not wired yet.
- A mobile web fallback for non-installed recipients is still planned.
