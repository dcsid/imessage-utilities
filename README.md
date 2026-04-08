# Chat Utilities Hub

An iPhone-first Flutter availability planner built around a `When2Meet`-style weekly board.

## Current product slice

- create a planning board
- drag across the weekly grid to fill availability
- erase availability by dragging back over selected blocks
- review overlap directly on the same board

## Run on iPhone

```bash
flutter pub get
flutter run -d <your-iphone-device-id>
```

## Verification

```bash
flutter analyze
flutter test
```

## Notes

- The repo is intentionally trimmed to the iPhone app only.
- Most product logic and UI live in Flutter and Dart.
