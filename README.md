# iMessage Utilities

A Flutter-first event planning app built around a real `When2Meet`-style availability board, with a thin native iMessage draft extension handing the full flow into Flutter.

This slice now treats scheduling as the main product, then layers in the planning tools that normally come right after: venue voting, reminders, and guest updates.

## Current architecture

- `Flutter app`
  - cross-platform planner for iPhone, Android, desktop, and web
  - seeded `When2Meet`-style board plus create-your-own planning boards
  - live availability responses with overlap scoring
  - venue voting and checklist actions on the same event board
  - deep-link routing for Messages handoff and compose drafts
- `Native iMessage extension`
  - compact in-chat composer for title, organizer, and participants
  - inserts a planning card into the thread
  - opens the Flutter planner to finish creating the board
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

## Current deep links

The app is ready to open utility links like:

`chatutilitieshub://utility/spring-launch-dinner?kind=availability`

And Messages compose drafts like:

`chatutilitieshub://compose?title=Game%20Night&createdBy=Maya&participants=Maya,Jordan,Ari`

## Current product slice

- create a new planning board from Flutter
- fill in participant availability directly on the board
- review ranked overlap to find the best slot
- vote on venue options without leaving the event
- add checklist tasks and mark them complete
- open a prefilled create-board flow from an iMessage draft link
- use the same deep-link contract the native Messages extension now sends

## Verification

```bash
flutter analyze
flutter test
```

## Notes

- The iMessage extension target now exists under [ios/MessagesExtension/Info.plist]([redacted-path] and [ios/MessagesExtension/MessagesViewController.swift]([redacted-path]
- Most product logic and UI stay in Flutter and Dart.
- AWS/Amplify integration is not wired yet.
- A mobile web fallback for non-installed recipients is still planned.
