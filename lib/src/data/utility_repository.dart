import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';

abstract class UtilityRepository {
  bool get isHydrated;

  Future<void> hydrateForUser(
    String? userId, {
    Iterable<String> legacyStorageKeys = const <String>[],
  });

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
    String? address,
    String? note,
  });

  UtilityInstance removeTripStop({
    required String utilityId,
    required String stopId,
  });

  UtilityInstance enableExpenseTracking({required String utilityId});

  UtilityInstance addExpense({
    required String utilityId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> splitBetween,
    String? note,
  });

  UtilityInstance removeExpense({
    required String utilityId,
    required String expenseId,
  });

  UtilityInstance saveLocationShare({
    required String utilityId,
    required String participantName,
    required LocationShareMode mode,
    required String stopId,
    String? statusMessage,
    required bool isBusy,
  });

  UtilityInstance endLocationShare({
    required String utilityId,
    required String participantName,
  });
}
