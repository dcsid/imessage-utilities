import 'package:chat_utilities_hub/src/models/geo_point.dart';

class TripStop {
  const TripStop({
    required this.id,
    required this.title,
    required this.position,
    required this.order,
    this.note,
  });

  final String id;
  final String title;
  final GeoPoint position;
  final int order;
  final String? note;

  TripStop copyWith({
    String? id,
    String? title,
    GeoPoint? position,
    int? order,
    String? note,
  }) {
    return TripStop(
      id: id ?? this.id,
      title: title ?? this.title,
      position: position ?? this.position,
      order: order ?? this.order,
      note: note ?? this.note,
    );
  }
}
