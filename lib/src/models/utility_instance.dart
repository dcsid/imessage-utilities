import 'package:chat_utilities_hub/src/models/utility_kind.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';

class UtilityInstance {
  const UtilityInstance({
    required this.id,
    required this.kind,
    required this.title,
    required this.prompt,
    required this.eventSummary,
    required this.createdBy,
    required this.participants,
    required this.options,
    required this.responses,
    required this.venueOptions,
    required this.checklistItems,
    required this.planningUpdates,
    this.closesAt,
  });

  final String id;
  final UtilityKind kind;
  final String title;
  final String prompt;
  final String eventSummary;
  final String createdBy;
  final List<String> participants;
  final List<UtilityOption> options;
  final List<UtilityResponse> responses;
  final List<PlanningVenueOption> venueOptions;
  final List<PlanningChecklistItem> checklistItems;
  final List<PlanningUpdate> planningUpdates;
  final DateTime? closesAt;

  int get responseCount => responses.length;

  int get pendingResponseCount => participants.length - responseCount;

  UtilityResponse? responseForParticipant(String participantName) {
    for (final response in responses) {
      if (response.participantName == participantName) {
        return response;
      }
    }
    return null;
  }

  UtilityInstance copyWith({
    String? id,
    UtilityKind? kind,
    String? title,
    String? prompt,
    String? eventSummary,
    String? createdBy,
    List<String>? participants,
    List<UtilityOption>? options,
    List<UtilityResponse>? responses,
    List<PlanningVenueOption>? venueOptions,
    List<PlanningChecklistItem>? checklistItems,
    List<PlanningUpdate>? planningUpdates,
    DateTime? closesAt,
  }) {
    return UtilityInstance(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      eventSummary: eventSummary ?? this.eventSummary,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      options: options ?? this.options,
      responses: responses ?? this.responses,
      venueOptions: venueOptions ?? this.venueOptions,
      checklistItems: checklistItems ?? this.checklistItems,
      planningUpdates: planningUpdates ?? this.planningUpdates,
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
        .toList();

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

class PlanningVenueOption {
  const PlanningVenueOption({
    required this.name,
    required this.detail,
    required this.votes,
  });

  final String name;
  final String detail;
  final int votes;

  PlanningVenueOption copyWith({String? name, String? detail, int? votes}) {
    return PlanningVenueOption(
      name: name ?? this.name,
      detail: detail ?? this.detail,
      votes: votes ?? this.votes,
    );
  }
}

class PlanningChecklistItem {
  const PlanningChecklistItem({
    required this.title,
    required this.assignee,
    required this.isComplete,
  });

  final String title;
  final String assignee;
  final bool isComplete;

  PlanningChecklistItem copyWith({
    String? title,
    String? assignee,
    bool? isComplete,
  }) {
    return PlanningChecklistItem(
      title: title ?? this.title,
      assignee: assignee ?? this.assignee,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class PlanningUpdate {
  const PlanningUpdate({required this.title, required this.detail});

  final String title;
  final String detail;
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
