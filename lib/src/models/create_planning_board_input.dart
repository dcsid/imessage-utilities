class CreatePlanningBoardInput {
  const CreatePlanningBoardInput({
    required this.title,
    required this.prompt,
    required this.createdBy,
    required this.participants,
    required this.startDate,
    required this.dayCount,
    required this.dayStart,
    required this.dayEnd,
    this.intervalMinutes = 30,
  });

  final String title;
  final String prompt;
  final String createdBy;
  final List<String> participants;
  final DateTime startDate;
  final int dayCount;
  final Duration dayStart;
  final Duration dayEnd;
  final int intervalMinutes;
}
