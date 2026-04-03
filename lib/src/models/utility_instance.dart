import 'package:chat_utilities_hub/src/models/utility_kind.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';

class UtilityInstance {
  const UtilityInstance({
    required this.id,
    required this.kind,
    required this.title,
    required this.prompt,
    required this.createdBy,
    required this.participants,
    required this.options,
    required this.responses,
    this.closesAt,
  });

  final String id;
  final UtilityKind kind;
  final String title;
  final String prompt;
  final String createdBy;
  final List<String> participants;
  final List<UtilityOption> options;
  final List<UtilityResponse> responses;
  final DateTime? closesAt;

  int get responseCount => responses.length;

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
