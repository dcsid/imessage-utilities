import 'package:chat_utilities_hub/src/models/geo_point.dart';

class TripPlaceMatch {
  const TripPlaceMatch({
    required this.title,
    required this.subtitle,
    required this.position,
  });

  final String title;
  final String subtitle;
  final GeoPoint position;

  factory TripPlaceMatch.fromMap(Map<Object?, Object?> map) {
    return TripPlaceMatch(
      title: (map['title'] as String?)?.trim() ?? '',
      subtitle: (map['subtitle'] as String?)?.trim() ?? '',
      position: GeoPoint(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      ),
    );
  }

  String get primaryLabel => title.trim().isEmpty ? subtitle : title;

  String? get secondaryLabel => subtitle.trim().isEmpty ? null : subtitle.trim();
}
