import 'dart:async';
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:chat_utilities_hub/src/models/ModelProvider.dart';
import 'package:chat_utilities_hub/src/services/location_service.dart';
import 'package:flutter/material.dart';

class LiveOutingMap extends StatefulWidget {
  const LiveOutingMap({
    super.key,
    required this.utilityId,
  });

  final String utilityId;

  @override
  State<LiveOutingMap> createState() => _LiveOutingMapState();
}

class _LiveOutingMapState extends State<LiveOutingMap> {
  AppleMapController? _mapController;
  StreamSubscription? _subscription;
  
  final Map<String, Annotation> _annotations = {};

  @override
  void initState() {
    super.initState();
    _subscribeToLiveLocations();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToLiveLocations() {
    _subscription = LocationService().subscribeToOuting(widget.utilityId).listen((snapshot) {
      final event = snapshot.data;
      if (event != null) {
        _updateMarker(event);
      }
    });
  }

  void _updateMarker(ParticipantLocationEvent event) {
    setState(() {
      _annotations[event.participantName] = Annotation(
        annotationId: AnnotationId(event.participantName),
        position: LatLng(event.lat, event.lng),
        infoWindow: InfoWindow(
          title: event.participantName,
          snippet: 'Updated just now',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AppleMap(
        onMapCreated: (AppleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(38.0336, -78.5080), // UVA coordinates as fallback
          zoom: 14.0,
        ),
        annotations: Set<Annotation>.of(_annotations.values),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
