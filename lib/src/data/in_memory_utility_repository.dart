import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';

class InMemoryUtilityRepository implements UtilityRepository {
  InMemoryUtilityRepository() : _utilities = <UtilityInstance>[];

  final List<UtilityInstance> _utilities;

  @override
  List<UtilityInstance> getAll() => List.unmodifiable(_utilities);

  @override
  UtilityInstance? findById(String id) {
    for (final utility in _utilities) {
      if (utility.id == id) {
        return utility;
      }
    }
    return null;
  }

  @override
  UtilityInstance createPlanningBoard(CreatePlanningBoardInput input) {
    final normalizedStart = DateTime(
      input.startDate.year,
      input.startDate.month,
      input.startDate.day,
    );
    final createdBy = input.createdBy.trim();
    final participants = input.participants
        .map((participant) => participant.trim())
        .where((participant) => participant.isNotEmpty)
        .toSet()
        .toList(growable: true);
    if (!participants.contains(createdBy)) {
      participants.insert(0, createdBy);
    }

    final utilityId = _slugify(input.title);
    final utility = UtilityInstance(
      id: utilityId,
      title: input.title.trim(),
      createdBy: createdBy,
      participants: participants,
      options: _buildOptions(
        utilityId: utilityId,
        startDate: normalizedStart,
        dayCount: input.dayCount,
        dayStart: input.dayStart,
        dayEnd: input.dayEnd,
        intervalMinutes: input.intervalMinutes,
      ),
      responses: const [],
      closesAt: normalizedStart
          .add(Duration(days: input.dayCount - 1))
          .add(input.dayEnd),
    );

    _utilities.insert(0, utility);
    return utility;
  }

  @override
  UtilityInstance saveResponse({
    required String utilityId,
    required String participantName,
    required Set<String> selectedOptionIds,
  }) {
    final index = _indexForUtility(utilityId);
    final utility = _utilities[index];
    final normalizedName = participantName.trim();
    final participants = utility.participants.toList(growable: true);
    if (!participants.contains(normalizedName)) {
      participants.add(normalizedName);
    }

    final responses = utility.responses.toList(growable: true);
    final responseIndex = responses.indexWhere(
      (response) => response.participantName == normalizedName,
    );
    final nextResponse = UtilityResponse(
      participantName: normalizedName,
      respondedAt: DateTime.now(),
      selectedOptionIds: Set<String>.from(selectedOptionIds),
    );

    if (responseIndex == -1) {
      responses.add(nextResponse);
    } else {
      responses[responseIndex] = nextResponse;
    }

    final updatedUtility = utility.copyWith(
      participants: participants,
      responses: responses,
    );
    _utilities[index] = updatedUtility;
    return updatedUtility;
  }

  static List<UtilityOption> _buildOptions({
    required String utilityId,
    required DateTime startDate,
    required int dayCount,
    required Duration dayStart,
    required Duration dayEnd,
    required int intervalMinutes,
  }) {
    final options = <UtilityOption>[];
    var sortOrder = 1;
    for (var dayIndex = 0; dayIndex < dayCount; dayIndex++) {
      final day = startDate.add(Duration(days: dayIndex));
      var cursor = dayStart;
      while (cursor < dayEnd) {
        final startAt = day.add(cursor);
        final endAt = startAt.add(Duration(minutes: intervalMinutes));
        options.add(
          UtilityOption(
            id: '$utilityId-$sortOrder',
            title: _formatDayTitle(day),
            subtitle: '${_formatTime(startAt)} - ${_formatTime(endAt)}',
            sortOrder: sortOrder,
            startAt: startAt,
            endAt: endAt,
          ),
        );
        sortOrder += 1;
        cursor += Duration(minutes: intervalMinutes);
      }
    }
    return options;
  }

  static String _slugify(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty
        ? 'plan-${DateTime.now().millisecondsSinceEpoch}'
        : '$normalized-${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _formatDayTitle(DateTime day) {
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthLabels = [
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
    return '${weekdayLabels[day.weekday - 1]}, ${monthLabels[day.month - 1]} ${day.day}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  int _indexForUtility(String utilityId) {
    final index = _utilities.indexWhere((utility) => utility.id == utilityId);
    if (index == -1) {
      throw StateError('Unknown utility id: $utilityId');
    }
    return index;
  }
}
