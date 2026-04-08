import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:flutter/material.dart';

class AvailabilityBoard extends StatelessWidget {
  const AvailabilityBoard({
    super.key,
    required this.utility,
    required this.accent,
    this.compact = false,
  });

  final UtilityInstance utility;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = utility.options
        .where((option) => option.startAt != null && option.endAt != null)
        .toList(growable: false);
    if (options.isEmpty) {
      return Text(
        'No availability board has been created yet.',
        style: theme.textTheme.bodyMedium?.copyWith(color: AppPalette.mutedText),
      );
    }

    final days = _uniqueDayAnchors(options);
    final timeSlots = _uniqueTimeSlots(options);
    final optionByCell = <String, UtilityOption>{
      for (final option in options) _cellKey(option): option,
    };
    final scoresById = <String, UtilityOptionScore>{
      for (final score in utility.optionScores) score.option.id: score,
    };
    final bestOptionId = utility.optionScores.first.option.id;
    final labelWidth = compact ? 68.0 : 84.0;
    final cellWidth = compact ? 82.0 : 104.0;
    final cellHeight = compact ? 58.0 : 72.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text('When2Meet-style board', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Darker cells mean more overlap. The highlighted cell is the best current slot.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: labelWidth),
                  for (final day in days)
                    _BoardDayHeader(
                      day: day,
                      width: cellWidth,
                      compact: compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (final minutes in timeSlots) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: labelWidth,
                      child: Text(
                        _formatMinutesLabel(minutes),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppPalette.mutedText,
                        ),
                      ),
                    ),
                    for (final day in days)
                      _BoardCell(
                        option: optionByCell[_cellKeyFromParts(day, minutes)],
                        score: optionByCell[_cellKeyFromParts(day, minutes)] ==
                                null
                            ? null
                            : scoresById[
                                optionByCell[_cellKeyFromParts(day, minutes)]!.id
                              ],
                        totalParticipants: utility.participants.length,
                        accent: accent,
                        width: cellWidth,
                        height: cellHeight,
                        compact: compact,
                        isBest:
                            optionByCell[_cellKeyFromParts(day, minutes)]?.id ==
                            bestOptionId,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<DateTime> _uniqueDayAnchors(List<UtilityOption> options) {
    final dayMap = <String, DateTime>{};
    for (final option in options) {
      final startAt = option.startAt!;
      final anchor = DateTime(startAt.year, startAt.month, startAt.day);
      dayMap['${anchor.year}-${anchor.month}-${anchor.day}'] = anchor;
    }
    final days = dayMap.values.toList(growable: false);
    days.sort();
    return days;
  }

  List<int> _uniqueTimeSlots(List<UtilityOption> options) {
    final minutes = options
        .map((option) {
          final startAt = option.startAt!;
          return startAt.hour * 60 + startAt.minute;
        })
        .toSet()
        .toList(growable: false);
    minutes.sort();
    return minutes;
  }

  String _cellKey(UtilityOption option) {
    final startAt = option.startAt!;
    return _cellKeyFromParts(
      DateTime(startAt.year, startAt.month, startAt.day),
      startAt.hour * 60 + startAt.minute,
    );
  }

  String _cellKeyFromParts(DateTime day, int minutes) {
    return '${day.year}-${day.month}-${day.day}-$minutes';
  }

  String _formatMinutesLabel(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return formatTime(DateTime(2026, 1, 1, hour, minute));
  }
}

class _BoardDayHeader extends StatelessWidget {
  const _BoardDayHeader({
    required this.day,
    required this.width,
    required this.compact,
  });

  final DateTime day;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final weekdayLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthLabels = const [
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

    return Container(
      width: width,
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Column(
        children: [
          Text(
            weekdayLabels[day.weekday - 1],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.mutedText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${monthLabels[day.month - 1]} ${day.day}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppPalette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.option,
    required this.score,
    required this.totalParticipants,
    required this.accent,
    required this.width,
    required this.height,
    required this.compact,
    required this.isBest,
  });

  final UtilityOption? option;
  final UtilityOptionScore? score;
  final int totalParticipants;
  final Color accent;
  final double width;
  final double height;
  final bool compact;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverage = score?.coverage(totalParticipants) ?? 0;
    final fillColor = option == null
        ? Colors.white.withValues(alpha: 0.48)
        : Color.lerp(Colors.white, accent, 0.12 + (coverage * 0.58))!;
    final foreground = coverage >= 0.42 ? Colors.white : AppPalette.text;
    final subtext = coverage >= 0.42
        ? Colors.white.withValues(alpha: 0.82)
        : AppPalette.mutedText;

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(
          color: isBest ? accent : AppPalette.border,
          width: isBest ? 1.6 : 1,
        ),
        boxShadow: isBest
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: option == null
          ? Center(
              child: Text(
                '—',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppPalette.mutedText,
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 8 : 10,
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${score?.votes ?? 0}/$totalParticipants',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!compact)
                            Text(
                              'available',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subtext,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (isBest)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: foreground.withValues(
                            alpha: compact ? 0.14 : 0.18,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          compact ? 'Top' : 'Best',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
