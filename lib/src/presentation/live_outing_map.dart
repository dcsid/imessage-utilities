import 'dart:async';

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:chat_utilities_hub/src/models/ModelProvider.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:chat_utilities_hub/src/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LiveOutingMap extends StatefulWidget {
  const LiveOutingMap({
    super.key,
    required this.utility,
    this.height = 280,
    this.showExpandButton = true,
  });

  final UtilityInstance utility;
  final double height;
  final bool showExpandButton;

  @override
  State<LiveOutingMap> createState() => _LiveOutingMapState();
}

class _LiveOutingMapState extends State<LiveOutingMap> {
  StreamSubscription<ParticipantLocationEvent>? _subscription;
  final Map<String, ParticipantLocationEvent> _eventsByParticipant =
      <String, ParticipantLocationEvent>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitialEvents());
    _subscribeToLiveLocations();
  }

  @override
  void didUpdateWidget(covariant LiveOutingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.utility.id == widget.utility.id) {
      return;
    }

    _eventsByParticipant.clear();
    _subscription?.cancel();
    _loading = true;
    unawaited(_loadInitialEvents());
    _subscribeToLiveLocations();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialEvents() async {
    final events = await LocationService().fetchRecentLocations(
      widget.utility.id,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      for (final event in events) {
        _eventsByParticipant[event.participantName] = event;
      }
      _loading = false;
    });
  }

  void _subscribeToLiveLocations() {
    _subscription?.cancel();
    _subscription = LocationService()
        .subscribeToOuting(widget.utility.id)
        .listen(_applyEvent);
  }

  void _applyEvent(ParticipantLocationEvent event) {
    final current = _eventsByParticipant[event.participantName];
    if (current != null &&
        !event.sharedAt.getDateTimeInUtc().isAfter(
          current.sharedAt.getDateTimeInUtc(),
        )) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _eventsByParticipant[event.participantName] = event;
    });
  }

  @override
  Widget build(BuildContext context) {
    final annotations = _eventsByParticipant.values
        .map(_annotationForEvent)
        .toSet();
    final sortedEvents = _eventsByParticipant.values.toList(growable: false)
      ..sort(
        (left, right) => right.sharedAt.getDateTimeInUtc().compareTo(
          left.sharedAt.getDateTimeInUtc(),
        ),
      );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            AppleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(38.0336, -78.5080),
                zoom: 13.5,
              ),
              annotations: annotations,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
            ),
            if (widget.showExpandButton)
              Positioned(
                top: 12,
                right: 12,
                child: _ExpandMapButton(
                  tooltip: 'Expand live map',
                  onPressed: () => _openExpandedMap(context),
                ),
              ),
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (sortedEvents.isEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: _OverlayCard(
                      child: Text(
                        'No live GPS updates yet. Start sharing from this board to drop the first pin.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.mutedText,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _OverlayCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedEvents
                        .take(3)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LiveEventRow(
                              event: event,
                              destinationLabel: _destinationLabel(event),
                              etaLabel: _etaLabel(event),
                              updatedLabel: formatTime(
                                event.sharedAt.getDateTimeInUtc().toLocal(),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Annotation _annotationForEvent(ParticipantLocationEvent event) {
    final subtitleParts = _subtitlePartsForEvent(event);

    return Annotation(
      annotationId: AnnotationId(event.participantName),
      position: LatLng(event.lat, event.lng),
      infoWindow: InfoWindow(
        title: event.participantName,
        snippet: subtitleParts.join(' • '),
      ),
    );
  }

  String? _destinationLabel(ParticipantLocationEvent event) {
    final stopId = event.destinationStopId;
    if (stopId == null || stopId.isEmpty) {
      return null;
    }

    final stop = widget.utility.stopById(stopId);
    if (stop == null) {
      return null;
    }
    return 'Heading to ${stop.title}';
  }

  List<String> _subtitlePartsForEvent(ParticipantLocationEvent event) {
    final parts = <String>[];
    if (event.isBusy == true) {
      parts.add('Busy');
    }
    final statusMessage = event.statusMessage?.trim();
    if (statusMessage != null && statusMessage.isNotEmpty) {
      parts.add(statusMessage);
    }
    final destinationLabel = _destinationLabel(event);
    if (destinationLabel != null) {
      parts.add(destinationLabel);
    }
    final etaLabel = _etaLabel(event);
    if (etaLabel != null) {
      parts.add(etaLabel);
    }
    parts.add(
      'Updated ${formatTime(event.sharedAt.getDateTimeInUtc().toLocal())}',
    );
    return parts;
  }

  String? _etaLabel(ParticipantLocationEvent event) {
    final stopId = event.destinationStopId;
    final speedMps = event.speedMps;
    if (stopId == null || speedMps == null || speedMps < 1) {
      return null;
    }

    final stop = widget.utility.stopById(stopId);
    if (stop == null) {
      return null;
    }

    final distanceMeters = Geolocator.distanceBetween(
      event.lat,
      event.lng,
      stop.position.latitude,
      stop.position.longitude,
    );
    if (distanceMeters <= 0) {
      return 'Arriving now';
    }

    final eta = Duration(seconds: (distanceMeters / speedMps).round());
    if (eta > const Duration(hours: 4)) {
      return null;
    }

    return '~${_formatDuration(eta)} ETA';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '<1 min';
    }
    if (duration.inHours < 1) {
      return '${duration.inMinutes} min';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  Future<void> _openExpandedMap(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            _ExpandedLiveOutingMapPage(utility: widget.utility),
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: child,
      ),
    );
  }
}

class _ExpandMapButton extends StatelessWidget {
  const _ExpandMapButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.border),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: const Icon(Icons.open_in_full_rounded, size: 18),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _LiveEventRow extends StatelessWidget {
  const _LiveEventRow({
    required this.event,
    required this.destinationLabel,
    required this.etaLabel,
    required this.updatedLabel,
  });

  final ParticipantLocationEvent event;
  final String? destinationLabel;
  final String? etaLabel;
  final String updatedLabel;

  @override
  Widget build(BuildContext context) {
    final destination = destinationLabel;
    final eta = etaLabel;
    final secondaryParts = <String>[
      if (event.isBusy == true) 'Busy',
      if (event.statusMessage?.trim().isNotEmpty == true)
        event.statusMessage!.trim(),
      ...?destination == null ? null : <String>[destination],
      ...?eta == null ? null : <String>[eta],
      'Updated $updatedLabel',
    ];

    return Row(
      children: [
        Icon(
          event.isBusy == true
              ? Icons.do_not_disturb_on_rounded
              : Icons.location_pin,
          color: event.isBusy == true ? AppPalette.warning : AppPalette.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.participantName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                secondaryParts.join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpandedLiveOutingMapPage extends StatelessWidget {
  const _ExpandedLiveOutingMapPage({required this.utility});

  final UtilityInstance utility;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live outing map')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return LiveOutingMap(
                utility: utility,
                height: constraints.maxHeight,
                showExpandButton: false,
              );
            },
          ),
        ),
      ),
    );
  }
}
