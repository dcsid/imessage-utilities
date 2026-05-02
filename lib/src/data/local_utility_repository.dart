import 'dart:async';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:chat_utilities_hub/src/auth/auth_controller.dart';
import 'package:chat_utilities_hub/src/data/demo_seed.dart';
import 'package:chat_utilities_hub/src/data/in_memory_utility_repository.dart';
import 'package:chat_utilities_hub/src/data/utility_serialization.dart';
import 'package:chat_utilities_hub/src/models/OutingRecord.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUtilityRepository extends InMemoryUtilityRepository {
  LocalUtilityRepository({required SharedPreferences preferences})
    : _preferences = preferences;

  final SharedPreferences _preferences;
  final Set<String> _cloudRecordIds = <String>{};
  bool _hydrated = false;
  String? _currentUserId;

  @override
  bool get isHydrated => _hydrated;

  @override
  Future<void> hydrateForUser(
    String? userId, {
    Iterable<String> legacyStorageKeys = const <String>[],
  }) async {
    _hydrated = false;
    final normalizedUserId = _normalizeUserId(userId);
    _currentUserId = normalizedUserId;
    _cloudRecordIds.clear();
    replaceAllUtilities(const <UtilityInstance>[]);

    if (normalizedUserId == null) {
      _hydrated = true;
      return;
    }

    // Demo session — load the seed in memory and skip every cloud /
    // local-cache code path. Edits a demo user makes stay for the
    // session and disappear on sign-out.
    if (normalizedUserId == AuthController.demoUserId) {
      replaceAllUtilities(buildDemoOutings());
      _hydrated = true;
      return;
    }

    final localUtilities = _loadCachedUtilities(
      normalizedUserId,
      legacyStorageKeys: legacyStorageKeys,
    );
    if (localUtilities.isNotEmpty) {
      replaceAllUtilities(localUtilities);
    }

    final remoteUtilities = await _fetchRemoteUtilities();
    if (remoteUtilities != null) {
      final mergedUtilities = _mergeUtilities(
        localUtilities: localUtilities,
        remoteUtilities: remoteUtilities,
      );
      replaceAllUtilities(mergedUtilities);
      await _persistCurrentUserUtilities();
      unawaited(_syncUtilitiesToCloud(mergedUtilities));
    } else if (localUtilities.isNotEmpty) {
      unawaited(_syncUtilitiesToCloud(localUtilities));
    }

    _hydrated = true;
  }

  bool get _isDemoSession => _currentUserId == AuthController.demoUserId;

  @override
  UtilityInstance createPlanningBoard(CreatePlanningBoardInput input) {
    final utility = super.createPlanningBoard(input);
    _schedulePersist(utility);
    return utility;
  }

  @override
  void removeUtility(String utilityId) {
    super.removeUtility(utilityId);
    if (_isDemoSession) return;
    _cloudRecordIds.remove(utilityId);
    unawaited(_persistCurrentUserUtilities());
    unawaited(_deleteOutingRecord(utilityId));
  }

  Future<void> _deleteOutingRecord(String utilityId) async {
    if (_currentUserId == null) {
      return;
    }
    try {
      final request = ModelMutations.deleteById(
        OutingRecord.classType,
        OutingRecordModelIdentifier(id: utilityId),
        authorizationMode: APIAuthorizationType.userPools,
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.hasErrors) {
        safePrint('Delete outing error: ${response.errors}');
      }
    } catch (error) {
      safePrint('Skipping remote outing delete: $error');
    }
  }

  @override
  UtilityInstance saveResponse({
    required String utilityId,
    required String participantName,
    required Set<String> selectedOptionIds,
  }) {
    final utility = super.saveResponse(
      utilityId: utilityId,
      participantName: participantName,
      selectedOptionIds: selectedOptionIds,
    );
    _schedulePersist(utility);
    return utility;
  }

  @override
  UtilityInstance lockTime({
    required String utilityId,
    required String optionId,
  }) {
    final utility = super.lockTime(utilityId: utilityId, optionId: optionId);
    _schedulePersist(utility);
    return utility;
  }

  @override
  UtilityInstance unlockTime({required String utilityId}) {
    final utility = super.unlockTime(utilityId: utilityId);
    _schedulePersist(utility);
    return utility;
  }

  @override
  UtilityInstance addTripStop({
    required String utilityId,
    required String title,
    required GeoPoint position,
    String? address,
    String? note,
  }) {
    final utility = super.addTripStop(
      utilityId: utilityId,
      title: title,
      position: position,
      address: address,
      note: note,
    );
    _schedulePersist(utility);
    return utility;
  }

  @override
  UtilityInstance removeTripStop({
    required String utilityId,
    required String stopId,
  }) {
    final utility = super.removeTripStop(utilityId: utilityId, stopId: stopId);
    _schedulePersist(utility);
    return utility;
  }

  @override
  UtilityInstance enableExpenseTracking({required String utilityId}) {
    final utility = super.enableExpenseTracking(utilityId: utilityId);
    _schedulePersist(utility);
    return utility;
  }

  @override
  UtilityInstance addExpense({
    required String utilityId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> splitBetween,
    String? note,
  }) {
    final utility = super.addExpense(
      utilityId: utilityId,
      title: title,
      amount: amount,
      paidBy: paidBy,
      splitBetween: splitBetween,
      note: note,
    );
    _schedulePersist(utility);
    return utility;
  }

  @override
  UtilityInstance removeExpense({
    required String utilityId,
    required String expenseId,
  }) {
    final utility = super.removeExpense(
      utilityId: utilityId,
      expenseId: expenseId,
    );
    _schedulePersist(utility);
    return utility;
  }

  @override
  UtilityInstance saveLocationShare({
    required String utilityId,
    required String participantName,
    required LocationShareMode mode,
    required String stopId,
    String? statusMessage,
    required bool isBusy,
  }) {
    final utility = super.saveLocationShare(
      utilityId: utilityId,
      participantName: participantName,
      mode: mode,
      stopId: stopId,
      statusMessage: statusMessage,
      isBusy: isBusy,
    );
    _schedulePersist(utility);
    return utility;
  }

  @override
  UtilityInstance endLocationShare({
    required String utilityId,
    required String participantName,
  }) {
    final utility = super.endLocationShare(
      utilityId: utilityId,
      participantName: participantName,
    );
    _schedulePersist(utility);
    return utility;
  }

  void _schedulePersist(UtilityInstance utility) {
    if (_isDemoSession) return;
    unawaited(_persistCurrentUserUtilities());
    unawaited(_syncUtilityToCloud(utility));
  }

  Future<void> _persistCurrentUserUtilities() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return;
    }

    await _preferences.setString(
      _storageKey(currentUserId),
      encodeUtilities(getAll()),
    );
  }

  List<UtilityInstance> _loadCachedUtilities(
    String currentUserId, {
    required Iterable<String> legacyStorageKeys,
  }) {
    final direct = _loadFromStorageKey(currentUserId);
    if (direct.isNotEmpty) {
      return direct;
    }

    for (final legacyKey in legacyStorageKeys) {
      final normalizedLegacyKey = _normalizeUserId(legacyKey);
      if (normalizedLegacyKey == null || normalizedLegacyKey == currentUserId) {
        continue;
      }

      final legacyUtilities = _loadFromStorageKey(normalizedLegacyKey);
      if (legacyUtilities.isEmpty) {
        continue;
      }

      unawaited(
        _preferences.setString(
          _storageKey(currentUserId),
          encodeUtilities(legacyUtilities),
        ),
      );
      return legacyUtilities;
    }

    return const <UtilityInstance>[];
  }

  List<UtilityInstance> _loadFromStorageKey(String userId) {
    for (final candidate in _storageKeyCandidates(userId)) {
      final raw = _preferences.getString(candidate);
      if (raw == null || raw.isEmpty) {
        continue;
      }
      final decoded = decodeUtilities(raw);
      if (decoded.isNotEmpty) {
        return decoded;
      }
    }
    return const <UtilityInstance>[];
  }

  Iterable<String> _storageKeyCandidates(String userId) sync* {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final exact = _storageKey(trimmed);
    yield exact;

    final lower = trimmed.toLowerCase();
    if (lower != trimmed) {
      yield _storageKey(lower);
    }
  }

  Future<List<UtilityInstance>?> _fetchRemoteUtilities() async {
    try {
      final request = ModelQueries.list<OutingRecord>(
        OutingRecord.classType,
        authorizationMode: APIAuthorizationType.userPools,
        limit: 200,
      );
      final response = await Amplify.API.query(request: request).response;
      if (response.hasErrors) {
        safePrint('Fetch outings error: ${response.errors}');
        return null;
      }

      final remoteUtilities = <UtilityInstance>[];
      _cloudRecordIds.clear();

      final items =
          response.data?.items.whereType<OutingRecord>() ??
          const Iterable<OutingRecord>.empty();
      for (final item in items) {
        final utility = decodeUtility(item.payload);
        if (utility == null) {
          continue;
        }

        _cloudRecordIds.add(item.id);
        remoteUtilities.add(utility);
      }

      return remoteUtilities;
    } catch (error) {
      safePrint('Skipping remote outings fetch: $error');
      return null;
    }
  }

  List<UtilityInstance> _mergeUtilities({
    required List<UtilityInstance> localUtilities,
    required List<UtilityInstance> remoteUtilities,
  }) {
    final remoteById = <String, UtilityInstance>{
      for (final utility in remoteUtilities) utility.id: utility,
    };
    final merged = <UtilityInstance>[];

    for (final local in localUtilities) {
      merged.add(remoteById.remove(local.id) ?? local);
    }

    if (remoteById.isNotEmpty) {
      final extras = remoteById.values.toList(growable: false)
        ..sort((left, right) => left.title.compareTo(right.title));
      merged.addAll(extras);
    }

    return merged;
  }

  Future<void> _syncUtilitiesToCloud(
    Iterable<UtilityInstance> utilities,
  ) async {
    for (final utility in utilities) {
      await _syncUtilityToCloud(utility);
    }
  }

  Future<void> _syncUtilityToCloud(UtilityInstance utility) async {
    if (_currentUserId == null) {
      return;
    }

    try {
      final record = OutingRecord(
        id: utility.id,
        title: utility.title,
        createdBy: utility.createdBy,
        payload: encodeUtility(utility),
        closesAt: utility.closesAt == null
            ? null
            : TemporalDateTime(utility.closesAt!.toUtc()),
      );

      final isKnownCloudRecord = _cloudRecordIds.contains(record.id);
      final success = isKnownCloudRecord
          ? await _updateOutingRecord(record)
          : await _createOutingRecord(record) ||
                await _updateOutingRecord(record);

      if (success) {
        _cloudRecordIds.add(record.id);
      }
    } catch (error) {
      safePrint('Skipping remote outing sync: $error');
    }
  }

  Future<bool> _createOutingRecord(OutingRecord record) async {
    final request = ModelMutations.create(
      record,
      authorizationMode: APIAuthorizationType.userPools,
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.hasErrors) {
      safePrint('Create outing error: ${response.errors}');
      return false;
    }
    return true;
  }

  Future<bool> _updateOutingRecord(OutingRecord record) async {
    final request = ModelMutations.update(
      record,
      authorizationMode: APIAuthorizationType.userPools,
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.hasErrors) {
      safePrint('Update outing error: ${response.errors}');
      return false;
    }
    return true;
  }

  String _storageKey(String userId) => 'stored_outings::$userId';

  String? _normalizeUserId(String? userId) {
    final trimmed = userId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
