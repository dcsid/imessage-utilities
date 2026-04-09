import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
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

  UtilityInstance addTripStop({
    required String utilityId,
    required String title,
    required GeoPoint position,
    String? note,
  });

  UtilityInstance saveLocationShare({
    required String utilityId,
    required String participantName,
    required LocationShareMode mode,
    required String stopId,
  });

  UtilityInstance endLocationShare({
    required String utilityId,
    required String participantName,
  });
}
