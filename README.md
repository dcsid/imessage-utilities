# iMessage Utilities

A Flutter-first event planning app built around a real `When2Meet`-style availability board, with future iMessage integration as the fastest sharing surface.

This slice now treats scheduling as the main product, then layers in the planning tools that normally come right after: venue voting, reminders, and guest updates.

## Current architecture

- `Flutter app`
  - cross-platform planner for iPhone, Android, desktop, and web
  - seeded `When2Meet`-style board
  - event-planning modules around the same board
  - deep-link routing for Messages handoff
- `Future native iMessage extension`
  - compact in-chat creation and response UI
  - launches the Flutter planner for deeper workflows
- `Future AWS backend`
  - auth, shared plan records, responses, notifications, and analytics

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

`chatutilitieshub://utility/spring-launch-dinner?kind=availability`

## Verification

```bash
flutter analyze
flutter test
```

## Notes

- The iMessage extension is still a future native iOS shell.
- Most product logic and UI stay in Flutter and Dart.
- AWS/Amplify integration is not wired yet.
- A mobile web fallback for non-installed recipients is still planned.
