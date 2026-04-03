enum UtilityKind {
  availability(
    label: 'Availability',
    blurb: 'Find overlap quickly from inside a chat thread.',
  ),
  poll(
    label: 'Polls',
    blurb: 'Fast picks for yes/no or multiple-choice decisions.',
  ),
  checklist(
    label: 'Checklists',
    blurb: 'Shared lightweight coordination for plans and trips.',
  ),
  picks(
    label: 'Group picks',
    blurb: 'Restaurants, movies, and activities that need a winner.',
  );

  const UtilityKind({required this.label, required this.blurb});

  final String label;
  final String blurb;
}
