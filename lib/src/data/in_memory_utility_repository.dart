import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_kind.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';

class InMemoryUtilityRepository implements UtilityRepository {
  InMemoryUtilityRepository() : _utilities = _seedUtilities;

  final List<UtilityInstance> _utilities;

  static final List<UtilityInstance> _seedUtilities = [
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
  List<UtilityInstance> getAll() => List.unmodifiable(_utilities);
}
