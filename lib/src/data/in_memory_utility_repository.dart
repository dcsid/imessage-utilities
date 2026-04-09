import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/participant_location_share.dart';
import 'package:chat_utilities_hub/src/models/trip_stop.dart';
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
      plannedStops: const [],
      locationShares: const [],
      closesAt: normalizedStart
          .add(Duration(days: input.dayCount - 1))
          .add(input.dayEnd),
    );

    _utilities.insert(0, utility);
    return utility;
  }

  @override
  UtilityInstance addTripStop({
    required String utilityId,
    required String title,
    required GeoPoint position,
    String? note,
  }) {
    final index = _indexForUtility(utilityId);
    final utility = _utilities[index];
    final stops = utility.plannedStops.toList(growable: true);
    stops.add(
      TripStop(
        id: '${utility.id}-stop-${stops.length + 1}-${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(),
        note: _normalizedNote(note),
        position: position,
        order: stops.length + 1,
      ),
    );

    final updatedUtility = utility.copyWith(plannedStops: stops);
    _utilities[index] = updatedUtility;
    return updatedUtility;
  }

  @override
  UtilityInstance saveLocationShare({
    required String utilityId,
    required String participantName,
    required LocationShareMode mode,
    required String stopId,
  }) {
    final index = _indexForUtility(utilityId);
    final utility = _utilities[index];
    final stop = utility.stopById(stopId);
    if (stop == null) {
      throw StateError('Unknown stop id: $stopId');
    }

    final normalizedName = participantName.trim();
    final participants = utility.participants.toList(growable: true);
    if (!participants.contains(normalizedName)) {
      participants.add(normalizedName);
    }

    final shares = utility.locationShares.toList(growable: true);
    final existingIndex = shares.indexWhere(
      (share) => share.participantName == normalizedName,
    );
    final nextShare = ParticipantLocationShare(
      participantName: normalizedName,
      mode: mode,
      stopId: stop.id,
      sharedAt: DateTime.now(),
    );

    if (existingIndex == -1) {
      shares.add(nextShare);
    } else {
      shares[existingIndex] = nextShare;
    }

    final updatedUtility = utility.copyWith(
      participants: participants,
      locationShares: shares,
    );
    _utilities[index] = updatedUtility;
    return updatedUtility;
  }

  @override
  UtilityInstance endLocationShare({
    required String utilityId,
    required String participantName,
  }) {
    final index = _indexForUtility(utilityId);
    final utility = _utilities[index];
    final shares = utility.locationShares
        .where((share) => share.participantName != participantName.trim())
        .toList(growable: false);
    final updatedUtility = utility.copyWith(locationShares: shares);
    _utilities[index] = updatedUtility;
    return updatedUtility;
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

  static String? _normalizedNote(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int _indexForUtility(String utilityId) {
    final index = _utilities.indexWhere((utility) => utility.id == utilityId);
    if (index == -1) {
      throw StateError('Unknown utility id: $utilityId');
    }
    return index;
  }
}
