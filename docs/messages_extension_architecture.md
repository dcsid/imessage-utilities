# Messages Extension Architecture

This repository now contains the Flutter-heavy planner for a future `When2Meet + iMessage` product.

## Current split

- `Flutter app`
  - cross-platform planning surface for iPhone, Android, desktop, and web
  - full availability board, venue shortlist, checklist, and richer detail flows
  - the main product logic stays in Dart
- `Future native iOS Messages extension`
  - thin chat-native composer and response UI
  - launches the Flutter app through a utility link when someone needs the full board
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

That gives the future Messages extension a stable handoff target before we wire in a backend or universal-link domain.

## Recommended next build steps

1. Add create/respond flows for the availability board instead of seeded sample data.
2. Replace the in-memory repository with Amplify/AWS-backed reads and writes.
3. Add a native iOS Messages extension target in Xcode that creates planning links and opens the app when needed.
4. Introduce a lightweight web fallback so non-installed recipients can still respond.
