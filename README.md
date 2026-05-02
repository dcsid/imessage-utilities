# Plan Together

A single Flutter codebase that ships an iPhone app and a web app from the same `lib/`. The product is a group-outing coordinator: pick a time on a When2Meet-style availability board, lock the winning slot, plan a route on a map, broadcast (or just watch) live location, and settle shared expenses — all backed by AWS Amplify Gen 2.

> **Live demo:** *deploying — link will land here once Amplify Hosting comes up.* On the auth screen click **Browse the demo** for a stateless sandbox seeded with four sample outings; no sign-up required.

Internally still named `chat_utilities_hub`; user-facing brand is **Plan Together**.

---

## What the product does

**Find a time.** Drag-paint your availability across a weekly grid; the board overlays an aggregated heatmap so the group can see the consensus window. The top-ranked slot can be **locked** — that freezes the choice, surfaces a prominent header banner on every device, and exposes a one-tap "Add to Calendar" action. On iPhone that opens the native `EKEventEditViewController`; on web it generates an RFC 5545 `.ics` and triggers a browser download.

**Pick a place.** Each outing has a planned route of typed stops. iPhone uses Apple Maps via `apple_maps_flutter` plus a custom Swift `MKLocalSearch` bridge for autocompletion and `CLGeocoder` for long-press-to-drop-pin reverse geocoding. The web app uses `flutter_map` rendering Mapbox tiles (or OpenStreetMap when no Mapbox token is configured) and Mapbox's Geocoding API for search.

**Share where you are.** When the outing is active, participants on iPhone can broadcast GPS — live or periodic — into AppSync as `ParticipantLocationEvent` records, which everyone subscribes to and renders as moving pins on the live map. The web build is intentionally **viewer-only**: a browser tab can't reliably keep streaming GPS once the page is closed, so web participants see everyone else's pins but don't try to publish their own.

**Split the bill.** Optional per-outing expense tracking with a Splitwise-style settle-up: per-person net balance strip + the minimum number of payments required to balance the group out, computed via a simple greedy debtor/creditor matching algorithm. Each participant gets a deterministic colored avatar derived from a hash of their name so identity is consistent across screens.

**Manage outings.** The landing page partitions outings into *active* (`closesAt`/`endsAt` in the future) and *past* — past ones live behind an archive shelf so the dashboard stays focused on what matters now. Each outing card has an action sheet with **Copy invite link** and **Delete outing** (destructive, confirmed).

---

## Architecture highlights

**One Dart codebase, two platforms.** The app entry is `lib/main.dart`. Platform-specific behaviour is split via `kIsWeb` runtime checks for cheap branches and Dart's `import … if (dart.library.html) …` conditional imports for cases where a dependency only exists on one side. For example, `lib/src/services/calendar_export_service.dart` declares an interface and lazily resolves `instance` to either:

- `calendar_export_service_io.dart` — wraps `add_2_calendar` to invoke the iOS calendar sheet, or
- `calendar_export_service_web.dart` — generates iCalendar text and triggers a `<a download>` click via `dart:html`.

The same pattern fences off `apple_maps_flutter` from web builds (where it would fail to register a platform view) — `lib/src/presentation/trip_map.dart` and `live_outing_map.dart` ship Apple Maps on iPhone and `flutter_map` widgets on the web.

**Repository pattern with cloud sync.** `lib/src/data/utility_repository.dart` defines the persistence interface. `InMemoryUtilityRepository` is the in-memory baseline (used by tests and by the demo session). `LocalUtilityRepository` extends it to add SharedPreferences caching plus AppSync write-through: every mutation schedules a `_persistCurrentUserUtilities` and a `_syncUtilityToCloud`, both `unawaited` so the UI stays snappy. Hydration on sign-in merges local-cached and remote-fetched outings by id.

**Demo session bypass.** A reserved `userId = 'demo-session'` (constant on `AuthController`) flips the controller into a stateless sandbox: no Cognito calls, no SharedPreferences writes, no AppSync mutations. `LocalUtilityRepository.hydrateForUser` short-circuits when it sees that id and replaces the working set with `buildDemoOutings()` — four pre-built `UtilityInstance` records that exercise every product surface (locked time, expenses with non-trivial settle-up, archived past outing, in-progress board). Edits stay in memory for the session and disappear on sign-out.

**Owner-based auth schema.** Both Amplify models in `amplify/data/resource.ts` use Cognito user-pool auth (`defaultAuthorizationMode: 'userPool'`). `OutingRecord` is `allow.owner()`-only — every outing's `payload` (a JSON-encoded `UtilityInstance`) is private to its creator. `ParticipantLocationEvent` allows owners to create and delete, and any authenticated user to read, so an invited group member can subscribe to live pins without being able to fabricate them. This replaced an earlier API-key-as-default schema that would have exposed every outing to anyone who pulled the bundle.

**Email-only Cognito.** `amplify/auth/resource.ts` declares `loginWith: { email: true }` and `accountRecovery: 'EMAIL_ONLY'`. SMS-based phone auth is intentionally absent because Cognito SMS verification routes through Amazon SNS at a per-message rate with no meaningful free tier — for a portfolio project that has no business model, exposing that cost surface isn't worth the marginal UX.

**Theme system.** `lib/src/presentation/app_palette.dart` defines a warm cream-paper canvas, ink text, and an `OutingAccent` palette of eight saturated brand colors (sunset, cobalt, fern, plum, marigold, teal, rose, pine). `AppPalette.accentFor(seed)` maps any string id to a deterministic accent via a 31-multiplier hash, so each outing has a stable visual identity. `AppSurface` renders the "sticker card" primitive used everywhere — thick ink stroke, hard 5×6 paper-edge drop shadow, plus a wider colored bloom tinted by the active accent. Typography pairs Fraunces (display) with Inter (body) via `google_fonts`.

---

## Tech stack

| Area | iOS | Web |
| --- | --- | --- |
| Framework | Flutter / Dart | Flutter / Dart |
| Maps | `apple_maps_flutter` (MapKit) | `flutter_map` + Mapbox tiles (OSM fallback) |
| Place search | Native `MKLocalSearch` via `MethodChannel` | Mapbox Geocoding API |
| Reverse geocode | `CLGeocoder` | Mapbox Geocoding API |
| GPS | `geolocator` (broadcaster) | `geolocator` (viewer-only) |
| Calendar export | `add_2_calendar` (`EKEventEditViewController`) | RFC 5545 `.ics` download |
| Auth | Amplify Cognito (email-only) | Amplify Cognito (email-only) |
| Sync | AppSync GraphQL + DynamoDB | AppSync GraphQL + DynamoDB |
| Hosting | Sideload (Apple Development cert) | AWS Amplify Hosting |
| Typography | `google_fonts` (Fraunces + Inter) | `google_fonts` (Fraunces + Inter) |

---

## Repo layout

```
lib/src/
  app.dart                       MaterialApp.router, theme, route delegate
  auth/
    auth_controller.dart         ChangeNotifier wrapping Amplify.Auth + demo-session bypass
    auth_screen.dart             Sign-in/up/confirm/reset; "Browse demo" entry
    identity_helpers.dart        Display-name extraction from email
  data/
    utility_repository.dart      Persistence interface
    in_memory_utility_repository.dart
    local_utility_repository.dart  SharedPreferences + AppSync write-through
    demo_seed.dart               Four pre-built UtilityInstance records
    utility_serialization.dart   JSON round-trip for cloud payloads
  models/                        UtilityInstance, OutingRecord, generated Amplify models
  presentation/
    app_palette.dart             Cream/ink system + OutingAccent palette
    app_surface.dart             Sticker card primitive + StickerHeader + OutingGlyph
    outing_sticker.dart          Shared outing card (vivid + muted variants)
    availability_board.dart      Drag-painted weekly grid with overlap heatmap
    trip_map.dart                Trip planning map (Apple Maps on iOS, web fallback shell)
    live_outing_map.dart         Live participant pins (Apple Maps on iOS, web shell)
    web_map.dart                 flutter_map-based WebTripMap + WebLiveOutingMap
    expense_tracking_panel.dart  Splitwise settle-up + per-person balance strip
    trip_planning_panel.dart     Stop list + location-share controls
  screens/
    home_screen.dart             Editorial dashboard with active/archive split
    past_outings_screen.dart     Archive view (muted sticker variant)
    utility_detail_screen.dart   Per-outing detail: board, lock banner, trip, expenses
  services/
    location_service.dart        GPS broadcast (iOS) / viewer (web) singleton
    trip_place_service.dart      MethodChannel + Mapbox HTTP fallback
    calendar_export_service.dart Conditional-import facade
      calendar_export_service_io.dart   add_2_calendar wrapper
      calendar_export_service_web.dart  RFC 5545 .ics generator
    mapbox_config.dart           Token + tile URL + attribution
    mapbox_geocoding.dart        Forward + reverse geocoding HTTP
  state/
    utility_app_state.dart       ChangeNotifier orchestrating routing + repo
amplify/                         Amplify Gen 2 backend (TypeScript)
  auth/resource.ts               Cognito user pool (email-only)
  data/resource.ts               OutingRecord + ParticipantLocationEvent schemas
  backend.ts                     defineBackend({auth, data})
amplify.yml                      AWS Amplify Hosting build spec
ios/Runner/
  AppDelegate.swift
  SceneDelegate.swift            TripPlacesBridge: MKLocalSearch + CLGeocoder
  Info.plist                     Location + calendar usage descriptions
web/                             Flutter web bootstrap (auto-generated)
test/widget_test.dart            Widget + persistence coverage
```

---

## Run locally

### iPhone

```bash
flutter pub get
flutter run -d <your-iphone-device-id>
```

iOS permissions (`ios/Runner/Info.plist`):
- `NSLocationWhenInUseUsageDescription` — outing map / live sharing
- `NSCalendarsWriteOnlyAccessUsageDescription` (+ legacy `NSCalendarsUsageDescription`) — calendar export

### Web

```bash
flutter pub get
flutter config --enable-web   # one-time
flutter run -d chrome --dart-define=MAPBOX_TOKEN=$MAPBOX_TOKEN
```

`MAPBOX_TOKEN` is **optional**:

| With token | Without token |
| --- | --- |
| Mapbox `light-v11` raster tiles | OpenStreetMap public tiles |
| Mapbox Geocoding (forward + reverse) | Place search returns empty list |

Get a free public token (50k loads + 100k geocodes / mo) at [account.mapbox.com/access-tokens](https://account.mapbox.com/access-tokens/).

### Verification

```bash
flutter analyze
flutter test
flutter build web
```

---

## Backend (Amplify Gen 2)

Two GraphQL models in `amplify/data/resource.ts`:

| Model | Auth | Shape |
| --- | --- | --- |
| `OutingRecord` | `allow.owner()` | `title`, `createdBy`, `payload` (JSON-encoded `UtilityInstance`), `closesAt` |
| `ParticipantLocationEvent` | owner can create/delete; authenticated read | `participantName`, `utilityId`, `lat/lng`, `speedMps`, `shareMode`, `statusMessage`, `isBusy`, `sharedAt`, `expiresAt` |

Auth in `amplify/auth/resource.ts`: Cognito user pool with email-only login, `EMAIL_ONLY` recovery, no MFA, no SMS path.

Sandbox / deploy:

```bash
aws sso login --profile amplify     # if SSO has expired
npm run amplify:sandbox             # local dev sandbox; regenerates lib/amplify_outputs.dart
npm run amplify:deploy              # pipeline-deploy to the configured AWS account
```

After redeploying, **rebuild the iOS app** — `lib/amplify_outputs.dart` ships baked into the bundle and the previous Cognito client ID will be invalidated.

---

## Web deploy (AWS Amplify Hosting)

`amplify.yml` configures the AWS Amplify Hosting build:

1. Clones Flutter from the stable channel (cached in `~/flutter` between builds).
2. Runs `flutter pub get`.
3. Runs `flutter build web --release --dart-define=MAPBOX_TOKEN=$MAPBOX_TOKEN`.
4. Publishes `build/web` as the static artifact.

In the Amplify Console:

1. Connect the GitHub repo (`dcsid/Plan2Meet`, branch `main`). The console auto-detects `amplify.yml`.
2. Add a `MAPBOX_TOKEN` environment variable under **App settings → Environment variables** — without it, the deployed site falls back to OSM tiles and place search returns empty.
3. Add a SPA rewrite under **App settings → Rewrites and redirects** so deep-link refreshes don't 404:
   - Source: `</^[^.]+$|\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|woff2|ttf|map|json|webp)$)([^.]+$)/>`
   - Target: `/index.html`
   - Type: `200 (Rewrite)`

The site comes up at `https://main.<app-id>.amplifyapp.com`.

---

## Known issues and decisions

- **iOS code-sign on iCloud-synced project folders.** This repo lives in `~/Documents`, which is iCloud Drive-managed by default on macOS. iCloud's file provider continually re-tags files in `build/` with `com.apple.fileprovider.fpfs#P` and `com.apple.FinderInfo`, which causes `codesign` to fail with `resource fork, Finder information, or similar detritus not allowed`. The fix on the to-do list is moving the project out of the iCloud-synced tree (e.g., to `~/Developer/`); for now, only the web build is publicly deployed.
- **Test coverage is light.** `test/widget_test.dart` exercises the main flows (board paint, expense balance computation, persistence round-trip) but per-repository and per-service unit coverage is limited.
- **`SceneDelegate.swift` is non-trivial (~170 lines).** It owns the `TripPlacesBridge` that backs Apple Maps search, plus deep-link handling and Amplify init ordering. If iOS startup gets weird, that's the first place to look.
- **Live location is iPhone-only on purpose.** Browsers can't keep `geolocation.watchPosition` running once a tab closes; offering the feature on web would create silent expectation gaps. Web users see other people's pins but don't try to publish their own.
- **Mapbox token is optional.** OSM tiles are fine for casual demoing; Mapbox is recommended only because the `light-v11` style pairs better with the cream UI and because Mapbox's geocoding is meaningfully faster than the free Nominatim alternative.

---

## Notes

- Project directory: `Plan2Meet`. Internal package name: `chat_utilities_hub`. User-facing brand: "Plan Together". The original repo name was `imessage-utilities`, and some package metadata still reflects that history.
- The web build is shaped for a portfolio demo, not production. The Amplify backend runs in a sandbox stack scoped to the developer's AWS account, free-tier-shaped (Cognito's free tier covers 50k MAUs, AppSync covers 250k requests/mo, DynamoDB covers 25 GB).
- Cost guardrails: a $1.00 monthly AWS budget alarm is recommended.
