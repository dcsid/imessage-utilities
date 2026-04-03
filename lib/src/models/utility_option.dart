class UtilityOption {
  const UtilityOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sortOrder,
    this.startAt,
    this.endAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final int sortOrder;
  final DateTime? startAt;
  final DateTime? endAt;
}
