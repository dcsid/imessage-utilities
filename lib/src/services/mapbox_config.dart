/// Mapbox access token, supplied at build time:
///   flutter build web --dart-define=MAPBOX_TOKEN=pk.eyJ...
/// Empty string (the default) makes the web app silently fall back to
/// OpenStreetMap tiles and disables Mapbox geocoding.
const String mapboxToken = String.fromEnvironment(
  'MAPBOX_TOKEN',
  defaultValue: '',
);

bool get hasMapboxToken => mapboxToken.isNotEmpty;

/// Tile URL template consumed by `flutter_map`. Uses Mapbox's "light-v11"
/// style when a token is available (pairs well with the cream UI), and
/// OpenStreetMap's free public tiles otherwise.
String get mapTileUrlTemplate => hasMapboxToken
    ? 'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/{z}/{x}/{y}@2x?access_token=$mapboxToken'
    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Attribution string flutter_map renders in the bottom-right of the
/// map. Required by both Mapbox and OSM ToS.
String get mapAttribution => hasMapboxToken
    ? '© Mapbox © OpenStreetMap'
    : '© OpenStreetMap contributors';
