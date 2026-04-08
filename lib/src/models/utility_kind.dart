enum UtilityKind {
  availability(
    label: 'When2Meet board',
    blurb: 'Shared availability grid for locking the event time first.',
  ),
  poll(
    label: 'Venue vote',
    blurb: 'Choose the restaurant, house, or activity after time overlap is clear.',
  ),
  checklist(
    label: 'Planning checklist',
    blurb: 'Track reminders, supplies, and day-of tasks without leaving the plan.',
  ),
  picks(
    label: 'Guest updates',
    blurb: 'Keep final headcount, notes, and changes tied to the same event board.',
  );

  const UtilityKind({required this.label, required this.blurb});

  final String label;
  final String blurb;
}
