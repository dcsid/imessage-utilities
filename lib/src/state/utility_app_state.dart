import 'package:chat_utilities_hub/src/app.dart';
import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';

import 'package:flutter/foundation.dart';

class UtilityAppState extends ChangeNotifier {
  UtilityAppState({required UtilityRepository repository})
    : _repository = repository,
      _isHydrated = repository.isHydrated;

  final UtilityRepository _repository;
  String? _selectedUtilityId;
  // Deep link target stored before the repo is hydrated. Once hydration
  // completes (e.g. after a sign-in or demo activation), this gets
  // applied as the selected utility if the outing actually exists.
  String? _pendingUtilityId;
  bool _isHydrated;

  bool get isHydrated => _isHydrated;

  /// Deep-link utility id that was requested via URL but couldn't be
  /// resolved yet because the repository hadn't been hydrated. Used by
  /// the auth gate to decide whether to auto-activate a demo session.
  String? get pendingUtilityId => _pendingUtilityId;

  List<UtilityInstance> get utilities => _repository.getAll();

  UtilityInstance? get selectedUtility {
    final selectedUtilityId = _selectedUtilityId;
    if (selectedUtilityId == null) {
      return null;
    }
    return _repository.findById(selectedUtilityId);
  }

  UtilityRoutePath get currentPath {
    if (!_isHydrated) {
      // Keep the URL bar showing the deep-linked path while we wait for
      // hydration, instead of flickering back to root.
      final pending = _pendingUtilityId;
      if (pending != null) {
        return UtilityRoutePath.utility(pending);
      }
      return const UtilityRoutePath.home();
    }
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
      _pendingUtilityId = null;
      if (_selectedUtilityId != null) {
        _selectedUtilityId = null;
        notifyListeners();
      }
      return;
    }

    if (_isHydrated) {
      if (_repository.findById(utilityId) != null) {
        _pendingUtilityId = null;
        _selectedUtilityId = utilityId;
      } else {
        // Hydrated and the outing doesn't exist — give up, fall to home.
        _pendingUtilityId = null;
        _selectedUtilityId = null;
      }
      notifyListeners();
      return;
    }

    // Not hydrated yet (e.g. cold load with a deep-link URL while auth
    // is still resolving). Stash the request for after hydration.
    _pendingUtilityId = utilityId;
    notifyListeners();
  }

  void openUtility(String utilityId) {
    if (!_isHydrated) {
      return;
    }
    if (_repository.findById(utilityId) == null) {
      return;
    }

    _selectedUtilityId = utilityId;
    notifyListeners();
  }

  void removeUtility(String utilityId) {
    _repository.removeUtility(utilityId);
    if (_selectedUtilityId == utilityId) {
      _selectedUtilityId = null;
    }
    notifyListeners();
  }

  void lockTime({required String utilityId, required String optionId}) {
    final utility = _repository.lockTime(
      utilityId: utilityId,
      optionId: optionId,
    );
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void unlockTime({required String utilityId}) {
    final utility = _repository.unlockTime(utilityId: utilityId);
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void createPlanningBoard(CreatePlanningBoardInput input) {
    final utility = _repository.createPlanningBoard(input);
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  Future<void> hydrateForUser(
    String? userId, {
    Iterable<String> legacyStorageKeys = const <String>[],
  }) async {
    _isHydrated = false;
    notifyListeners();

    await _repository.hydrateForUser(
      userId,
      legacyStorageKeys: legacyStorageKeys,
    );

    final selectedUtilityId = _selectedUtilityId;
    if (selectedUtilityId != null &&
        _repository.findById(selectedUtilityId) == null) {
      _selectedUtilityId = null;
    }

    // If a deep link was queued during the empty state, fulfill it now
    // that the repo has data. Drops the pending id either way so we
    // don't keep looking for it on subsequent hydrations.
    final pending = _pendingUtilityId;
    if (pending != null) {
      if (_repository.findById(pending) != null) {
        _selectedUtilityId = pending;
      }
      _pendingUtilityId = null;
    }

    _isHydrated = true;
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
    String? address,
    String? note,
  }) {
    final utility = _repository.addTripStop(
      utilityId: utilityId,
      title: title,
      position: position,
      address: address,
      note: note,
    );
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void removeTripStop({required String utilityId, required String stopId}) {
    final utility = _repository.removeTripStop(
      utilityId: utilityId,
      stopId: stopId,
    );
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void enableExpenseTracking({required String utilityId}) {
    final utility = _repository.enableExpenseTracking(utilityId: utilityId);
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void addExpense({
    required String utilityId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> splitBetween,
    String? note,
  }) {
    final utility = _repository.addExpense(
      utilityId: utilityId,
      title: title,
      amount: amount,
      paidBy: paidBy,
      splitBetween: splitBetween,
      note: note,
    );
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void removeExpense({required String utilityId, required String expenseId}) {
    final utility = _repository.removeExpense(
      utilityId: utilityId,
      expenseId: expenseId,
    );
    _selectedUtilityId = utility.id;
    notifyListeners();
  }

  void saveLocationShare({
    required String utilityId,
    required String participantName,
    required LocationShareMode mode,
    required String stopId,
    String? statusMessage,
    required bool isBusy,
  }) {
    final utility = _repository.saveLocationShare(
      utilityId: utilityId,
      participantName: participantName,
      mode: mode,
      stopId: stopId,
      statusMessage: statusMessage,
      isBusy: isBusy,
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
