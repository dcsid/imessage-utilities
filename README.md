# Plan Together

iPhone-first Flutter app for coordinating group outings — pick a time, pick a place,
share where you are, split the bill. Internally still named `chat_utilities_hub`;
user-facing brand is **Plan Together**.

## Features

**Find a time**
- When2Meet-style weekly availability grid; drag to paint, drag back over to erase
- Live overlap heatmap; ranked "Best times" with vote counts
- "Lock this time" commits the chosen slot, freezes the board, and surfaces a
  prominent banner with the locked window
- "Add to Calendar" on a locked slot opens the native iOS event sheet
  (title, start/end, first planned stop as the location)
- Response identity auto-fills from the signed-in account

**Pick a place**
- Apple Maps search via `MKLocalSearch` (Swift bridge in `ios/Runner/SceneDelegate.swift`)
- Long-press the map to drop a pin; the app reverse-geocodes via `CLGeocoder`
- Stops are stored with title + address + coordinates

**Share where you are**
- Phone GPS broadcast (live or periodic) via Amplify AppSync subscriptions
- Per-participant status message + busy flag
- Live outing map shows everyone's pin and rough ETA toward the chosen destination

**Split the bill**
- Optional expense tracking (off by default — opt in per outing)
- Splitwise-style settle-up: per-person net balance strip + the fewest payments
  needed to balance everyone out, with colored participant avatars

**Manage outings**
- Landing page only shows active outings; past outings live behind an archive shelf
- Delete an outing from the action sheet on its sticker (cloud + local)

## Tech stack

- Flutter / Dart, iPhone target
- AWS Amplify Gen 2 — Cognito (email + phone), AppSync GraphQL, DynamoDB
- Apple Maps via `apple_maps_flutter` + native `MKLocalSearch`
- `geolocator` for GPS streaming
- `add_2_calendar` for the calendar-export sheet
- `google_fonts` (Fraunces display + Inter body)

## Run on iPhone

```bash
flutter pub get
flutter run -d <your-iphone-device-id>
```

iOS permissions live in `ios/Runner/Info.plist`:
- `NSLocationWhenInUseUsageDescription` — outing map / sharing
- `NSCalendarsWriteOnlyAccessUsageDescription` (+ legacy `NSCalendarsUsageDescription`)
  — calendar export

## Verification

```bash
flutter analyze
flutter test
```

## Backend (Amplify Gen 2)

The backend lives in `amplify/`. Two models in `amplify/data/resource.ts`:

- `OutingRecord` — owner-based auth; the entire outing (responses, stops, locks,
  expenses, etc.) is serialized into the `payload` JSON string
- `ParticipantLocationEvent` — owner can create/delete, any authenticated user
  can read; carries lat/lng + status for live sharing

Sandbox / deploy via the wrapper script:

```bash
npm run amplify:configure   # one-time AWS profile setup
npm run amplify:sandbox     # local dev sandbox, writes lib/amplify_outputs.dart
npm run amplify:deploy      # pipeline-deploy to the configured AWS account
```

## Repo layout

```
lib/src/
  app.dart                       # MaterialApp.router, theme, navigation
  auth/                          # Cognito controller + auth screen + identity helpers
  data/                          # repository interface, in-memory + local (cloud-sync) impls
  models/                        # UtilityInstance, OutingRecord, generated Amplify models
  presentation/                  # AppPalette, AppSurface, OutingSticker, AvailabilityBoard, TripMap, etc.
  screens/                       # HomeScreen, UtilityDetailScreen, PastOutingsScreen
  services/                      # LocationService, TripPlaceService (MethodChannel)
  state/                         # UtilityAppState (ChangeNotifier)
amplify/                         # Amplify Gen 2 backend definitions
ios/Runner/
  SceneDelegate.swift            # TripPlacesBridge (MKLocalSearch + reverseGeocode)
  Info.plist                     # location + calendar usage descriptions
test/widget_test.dart            # widget + persistence tests
```

## Known issues

- **Cloud schema drift.** `amplify/data/resource.ts` declares owner-based
  `OutingRecord` + `ParticipantLocationEvent`. The deployed AppSync at
  `amplify_outputs.json` is still on an older `UtilityInstance` schema with a
  **public API key** authorization mode. Until redeployed:
  - Anyone with the API key can read/write all outings and live locations
  - `lockTime` / `unlockTime` are persisted locally fine, but cloud writes go
    through the legacy schema
  - `removeUtility`'s `ModelMutations.deleteById` against the new schema name
    will fail silently — the local delete still works
- **Custom `SceneDelegate.swift`** (~170 lines) handles deep links and Amplify
  init quirks. If iOS startup gets weird, that's the first place to look.
- **Test coverage is light.** `test/widget_test.dart` exercises the main flows
  but there's no per-repo or per-service unit coverage yet.

## Notes

- Project directory is `Plan2Meet`; internal package name is `chat_utilities_hub`;
  user-facing brand is "Plan Together". The original repo name was
  `imessage-utilities`, and some package metadata still reflects that history.
- The repo is intentionally trimmed to the iPhone app — no Android, no web.
