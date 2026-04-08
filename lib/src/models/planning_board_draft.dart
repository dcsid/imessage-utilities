class PlanningBoardDraft {
  const PlanningBoardDraft({
    this.title,
    this.prompt,
    this.createdBy,
    this.participants = const <String>[],
  });

  final String? title;
  final String? prompt;
  final String? createdBy;
  final List<String> participants;
}
