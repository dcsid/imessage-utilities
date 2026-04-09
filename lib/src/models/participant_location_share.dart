import 'package:chat_utilities_hub/src/models/location_share_mode.dart';

class ParticipantLocationShare {
  const ParticipantLocationShare({
    required this.participantName,
    required this.mode,
    required this.stopId,
    required this.sharedAt,
  });

  final String participantName;
  final LocationShareMode mode;
  final String stopId;
  final DateTime sharedAt;

  ParticipantLocationShare copyWith({
    String? participantName,
    LocationShareMode? mode,
    String? stopId,
    DateTime? sharedAt,
  }) {
    return ParticipantLocationShare(
      participantName: participantName ?? this.participantName,
      mode: mode ?? this.mode,
      stopId: stopId ?? this.stopId,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }
}
