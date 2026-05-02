# Plan Together

Flutter app for coordinating group outings — pick a time, pick a place,
share where you are, split the bill. iPhone-first, with a Flutter web
build that runs the same Dart codebase in the browser. Internally still
named `chat_utilities_hub`; user-facing brand is **Plan Together**.

## Features

**Find a time**
- When2Meet-style weekly availability grid; drag to paint, drag back over to erase
- Live overlap heatmap; ranked "Best times" with vote counts
- "Lock this time" commits the chosen slot, freezes the board, and surfaces a
  prominent banner with the locked window
- "Add to Calendar" on a locked slot opens the native iOS event sheet on
  iPhone, or downloads an `.ics` file on web
- Response identity auto-fills from the signed-in account

**Pick a place**
- iOS: Apple Maps search via `MKLocalSearch` (Swift bridge in
  `ios/Runner/SceneDelegate.swift`); long-press a pin to reverse-geocode via
  `CLGeocoder`
- Web: raster tiles via `flutter_map` (Mapbox if a token is set, OpenStreetMap
  otherwise); place search via Mapbox Geocoding when a token is set
- Stops are stored with title + address + coordinates

**Share where you are**
- iOS: GPS broadcast (live or periodic) via Amplify AppSync subscriptions
- Web: viewer-only — sees everyone else's pins, can't broadcast (browsers
  can't keep GPS streaming after a tab closes)
- Per-participant status message + busy flag
- Live outing map shows everyone's pin and rough ETA toward the chosen destination

**Split the bill**
- Optional expense tracking (off by default — opt in per outing)
- Splitwise-style settle-up: per-person net balance strip + the fewest payments
  needed to balance everyone out, with colored participant avatars

**Manage outings**
- Landing page only shows active outings; past outings live behind an archive shelf
- Delete an outing from the action sheet on its sticker (cloud + local)
- "Browse the demo" button on the auth screen drops new visitors into a
  pre-seeded sandbox session — no account required

## Tech stack

- Flutter / Dart, iPhone + web targets
- AWS Amplify Gen 2 — Cognito (email-only auth), AppSync GraphQL, DynamoDB
- Apple Maps via `apple_maps_flutter` (iOS only) + native `MKLocalSearch`
- `flutter_map` for web tile rendering
- Mapbox tiles + Geocoding API on web (optional, falls back to OSM tiles)
- `geolocator` for GPS (iOS) / browser geolocation (web)
- `add_2_calendar` (iOS) + custom `.ics` generator (web)
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

## Run on the web

```bash
flutter pub get
flutter config --enable-web   # one-time
flutter run -d chrome --dart-define=MAPBOX_TOKEN=$MAPBOX_TOKEN
```

The `MAPBOX_TOKEN` env var is **optional**:
- Without it: maps use OpenStreetMap tiles, place search returns nothing
- With it: maps use Mapbox's `light-v11` style and place search hits the
  Mapbox Geocoding API

Get a public token (starts with `pk.eyJ`) free at
[account.mapbox.com/access-tokens](https://account.mapbox.com/access-tokens/).

## Verification

```bash
flutter analyze
flutter test
flutter build web --dart-define=MAPBOX_TOKEN=$MAPBOX_TOKEN
```

## Backend (Amplify Gen 2)

The backend lives in `amplify/`. Two models in `amplify/data/resource.ts`:

- `OutingRecord` — owner-based auth; the entire outing (responses, stops,
  locks, expenses, etc.) is serialized into the `payload` JSON string
- `ParticipantLocationEvent` — owner can create/delete, any authenticated
  user can read; carries lat/lng + status for live sharing

Auth (`amplify/auth/resource.ts`) is **email-only** by design. SMS / phone
verification was removed because Cognito SMS goes through Amazon SNS at a
per-message cost with no meaningful free tier.

Sandbox / deploy via the wrapper script:

```bash
aws sso login --profile amplify       # if SSO has expired
npm run amplify:sandbox                # local dev sandbox, writes lib/amplify_outputs.dart
npm run amplify:deploy                 # pipeline-deploy to the configured AWS account
```

After redeploying, **iOS rebuild required** — `lib/amplify_outputs.dart`
gets regenerated and the running app needs the new Cognito client ID.

## Deploy the web app to AWS Amplify Hosting

`amplify.yml` at the repo root configures the build for AWS Amplify Hosting.
First-time setup:

1. Push this branch to GitHub.
2. AWS Console → Amplify → "Create new app" → "Deploy your app" → connect
   the GitHub repo.
3. Amplify auto-detects `amplify.yml` and uses it as the build spec.
4. Under "App settings → Environment variables", add `MAPBOX_TOKEN` with
   your public Mapbox token. Optional but recommended.
5. Under "App settings → Rewrites and redirects", add a single SPA rewrite:
   - Source: `</^[^.]+$|\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|woff2|ttf|map|json|webp)$)([^.]+$)/>`
   - Target: `/index.html`
   - Type: `200 (Rewrite)`
6. Trigger a deploy. The site comes up at `https://<branch>.<app-id>.amplifyapp.com`.

## Repo layout

```
lib/src/
  app.dart                       # MaterialApp.router, theme, navigation
  auth/                          # Cognito controller + auth screen + identity helpers
                                 # + demo-session bypass
  data/                          # repository interface, in-memory + local (cloud-sync) impls
                                 # + demo_seed.dart (sample outings)
  models/                        # UtilityInstance, OutingRecord, generated Amplify models
  presentation/                  # AppPalette, AppSurface, OutingSticker,
                                 # AvailabilityBoard, TripMap (iOS),
                                 # web_map.dart (web), etc.
  screens/                       # HomeScreen, UtilityDetailScreen, PastOutingsScreen
  services/                      # LocationService (web-safe),
                                 # TripPlaceService (MethodChannel + Mapbox HTTP fallback),
                                 # CalendarExportService (Add2Calendar / .ics),
                                 # mapbox_config.dart, mapbox_geocoding.dart
  state/                         # UtilityAppState (ChangeNotifier)
amplify/                         # Amplify Gen 2 backend definitions
amplify.yml                      # AWS Amplify Hosting build spec
ios/Runner/
  SceneDelegate.swift            # TripPlacesBridge (MKLocalSearch + reverseGeocode)
  Info.plist                     # location + calendar usage descriptions
web/                             # Flutter web bootstrap (auto-generated)
test/widget_test.dart            # widget + persistence tests
```

## Known issues

- **Cloud schema drift.** `amplify/data/resource.ts` declares owner-based
  `OutingRecord` + `ParticipantLocationEvent`. The deployed AppSync may
  still be on an older `UtilityInstance` schema with a public API key
  until the next `npm run amplify:sandbox`. Until redeployed:
  - Anyone with the API key can read/write all outings and live locations
  - `lockTime` / `unlockTime` are persisted locally fine, but cloud writes
    go through the legacy schema
  - `removeUtility`'s `ModelMutations.deleteById` against the new schema
    name will fail silently — the local delete still works
- **Custom `SceneDelegate.swift`** (~170 lines) handles deep links and
  Amplify init quirks. If iOS startup gets weird, that's the first place
  to look.
- **Test coverage is light.** `test/widget_test.dart` exercises the main
  flows but there's no per-repo or per-service unit coverage yet.

## Notes

- Project directory is `Plan2Meet`; internal package name is
  `chat_utilities_hub`; user-facing brand is "Plan Together". The
  original repo name was `imessage-utilities`, and some package metadata
  still reflects that history.
- The web build is intended for a portfolio demo. Live location broadcast
  is iPhone-only by design — the web app shows other people's pins but
  doesn't try to track yours.
