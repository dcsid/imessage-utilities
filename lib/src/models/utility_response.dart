class UtilityResponse {
  const UtilityResponse({
    required this.participantName,
    required this.respondedAt,
    required this.selectedOptionIds,
  });

  final String participantName;
  final DateTime respondedAt;
  final Set<String> selectedOptionIds;

  UtilityResponse copyWith({
    String? participantName,
    DateTime? respondedAt,
    Set<String>? selectedOptionIds,
  }) {
    return UtilityResponse(
      participantName: participantName ?? this.participantName,
      respondedAt: respondedAt ?? this.respondedAt,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
    );
  }
}
