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
}
