class UtilityResponse {
  const UtilityResponse({
    required this.participantName,
    required this.respondedAt,
    required this.selectedOptionIds,
  });

  final String participantName;
  final DateTime respondedAt;
  final Set<String> selectedOptionIds;
}
