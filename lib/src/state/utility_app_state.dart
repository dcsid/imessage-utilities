import 'package:chat_utilities_hub/src/app.dart';
import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/planning_board_draft.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:flutter/foundation.dart';

class UtilityAppState extends ChangeNotifier {
  UtilityAppState({required UtilityRepository repository})
    : _repository = repository;

  final UtilityRepository _repository;
  String? _selectedUtilityId;
  PlanningBoardDraft? _pendingComposeDraft;

  List<UtilityInstance> get utilities => _repository.getAll();
  PlanningBoardDraft? get pendingComposeDraft => _pendingComposeDraft;

  UtilityInstance? get selectedUtility {
    final selectedUtilityId = _selectedUtilityId;
    if (selectedUtilityId == null) {
      return null;
    }
    return _repository.findById(selectedUtilityId);
  }

  UtilityRoutePath get currentPath {
    final pendingComposeDraft = _pendingComposeDraft;
    if (pendingComposeDraft != null) {
      return UtilityRoutePath.compose(pendingComposeDraft);
    }

    final selectedUtilityId = _selectedUtilityId;
    if (selectedUtilityId == null ||
        _repository.findById(selectedUtilityId) == null) {
      return const UtilityRoutePath.home();
    }

    return UtilityRoutePath.utility(selectedUtilityId);
  }

  void applyRoutePath(UtilityRoutePath routePath) {
    final composeDraft = routePath.composeDraft;
    if (composeDraft != null) {
      _selectedUtilityId = null;
      _pendingComposeDraft = composeDraft;
      notifyListeners();
      return;
    }

    if (routePath.isHome) {
      showHome();
      return;
    }

    final utilityId = routePath.utilityId;
    if (utilityId == null || _repository.findById(utilityId) == null) {
      showHome();
      return;
    }

    _selectedUtilityId = utilityId;
    _pendingComposeDraft = null;
    notifyListeners();
  }

  void openUtility(String utilityId) {
    if (_repository.findById(utilityId) == null) {
      return;
    }

    _selectedUtilityId = utilityId;
    _pendingComposeDraft = null;
    notifyListeners();
  }

  void createPlanningBoard(CreatePlanningBoardInput input) {
    final utility = _repository.createPlanningBoard(input);
    _selectedUtilityId = utility.id;
    _pendingComposeDraft = null;
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
    _pendingComposeDraft = null;
    notifyListeners();
  }

  void voteForVenue({required String utilityId, required int venueIndex}) {
    final utility = _repository.voteForVenue(
      utilityId: utilityId,
      venueIndex: venueIndex,
    );
    _selectedUtilityId = utility.id;
    _pendingComposeDraft = null;
    notifyListeners();
  }

  void addVenueOption({
    required String utilityId,
    required String name,
    required String detail,
  }) {
    final utility = _repository.addVenueOption(
      utilityId: utilityId,
      name: name,
      detail: detail,
    );
    _selectedUtilityId = utility.id;
    _pendingComposeDraft = null;
    notifyListeners();
  }

  void toggleChecklistItem({
    required String utilityId,
    required int checklistIndex,
  }) {
    final utility = _repository.toggleChecklistItem(
      utilityId: utilityId,
      checklistIndex: checklistIndex,
    );
    _selectedUtilityId = utility.id;
    _pendingComposeDraft = null;
    notifyListeners();
  }

  void addChecklistItem({
    required String utilityId,
    required String title,
    required String assignee,
  }) {
    final utility = _repository.addChecklistItem(
      utilityId: utilityId,
      title: title,
      assignee: assignee,
    );
    _selectedUtilityId = utility.id;
    _pendingComposeDraft = null;
    notifyListeners();
  }

  bool openUtilityLink(String rawLink) {
    final utilityId = UtilityLink.parseUtilityId(rawLink);
    if (utilityId != null) {
      if (_repository.findById(utilityId) == null) {
        return false;
      }

      openUtility(utilityId);
      return true;
    }

    final composeDraft = UtilityLink.parseComposeDraft(rawLink);
    if (composeDraft == null) {
      return false;
    }

    _selectedUtilityId = null;
    _pendingComposeDraft = composeDraft;
    notifyListeners();
    return true;
  }

  void clearPendingComposeDraft() {
    if (_pendingComposeDraft == null) {
      return;
    }

    _pendingComposeDraft = null;
    notifyListeners();
  }

  void showHome() {
    if (_selectedUtilityId == null && _pendingComposeDraft == null) {
      return;
    }

    _selectedUtilityId = null;
    _pendingComposeDraft = null;
    notifyListeners();
  }
}
