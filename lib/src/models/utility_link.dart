class UtilityLink {
  const UtilityLink._();

  static const String scheme = 'chatutilitieshub';
  static const String utilityHost = 'utility';

  static Uri forUtility(String utilityId, {String? kind}) {
    return Uri(
      scheme: scheme,
      host: utilityHost,
      pathSegments: [utilityId],
      queryParameters: kind == null ? null : {'kind': kind},
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

  static List<String> normalizedSegments(Uri uri) {
    final pathSegments = uri.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    if (uri.scheme.isEmpty || uri.host.isEmpty) {
      return pathSegments.toList(growable: false);
    }

    return [uri.host, ...pathSegments];
  }
}
