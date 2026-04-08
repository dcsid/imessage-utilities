import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';

abstract class UtilityRepository {
  List<UtilityInstance> getAll();

  UtilityInstance? findById(String id);

  UtilityInstance createPlanningBoard(CreatePlanningBoardInput input);

  UtilityInstance saveResponse({
    required String utilityId,
    required String participantName,
    required Set<String> selectedOptionIds,
  });

  UtilityInstance voteForVenue({
    required String utilityId,
    required int venueIndex,
  });

  UtilityInstance addVenueOption({
    required String utilityId,
    required String name,
    required String detail,
  });

  UtilityInstance toggleChecklistItem({
    required String utilityId,
    required int checklistIndex,
  });

  UtilityInstance addChecklistItem({
    required String utilityId,
    required String title,
    required String assignee,
  });
}
