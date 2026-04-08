# Messages Extension Architecture

This repository now contains the Flutter-heavy planner for a `When2Meet + iMessage` product, plus a thin native Messages extension shell.

## Current split

- `Flutter app`
  - cross-platform planning surface for iPhone, Android, desktop, and web
  - full availability board, venue shortlist, checklist, and richer detail flows
  - the main product logic stays in Dart
- `Native iOS Messages extension`
  - thin chat-native composer for a planning draft
  - inserts a Messages card with a compose handoff link
  - launches the Flutter app when someone needs the full board
- `Future AWS backend`
  - shared planning records, membership, responses, notifications, and analytics

## Why this shape

- A Messages extension is iOS-specific and should stay lightweight.
- Flutter remains the main product surface and should hold as much logic/UI as possible.
- The app data model keeps the availability board at the center while leaving room for event-planning modules around it.

That lets us ship scheduling first, then add venue voting, checklists, and guest updates without replacing the app shell.

## Current link contract

The app is ready to parse links shaped like:

`chatutilitieshub://utility/<utility-id>?kind=availability`

And compose drafts shaped like:

`chatutilitieshub://compose?title=<title>&createdBy=<name>&participants=<csv>`

That gives the Messages extension a stable handoff target before we wire in a backend or universal-link domain.

## Recommended next build steps

1. Let the Messages extension open an existing board or recent board list once the app has shared state or backend storage.
2. Replace the in-memory repository with Amplify/AWS-backed reads and writes.
3. Add a lightweight response mode inside the extension for simple availability taps before opening Flutter.
4. Introduce a lightweight web fallback so non-installed recipients can still respond.
