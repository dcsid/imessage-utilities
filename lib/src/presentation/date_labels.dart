import 'package:chat_utilities_hub/src/models/utility_option.dart';

const List<String> _weekdayLabels = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> _monthLabels = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatUtilityOption(UtilityOption option) {
  final startAt = option.startAt;
  final endAt = option.endAt;
  if (startAt == null || endAt == null) {
    return '${option.title} • ${option.subtitle}';
  }

  final weekday = _weekdayLabels[startAt.weekday - 1];
  final month = _monthLabels[startAt.month - 1];
  return '$weekday, $month ${startAt.day} • ${formatTime(startAt)}-${formatTime(endAt)}';
}

String formatDeadline(DateTime deadline) {
  final weekday = _weekdayLabels[deadline.weekday - 1];
  final month = _monthLabels[deadline.month - 1];
  return '$weekday, $month ${deadline.day} at ${formatTime(deadline)}';
}

String formatTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
