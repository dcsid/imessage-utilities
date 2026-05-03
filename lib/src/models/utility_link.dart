class UtilityLink {
  const UtilityLink._();

  /// Custom URL scheme registered in `ios/Runner/Info.plist`. Reserved
  /// for in-app deep linking on iOS — does not work in browsers, in
  /// iMessage, or on devices where the app is not installed.
  static const String scheme = 'chatutilitieshub';

  static const String utilityHost = 'utility';

  /// Public web host used when generating shareable links. Defaults to
  /// the live Amplify Hosting URL; can be overridden at build time via
  /// `--dart-define=PUBLIC_WEB_HOST=plantogether.app` if you ever wire
  /// up a custom domain.
  static const String webHost = String.fromEnvironment(
    'PUBLIC_WEB_HOST',
    defaultValue: 'main.d3pi3iif6jv5s3.amplifyapp.com',
  );

  /// Build a sharable link to a specific outing. Returns an HTTPS URL
  /// pointing at the live web demo so the link works in any browser.
  /// On iOS, the same path opens the native app via Universal Links if
  /// they're configured (currently they aren't — Universal Links require
  /// a paid Apple Developer Program), and falls back to the web demo
  /// otherwise.
  static Uri forUtility(String utilityId) {
    return Uri(
      scheme: 'https',
      host: webHost,
      pathSegments: [utilityHost, utilityId],
    );
  }

  static String? parseUtilityId(String rawLink) {
    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null) {
      return null;
    }

    final segments = normalizedSegments(uri);
    if (segments.length < 2 || segments.first != utilityHost) {
      return null;
    }

    return segments[1];
  }

  /// Normalize URI segments across the three forms we accept:
  ///   - `chatutilitieshub://utility/<id>`     (legacy iOS deep link)
  ///   - `https://<host>/utility/<id>`         (web invite link)
  ///   - `/utility/<id>`                       (in-app router path)
  ///
  /// For the legacy custom scheme, the URI parser stashes the logical
  /// first segment in `host`, so we copy it back to the front of the
  /// path. For HTTPS URLs, `host` is the actual domain name and must
  /// not pollute the path segments.
  static List<String> normalizedSegments(Uri uri) {
    final pathSegments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (uri.scheme == scheme && uri.host.isNotEmpty) {
      return [uri.host, ...pathSegments];
    }
    return pathSegments;
  }
}
