import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/participant_location_share.dart';
import 'package:chat_utilities_hub/src/models/trip_stop.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';

class UtilityInstance {
  const UtilityInstance({
    required this.id,
    required this.title,
    required this.createdBy,
    required this.participants,
    required this.options,
    required this.responses,
    this.plannedStops = const [],
    this.locationShares = const [],
    this.closesAt,
  });

  final String id;
  final String title;
  final String createdBy;
  final List<String> participants;
  final List<UtilityOption> options;
  final List<UtilityResponse> responses;
  final List<TripStop> plannedStops;
  final List<ParticipantLocationShare> locationShares;
  final DateTime? closesAt;

  int get responseCount => responses.length;

  int get pendingResponseCount => participants.length - responseCount;

  int get stopCount => plannedStops.length;

  int get activeLocationShareCount => resolvedLocationShares.length;

  DateTime? get startsAt {
    DateTime? first;
    for (final option in options) {
      final startAt = option.startAt;
      if (startAt == null) {
        continue;
      }
      if (first == null || startAt.isBefore(first)) {
        first = startAt;
      }
    }
    return first;
  }

  DateTime? get endsAt {
    DateTime? last;
    for (final option in options) {
      final endAt = option.endAt;
      if (endAt == null) {
        continue;
      }
      if (last == null || endAt.isAfter(last)) {
        last = endAt;
      }
    }
    return last;
  }

  UtilityResponse? responseForParticipant(String participantName) {
    for (final response in responses) {
      if (response.participantName == participantName) {
        return response;
      }
    }
    return null;
  }

  TripStop? stopById(String stopId) {
    for (final stop in plannedStops) {
      if (stop.id == stopId) {
        return stop;
      }
    }
    return null;
  }

  ParticipantLocationShare? locationShareForParticipant(String participantName) {
    for (final share in locationShares) {
      if (share.participantName == participantName) {
        return share;
      }
    }
    return null;
  }

  List<ResolvedParticipantLocation> get resolvedLocationShares {
    final resolved = <ResolvedParticipantLocation>[];
    for (final share in locationShares) {
      final stop = stopById(share.stopId);
      if (stop == null) {
        continue;
      }
      resolved.add(
        ResolvedParticipantLocation(
          share: share,
          stop: stop,
        ),
      );
    }
    return resolved;
  }

  UtilityInstance copyWith({
    String? id,
    String? title,
    String? createdBy,
    List<String>? participants,
    List<UtilityOption>? options,
    List<UtilityResponse>? responses,
    List<TripStop>? plannedStops,
    List<ParticipantLocationShare>? locationShares,
    DateTime? closesAt,
  }) {
    return UtilityInstance(
      id: id ?? this.id,
      title: title ?? this.title,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      options: options ?? this.options,
      responses: responses ?? this.responses,
      plannedStops: plannedStops ?? this.plannedStops,
      locationShares: locationShares ?? this.locationShares,
      closesAt: closesAt ?? this.closesAt,
    );
  }

  List<UtilityOptionScore> get optionScores {
    final scores = options
        .map(
          (option) => UtilityOptionScore(
            option: option,
            votes: selectionCountForOption(option.id),
            responders: respondersForOption(option.id),
          ),
        )
        .toList(growable: false);

    scores.sort((left, right) {
      final voteCompare = right.votes.compareTo(left.votes);
      if (voteCompare != 0) {
        return voteCompare;
      }
      return left.option.sortOrder.compareTo(right.option.sortOrder);
    });

    return scores;
  }

  int selectionCountForOption(String optionId) {
    return responses
        .where((response) => response.selectedOptionIds.contains(optionId))
        .length;
  }

  List<String> respondersForOption(String optionId) {
    return responses
        .where((response) => response.selectedOptionIds.contains(optionId))
        .map((response) => response.participantName)
        .toList(growable: false);
  }
}

class ResolvedParticipantLocation {
  const ResolvedParticipantLocation({
    required this.share,
    required this.stop,
  });

  final ParticipantLocationShare share;
  final TripStop stop;

  String get participantName => share.participantName;

  LocationShareMode get mode => share.mode;

  DateTime get sharedAt => share.sharedAt;
}

class UtilityOptionScore {
  const UtilityOptionScore({
    required this.option,
    required this.votes,
    required this.responders,
  });

  final UtilityOption option;
  final int votes;
  final List<String> responders;

  double coverage(int totalParticipants) {
    if (totalParticipants == 0) {
      return 0;
    }

    return votes / totalParticipants;
  }
}
