# iMessage Utilities

A Flutter-first event planning app built around a real `When2Meet`-style availability board, with future iMessage integration as the fastest sharing surface.

This slice now treats scheduling as the main product, then layers in the planning tools that normally come right after: venue voting, reminders, and guest updates.

## Current architecture

- `Flutter app`
  - cross-platform planner for iPhone, Android, desktop, and web
  - seeded `When2Meet`-style board plus create-your-own planning boards
  - live availability responses with overlap scoring
  - venue voting and checklist actions on the same event board
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

## Current product slice

- create a new planning board from Flutter
- fill in participant availability directly on the board
- review ranked overlap to find the best slot
- vote on venue options without leaving the event
- add checklist tasks and mark them complete
- use the same deep-link contract the future iMessage extension will send

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
