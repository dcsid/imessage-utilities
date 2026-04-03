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
      id: 'design-sprint-sync',
      kind: UtilityKind.availability,
      title: 'Design sprint sync',
      prompt:
          'Find the cleanest 30-minute overlap for a Messages thread without kicking everyone into another app.',
      createdBy: 'Maya',
      participants: const ['Maya', 'Jordan', 'Ari', 'Nina', 'Chris'],
      closesAt: DateTime(2026, 4, 6, 21),
      options: [
        UtilityOption(
          id: 'tue-530',
          title: 'Tue, Apr 7',
          subtitle: '5:30 PM - 6:00 PM',
          sortOrder: 1,
          startAt: DateTime(2026, 4, 7, 17, 30),
          endAt: DateTime(2026, 4, 7, 18),
        ),
        UtilityOption(
          id: 'tue-600',
          title: 'Tue, Apr 7',
          subtitle: '6:00 PM - 6:30 PM',
          sortOrder: 2,
          startAt: DateTime(2026, 4, 7, 18),
          endAt: DateTime(2026, 4, 7, 18, 30),
        ),
        UtilityOption(
          id: 'wed-500',
          title: 'Wed, Apr 8',
          subtitle: '5:00 PM - 5:30 PM',
          sortOrder: 3,
          startAt: DateTime(2026, 4, 8, 17),
          endAt: DateTime(2026, 4, 8, 17, 30),
        ),
        UtilityOption(
          id: 'wed-630',
          title: 'Wed, Apr 8',
          subtitle: '6:30 PM - 7:00 PM',
          sortOrder: 4,
          startAt: DateTime(2026, 4, 8, 18, 30),
          endAt: DateTime(2026, 4, 8, 19),
        ),
        UtilityOption(
          id: 'thu-545',
          title: 'Thu, Apr 9',
          subtitle: '5:45 PM - 6:15 PM',
          sortOrder: 5,
          startAt: DateTime(2026, 4, 9, 17, 45),
          endAt: DateTime(2026, 4, 9, 18, 15),
        ),
      ],
      responses: [
        UtilityResponse(
          participantName: 'Maya',
          respondedAt: DateTime(2026, 4, 3, 11, 10),
          selectedOptionIds: const {'tue-530', 'wed-500', 'thu-545'},
        ),
        UtilityResponse(
          participantName: 'Jordan',
          respondedAt: DateTime(2026, 4, 3, 11, 20),
          selectedOptionIds: const {'tue-600', 'wed-500', 'wed-630'},
        ),
        UtilityResponse(
          participantName: 'Ari',
          respondedAt: DateTime(2026, 4, 3, 11, 22),
          selectedOptionIds: const {'wed-500', 'wed-630', 'thu-545'},
        ),
        UtilityResponse(
          participantName: 'Nina',
          respondedAt: DateTime(2026, 4, 3, 11, 35),
          selectedOptionIds: const {'tue-530', 'wed-500'},
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
