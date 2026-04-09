import 'package:chat_utilities_hub/src/app.dart';
import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';

import 'package:flutter/foundation.dart';

class UtilityAppState extends ChangeNotifier {
  UtilityAppState({required UtilityRepository repository})
    : _repository = repository;

  final UtilityRepository _repository;
  String? _selectedUtilityId;

  List<UtilityInstance> get utilities => _repository.getAll();

  UtilityInstance? get selectedUtility {
    final selectedUtilityId = _selectedUtilityId;
    if (selectedUtilityId == null) {
      return null;
    }
    return _repository.findById(selectedUtilityId);
  }

  UtilityRoutePath get currentPath {
    final selectedUtilityId = _selectedUtilityId;
    if (selectedUtilityId == null ||
        _repository.findById(selectedUtilityId) == null) {
      return const UtilityRoutePath.home();
    }
    return UtilityRoutePath.utility(selectedUtilityId);
  }

  void applyRoutePath(UtilityRoutePath routePath) {
    final utilityId = routePath.utilityId;
    if (utilityId == null) {
      showHome();
      return;
    }

    if (_repository.findById(utilityId) == null) {
      showHome();
      return;
    }

    _selectedUtilityId = utilityId;
    notifyListeners();
  }

  void openUtility(String utilityId) {
    if (_repository.findById(utilityId) == null) {
      return;
    }

    _selectedUtilityId = utilityId;
    notifyListeners();
  }

  void createPlanningBoard(CreatePlanningBoardInput input) {
    final utility = _repository.createPlanningBoard(input);
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void saveResponse({
    required String utilityId,
    required String participantName,
    required Set<String> selectedOptionIds,
  }) {
    final utility = _repository.saveResponse(
      utilityId: utilityId,
      participantName: participantName,
      selectedOptionIds: selectedOptionIds,
    );
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void addTripStop({
    required String utilityId,
    required String title,
    required GeoPoint position,
    String? note,
  }) {
    final utility = _repository.addTripStop(
      utilityId: utilityId,
      title: title,
      position: position,
      note: note,
    );
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void saveLocationShare({
    required String utilityId,
    required String participantName,
    required LocationShareMode mode,
    required String stopId,
  }) {
    final utility = _repository.saveLocationShare(
      utilityId: utilityId,
      participantName: participantName,
      mode: mode,
      stopId: stopId,
    );
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void endLocationShare({
    required String utilityId,
    required String participantName,
  }) {
    final utility = _repository.endLocationShare(
      utilityId: utilityId,
      participantName: participantName,
    );
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void showHome() {
    if (_selectedUtilityId == null) {
      return;
    }

    _selectedUtilityId = null;
    notifyListeners();
  }
}
