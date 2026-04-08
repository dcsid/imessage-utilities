import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_kind.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';

class InMemoryUtilityRepository implements UtilityRepository {
  InMemoryUtilityRepository() : _utilities = _buildSeedUtilities();

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
    final normalizedParticipants = input.participants
        .map((participant) => participant.trim())
        .where((participant) => participant.isNotEmpty)
        .toSet()
        .toList(growable: true);
    if (!normalizedParticipants.contains(createdBy)) {
      normalizedParticipants.insert(0, createdBy);
    }
    final utilityId = _slugify(input.title);
    final options = _buildOptions(
      utilityId: utilityId,
      startDate: normalizedStart,
      dayCount: input.dayCount,
      dayStart: input.dayStart,
      dayEnd: input.dayEnd,
      intervalMinutes: input.intervalMinutes,
    );
    final utility = UtilityInstance(
      id: utilityId,
      kind: UtilityKind.availability,
      title: input.title.trim(),
      prompt: input.prompt.trim().isEmpty
          ? 'Find the best overlap, then use the same board to finish the event details.'
          : input.prompt.trim(),
      eventSummary:
          'A live planning board for ${normalizedParticipants.length} people, centered on a shared availability grid and ready for iMessage handoff.',
      createdBy: createdBy,
      participants: normalizedParticipants,
      options: options,
      responses: const [],
      venueOptions: const [
        PlanningVenueOption(
          name: 'Add the first venue idea',
          detail: 'Once the winning slot is clear, use this space for the shortlist.',
          votes: 0,
        ),
      ],
      checklistItems: [
        PlanningChecklistItem(
          title: 'Share the board back into Messages',
          assignee: createdBy,
          isComplete: false,
        ),
        PlanningChecklistItem(
          title: 'Confirm the winning time window',
          assignee: createdBy,
          isComplete: false,
        ),
      ],
      planningUpdates: const [
        PlanningUpdate(
          title: 'Created in Flutter',
          detail:
              'This board was created in the Flutter planner, and the same deep link can later be dropped into iMessage.',
        ),
        PlanningUpdate(
          title: 'Respond from any device',
          detail:
              'Each participant can fill in their availability here first while the native Messages entry point is still being built.',
        ),
      ],
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
    if (!utility.participants.contains(participantName)) {
      throw StateError('Unknown participant "$participantName" for $utilityId');
    }
    final responses = utility.responses.toList(growable: true);
    final existingIndex = responses.indexWhere(
      (response) => response.participantName == participantName,
    );
    final nextResponse = UtilityResponse(
      participantName: participantName,
      respondedAt: DateTime.now(),
      selectedOptionIds: Set<String>.from(selectedOptionIds),
    );

    if (existingIndex == -1) {
      responses.add(nextResponse);
    } else {
      responses[existingIndex] = nextResponse;
    }

    final updatedUtility = utility.copyWith(responses: responses);
    _utilities[index] = updatedUtility;
    return updatedUtility;
  }

  @override
  UtilityInstance voteForVenue({
    required String utilityId,
    required int venueIndex,
  }) {
    final index = _indexForUtility(utilityId);
    final utility = _utilities[index];
    if (venueIndex < 0 || venueIndex >= utility.venueOptions.length) {
      throw RangeError.index(venueIndex, utility.venueOptions, 'venueIndex');
    }

    final nextVenueOptions = utility.venueOptions.toList(growable: true);
    final existing = nextVenueOptions[venueIndex];
    nextVenueOptions[venueIndex] = existing.copyWith(votes: existing.votes + 1);

    final updatedUtility = utility.copyWith(venueOptions: nextVenueOptions);
    _utilities[index] = updatedUtility;
    return updatedUtility;
  }

  @override
  UtilityInstance addVenueOption({
    required String utilityId,
    required String name,
    required String detail,
  }) {
    final index = _indexForUtility(utilityId);
    final utility = _utilities[index];
    final nextVenueOptions = utility.venueOptions.toList(growable: true)
      ..add(
        PlanningVenueOption(
          name: name.trim(),
          detail: detail.trim(),
          votes: 0,
        ),
      );

    final updatedUtility = utility.copyWith(venueOptions: nextVenueOptions);
    _utilities[index] = updatedUtility;
    return updatedUtility;
  }

  @override
  UtilityInstance toggleChecklistItem({
    required String utilityId,
    required int checklistIndex,
  }) {
    final index = _indexForUtility(utilityId);
    final utility = _utilities[index];
    if (checklistIndex < 0 || checklistIndex >= utility.checklistItems.length) {
      throw RangeError.index(
        checklistIndex,
        utility.checklistItems,
        'checklistIndex',
      );
    }

    final nextChecklist = utility.checklistItems.toList(growable: true);
    final existing = nextChecklist[checklistIndex];
    nextChecklist[checklistIndex] = existing.copyWith(
      isComplete: !existing.isComplete,
    );

    final updatedUtility = utility.copyWith(checklistItems: nextChecklist);
    _utilities[index] = updatedUtility;
    return updatedUtility;
  }

  @override
  UtilityInstance addChecklistItem({
    required String utilityId,
    required String title,
    required String assignee,
  }) {
    final index = _indexForUtility(utilityId);
    final utility = _utilities[index];
    final nextChecklist = utility.checklistItems.toList(growable: true)
      ..add(
        PlanningChecklistItem(
          title: title.trim(),
          assignee: assignee.trim(),
          isComplete: false,
        ),
      );

    final updatedUtility = utility.copyWith(checklistItems: nextChecklist);
    _utilities[index] = updatedUtility;
    return updatedUtility;
  }

  static List<UtilityInstance> _buildSeedUtilities() {
    return [
      UtilityInstance(
        id: 'spring-launch-dinner',
        kind: UtilityKind.availability,
        title: 'Spring launch dinner',
        prompt:
            'Lock the best overlap first, then move straight into the venue vote and day-of details without losing the thread.',
        eventSummary:
            'A real planning board for a six-person dinner, starting with a When2Meet-style grid and expanding into venue picks, reminders, and guest coordination.',
        createdBy: 'Maya',
        participants: const ['Maya', 'Jordan', 'Ari', 'Nina', 'Chris', 'Lena'],
        closesAt: DateTime(2026, 4, 9, 22),
        options: [
          UtilityOption(
            id: 'thu-600',
            title: 'Thu, Apr 9',
            subtitle: '6:00 PM - 6:30 PM',
            sortOrder: 1,
            startAt: DateTime(2026, 4, 9, 18),
            endAt: DateTime(2026, 4, 9, 18, 30),
          ),
          UtilityOption(
            id: 'thu-630',
            title: 'Thu, Apr 9',
            subtitle: '6:30 PM - 7:00 PM',
            sortOrder: 2,
            startAt: DateTime(2026, 4, 9, 18, 30),
            endAt: DateTime(2026, 4, 9, 19),
          ),
          UtilityOption(
            id: 'thu-700',
            title: 'Thu, Apr 9',
            subtitle: '7:00 PM - 7:30 PM',
            sortOrder: 3,
            startAt: DateTime(2026, 4, 9, 19),
            endAt: DateTime(2026, 4, 9, 19, 30),
          ),
          UtilityOption(
            id: 'thu-730',
            title: 'Thu, Apr 9',
            subtitle: '7:30 PM - 8:00 PM',
            sortOrder: 4,
            startAt: DateTime(2026, 4, 9, 19, 30),
            endAt: DateTime(2026, 4, 9, 20),
          ),
          UtilityOption(
            id: 'fri-600',
            title: 'Fri, Apr 10',
            subtitle: '6:00 PM - 6:30 PM',
            sortOrder: 5,
            startAt: DateTime(2026, 4, 10, 18),
            endAt: DateTime(2026, 4, 10, 18, 30),
          ),
          UtilityOption(
            id: 'fri-630',
            title: 'Fri, Apr 10',
            subtitle: '6:30 PM - 7:00 PM',
            sortOrder: 6,
            startAt: DateTime(2026, 4, 10, 18, 30),
            endAt: DateTime(2026, 4, 10, 19),
          ),
          UtilityOption(
            id: 'fri-700',
            title: 'Fri, Apr 10',
            subtitle: '7:00 PM - 7:30 PM',
            sortOrder: 7,
            startAt: DateTime(2026, 4, 10, 19),
            endAt: DateTime(2026, 4, 10, 19, 30),
          ),
          UtilityOption(
            id: 'fri-730',
            title: 'Fri, Apr 10',
            subtitle: '7:30 PM - 8:00 PM',
            sortOrder: 8,
            startAt: DateTime(2026, 4, 10, 19, 30),
            endAt: DateTime(2026, 4, 10, 20),
          ),
          UtilityOption(
            id: 'sat-1200',
            title: 'Sat, Apr 11',
            subtitle: '12:00 PM - 12:30 PM',
            sortOrder: 9,
            startAt: DateTime(2026, 4, 11, 12),
            endAt: DateTime(2026, 4, 11, 12, 30),
          ),
          UtilityOption(
            id: 'sat-1230',
            title: 'Sat, Apr 11',
            subtitle: '12:30 PM - 1:00 PM',
            sortOrder: 10,
            startAt: DateTime(2026, 4, 11, 12, 30),
            endAt: DateTime(2026, 4, 11, 13),
          ),
          UtilityOption(
            id: 'sat-100',
            title: 'Sat, Apr 11',
            subtitle: '1:00 PM - 1:30 PM',
            sortOrder: 11,
            startAt: DateTime(2026, 4, 11, 13),
            endAt: DateTime(2026, 4, 11, 13, 30),
          ),
          UtilityOption(
            id: 'sat-130',
            title: 'Sat, Apr 11',
            subtitle: '1:30 PM - 2:00 PM',
            sortOrder: 12,
            startAt: DateTime(2026, 4, 11, 13, 30),
            endAt: DateTime(2026, 4, 11, 14),
          ),
          UtilityOption(
            id: 'sun-1200',
            title: 'Sun, Apr 12',
            subtitle: '12:00 PM - 12:30 PM',
            sortOrder: 13,
            startAt: DateTime(2026, 4, 12, 12),
            endAt: DateTime(2026, 4, 12, 12, 30),
          ),
          UtilityOption(
            id: 'sun-1230',
            title: 'Sun, Apr 12',
            subtitle: '12:30 PM - 1:00 PM',
            sortOrder: 14,
            startAt: DateTime(2026, 4, 12, 12, 30),
            endAt: DateTime(2026, 4, 12, 13),
          ),
          UtilityOption(
            id: 'sun-100',
            title: 'Sun, Apr 12',
            subtitle: '1:00 PM - 1:30 PM',
            sortOrder: 15,
            startAt: DateTime(2026, 4, 12, 13),
            endAt: DateTime(2026, 4, 12, 13, 30),
          ),
          UtilityOption(
            id: 'sun-130',
            title: 'Sun, Apr 12',
            subtitle: '1:30 PM - 2:00 PM',
            sortOrder: 16,
            startAt: DateTime(2026, 4, 12, 13, 30),
            endAt: DateTime(2026, 4, 12, 14),
          ),
        ],
        responses: [
          UtilityResponse(
            participantName: 'Maya',
            respondedAt: DateTime(2026, 4, 7, 10, 10),
            selectedOptionIds: const {
              'fri-630',
              'fri-700',
              'sat-1230',
              'sat-100',
              'sun-1200',
            },
          ),
          UtilityResponse(
            participantName: 'Jordan',
            respondedAt: DateTime(2026, 4, 7, 10, 22),
            selectedOptionIds: const {
              'fri-600',
              'fri-630',
              'fri-700',
              'sat-1200',
              'sat-1230',
            },
          ),
          UtilityResponse(
            participantName: 'Ari',
            respondedAt: DateTime(2026, 4, 7, 10, 28),
            selectedOptionIds: const {
              'thu-700',
              'thu-730',
              'fri-700',
              'fri-730',
              'sat-1230',
            },
          ),
          UtilityResponse(
            participantName: 'Nina',
            respondedAt: DateTime(2026, 4, 7, 10, 35),
            selectedOptionIds: const {
              'fri-630',
              'fri-700',
              'sat-1230',
              'sat-100',
              'sun-1230',
            },
          ),
          UtilityResponse(
            participantName: 'Chris',
            respondedAt: DateTime(2026, 4, 7, 10, 42),
            selectedOptionIds: const {
              'fri-700',
              'sat-1200',
              'sat-1230',
              'sat-100',
              'sun-1200',
            },
          ),
        ],
        venueOptions: const [
          PlanningVenueOption(
            name: 'Veranda Rooftop',
            detail: 'Outdoor tables, near the office, can hold six at 7 PM.',
            votes: 4,
          ),
          PlanningVenueOption(
            name: 'Otto Pasta House',
            detail: 'Best backup if we land on a Friday dinner slot.',
            votes: 3,
          ),
          PlanningVenueOption(
            name: 'Kumo Karaoke',
            detail: 'Late-night fallback if the overlap drifts past 8 PM.',
            votes: 2,
          ),
        ],
        checklistItems: const [
          PlanningChecklistItem(
            title: 'Confirm final headcount in Messages',
            assignee: 'Jordan',
            isComplete: true,
          ),
          PlanningChecklistItem(
            title: 'Place the rooftop hold once a time wins',
            assignee: 'Maya',
            isComplete: false,
          ),
          PlanningChecklistItem(
            title: 'Send parking and dress note',
            assignee: 'Chris',
            isComplete: false,
          ),
          PlanningChecklistItem(
            title: 'Bring candles and the welcome sign',
            assignee: 'Nina',
            isComplete: true,
          ),
        ],
        planningUpdates: const [
          PlanningUpdate(
            title: 'Start in iMessage',
            detail:
                'The native Messages extension will create this board directly inside the group thread, so the first step feels like a chat action instead of a full app launch.',
          ),
          PlanningUpdate(
            title: 'Use Flutter for the full board',
            detail:
                'Once people need the full grid, venue shortlist, and checklist, the share link opens this richer Dart-based planning surface.',
          ),
          PlanningUpdate(
            title: 'Keep planning in one thread',
            detail:
                'After the winning slot is clear, the same plan can power a venue vote, reminders, and final guest updates without starting a second workflow.',
          ),
        ],
      ),
    ];
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
        final title = _formatDayTitle(day);
        final subtitle =
            '${_formatTime(startAt)} - ${_formatTime(endAt)}';
        options.add(
          UtilityOption(
            id: '$utilityId-$sortOrder',
            title: title,
            subtitle: subtitle,
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
