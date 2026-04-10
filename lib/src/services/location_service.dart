import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:geolocator/geolocator.dart';
import 'package:chat_utilities_hub/src/models/ModelProvider.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  String? _activeUtilityId;
  String? _participantName;

  /// Starts broadcasting the user's location to the AppSync API
  Future<void> startBroadcasting({
    required String utilityId,
    required String participantName,
  }) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested != LocationPermission.whileInUse && requested != LocationPermission.always) {
        throw Exception('Location permissions are denied');
      }
    }

    _activeUtilityId = utilityId;
    _participantName = participantName;

    final locationSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // Only send if we move 20 meters
      allowBackgroundLocationUpdates: true, // The Secret Blue Pill
      pauseLocationUpdatesAutomatically: true,
      showBackgroundLocationIndicator: true,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _broadcastLocation(position);
    });
  }

  void stopBroadcasting() {
    _positionStream?.cancel();
    _positionStream = null;
    _activeUtilityId = null;
    _participantName = null;
  }

  Future<void> _broadcastLocation(Position position) async {
    if (_activeUtilityId == null || _participantName == null) return;

    final event = ParticipantLocationEvent(
      participantName: _participantName!,
      utilityId: _activeUtilityId!,
      lat: position.latitude,
      lng: position.longitude,
      sharedAt: TemporalDateTime.now(),
    );

    final request = ModelMutations.create(event);
    final response = await Amplify.API.mutate(request: request).response;

    if (response.hasErrors) {
      safePrint('Location Broadcast Error: ${response.errors}');
    }
  }

  /// Subscribe to location updates for a specific board
  Stream<GraphQLResponse<ParticipantLocationEvent>> subscribeToOuting(String utilityId) {
    final request = ModelSubscriptions.onCreate(ParticipantLocationEvent.classType);
    return Amplify.API.subscribe<ParticipantLocationEvent>(
      request,
      onEstablished: () => safePrint('Subscription established'),
    ).where((event) {
      return event.data?.utilityId == utilityId;
    });
  }
}
