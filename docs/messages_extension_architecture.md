# Messages Extension Architecture

This repository now contains the Flutter companion app for a future Messages-first utility product.

## Current split

- `Flutter app`
  - cross-platform shell for iPhone and Android
  - utility browsing, deep-link entry, and richer detail flows
  - reusable `utility` domain model so availability is only v1
- `Future native iOS Messages extension`
  - compact chat-native composer and response UI
  - launches the Flutter app through a utility link when a workflow becomes too deep for Messages
- `Future AWS backend`
  - shared utility records, membership, responses, notifications, and analytics

## Why this shape

- A Messages extension is iOS-specific and should stay lightweight.
- Flutter remains the main product surface and can grow beyond iMessage.
- The app data model is intentionally generic:
  - `UtilityKind`
  - `UtilityInstance`
  - `UtilityOption`
  - `UtilityResponse`

That lets us add polls, checklists, and other utilities later without replacing the app shell.

## Current link contract

The app is ready to parse links shaped like:

`chatutilitieshub://utility/<utility-id>?kind=availability`

That gives the future Messages extension a stable handoff target before we wire in a backend or universal-link domain.

## Recommended next build steps

1. Add create/respond flows for availability instead of seeded sample data.
2. Replace the in-memory repository with Amplify/AWS-backed reads and writes.
3. Add a native iOS Messages extension target in Xcode that creates utility links and opens the app when needed.
4. Introduce a lightweight web fallback so non-installed recipients can still respond.
