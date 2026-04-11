import 'dart:async';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:chat_utilities_hub/src/models/ModelProvider.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._internal();

  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  StreamSubscription<Position>? _positionStream;
  String? _activeUtilityId;
  String? _participantName;
  String? _destinationStopId;
  String? _statusMessage;
  bool _isBusy = false;
  LocationShareMode? _shareMode;
  DateTime? _lastPublishedAt;

  bool isBroadcastingFor({
    required String utilityId,
    required String participantName,
  }) {
    return _activeUtilityId == utilityId &&
        _participantName == participantName &&
        _positionStream != null;
  }

  Future<void> startBroadcasting({
    required String utilityId,
    required String participantName,
    required LocationShareMode mode,
    String? destinationStopId,
    String? statusMessage,
    required bool isBusy,
  }) async {
    await stopBroadcasting();
    await _ensureLocationPermission();

    _activeUtilityId = utilityId;
    _participantName = participantName.trim();
    _destinationStopId = destinationStopId;
    _statusMessage = _normalizedMessage(statusMessage);
    _isBusy = isBusy;
    _shareMode = mode;
    _lastPublishedAt = null;

    final currentLocationSettings = AppleSettings(
      accuracy: LocationAccuracy.best,
      activityType: ActivityType.otherNavigation,
    );
    final currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: currentLocationSettings,
    );
    await _broadcastLocation(currentPosition, force: true);

    final locationSettings = AppleSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: mode == LocationShareMode.live ? 10 : 25,
      activityType: ActivityType.otherNavigation,
      pauseLocationUpdatesAutomatically: true,
      showBackgroundLocationIndicator: false,
      allowBackgroundLocationUpdates: false,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            unawaited(_broadcastLocation(position));
          },
          onError: (Object error, StackTrace stackTrace) {
            safePrint('Location stream error: $error');
          },
        );
  }

  Future<void> stopBroadcasting() async {
    final positionStream = _positionStream;
    _positionStream = null;
    await positionStream?.cancel();
    _activeUtilityId = null;
    _participantName = null;
    _destinationStopId = null;
    _statusMessage = null;
    _isBusy = false;
    _shareMode = null;
    _lastPublishedAt = null;
  }

  Future<List<ParticipantLocationEvent>> fetchRecentLocations(
    String utilityId,
  ) async {
    final request = ModelQueries.list<ParticipantLocationEvent>(
      ParticipantLocationEvent.classType,
      where: ParticipantLocationEvent.UTILITYID.eq(utilityId),
      authorizationMode: APIAuthorizationType.userPools,
      limit: 200,
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.hasErrors) {
      safePrint('Fetch locations error: ${response.errors}');
      return const <ParticipantLocationEvent>[];
    }

    final items =
        response.data?.items.whereType<ParticipantLocationEvent>() ??
        const Iterable<ParticipantLocationEvent>.empty();
    final latestByParticipant = <String, ParticipantLocationEvent>{};

    for (final item in items) {
      if (_isExpired(item)) {
        continue;
      }

      final existing = latestByParticipant[item.participantName];
      if (existing == null || _isNewer(item, existing)) {
        latestByParticipant[item.participantName] = item;
      }
    }

    final latest = latestByParticipant.values.toList(growable: false);
    latest.sort(
      (left, right) => right.sharedAt.getDateTimeInUtc().compareTo(
        left.sharedAt.getDateTimeInUtc(),
      ),
    );
    return latest;
  }

  Stream<ParticipantLocationEvent> subscribeToOuting(String utilityId) {
    final request = ModelSubscriptions.onCreate(
      ParticipantLocationEvent.classType,
      authorizationMode: APIAuthorizationType.userPools,
    );

    return Amplify.API
        .subscribe<ParticipantLocationEvent>(
          request,
          onEstablished: () => safePrint('Location subscription established'),
        )
        .where((event) => event.data != null)
        .map((event) => event.data!)
        .where((event) => event.utilityId == utilityId && !_isExpired(event));
  }

  Future<void> _broadcastLocation(
    Position position, {
    bool force = false,
  }) async {
    final activeUtilityId = _activeUtilityId;
    final participantName = _participantName;
    final shareMode = _shareMode;
    if (activeUtilityId == null ||
        participantName == null ||
        shareMode == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    if (!force && !_shouldPublish(now, shareMode)) {
      return;
    }

    _lastPublishedAt = now;
    final event = ParticipantLocationEvent(
      participantName: participantName,
      utilityId: activeUtilityId,
      destinationStopId: _destinationStopId,
      statusMessage: _statusMessage,
      isBusy: _isBusy,
      shareMode: shareMode.name,
      lat: position.latitude,
      lng: position.longitude,
      speedMps: position.speed >= 0 ? position.speed : null,
      sharedAt: TemporalDateTime(now),
      expiresAt: TemporalDateTime(now.add(_ttlForMode(shareMode))),
    );

    final request = ModelMutations.create(
      event,
      authorizationMode: APIAuthorizationType.userPools,
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.hasErrors) {
      safePrint('Location broadcast error: ${response.errors}');
    }
  }

  String? _normalizedMessage(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool _shouldPublish(DateTime now, LocationShareMode mode) {
    final lastPublishedAt = _lastPublishedAt;
    if (lastPublishedAt == null) {
      return true;
    }

    return now.difference(lastPublishedAt) >= mode.publishInterval;
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError(
        'Turn on Location Services to share your live position.',
      );
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is turned off for this app. Update it in Settings.',
      );
    }

    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested != LocationPermission.whileInUse &&
          requested != LocationPermission.always) {
        throw StateError('Location permission is required for live sharing.');
      }
    }
  }

  bool _isExpired(ParticipantLocationEvent event) {
    final expiresAt = event.expiresAt;
    if (expiresAt == null) {
      return false;
    }
    return expiresAt.getDateTimeInUtc().isBefore(DateTime.now().toUtc());
  }

  bool _isNewer(
    ParticipantLocationEvent candidate,
    ParticipantLocationEvent current,
  ) {
    return candidate.sharedAt.getDateTimeInUtc().isAfter(
      current.sharedAt.getDateTimeInUtc(),
    );
  }

  Duration _ttlForMode(LocationShareMode mode) {
    switch (mode) {
      case LocationShareMode.live:
        return const Duration(minutes: 5);
      case LocationShareMode.every15Minutes:
        return const Duration(minutes: 30);
      case LocationShareMode.every30Minutes:
        return const Duration(hours: 1);
      case LocationShareMode.hourly:
        return const Duration(hours: 2);
    }
  }
}
