import 'package:chat_utilities_hub/src/app.dart';
import 'package:chat_utilities_hub/src/data/utility_repository.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
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
    notifyListeners();
  }

  void openUtility(String utilityId) {
    if (_repository.findById(utilityId) == null) {
      return;
    }

    _selectedUtilityId = utilityId;
    notifyListeners();
  }

  bool openUtilityLink(String rawLink) {
    final utilityId = UtilityLink.parseUtilityId(rawLink);
    if (utilityId == null || _repository.findById(utilityId) == null) {
      return false;
    }

    openUtility(utilityId);
    return true;
  }

  void showHome() {
    if (_selectedUtilityId == null) {
      return;
    }

    _selectedUtilityId = null;
    notifyListeners();
  }
}
