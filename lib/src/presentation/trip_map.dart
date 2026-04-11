import 'dart:async';
import 'dart:math' as math;

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/trip_stop.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class TripMap extends StatefulWidget {
  const TripMap({
    super.key,
    required this.utility,
    this.height = 280,
    this.onAddStopAtPoint,
    this.showExpandButton = true,
  });

  final UtilityInstance utility;
  final double height;
  final ValueChanged<GeoPoint>? onAddStopAtPoint;
  final bool showExpandButton;

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  AppleMapController? _controller;
  String? _selectedStopId;
  String? _lastStopSignature;

  bool get _supportsInteractiveMap =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _selectedStopId = widget.utility.plannedStops.isEmpty
        ? null
        : widget.utility.plannedStops.first.id;
    _lastStopSignature = _stopSignature(widget.utility);
  }

  @override
  void didUpdateWidget(covariant TripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedStopId = _resolvedSelectedStopId();

    final newSignature = _stopSignature(widget.utility);
    if (_supportsInteractiveMap &&
        _controller != null &&
        newSignature != _lastStopSignature) {
      _lastStopSignature = newSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_fitCameraToPlannedStops(animated: true));
      });
    } else {
      _lastStopSignature = newSignature;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStop = _selectedStop();
    final resolvedLocations = widget.utility.resolvedLocationShares;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: _supportsInteractiveMap
                  ? _InteractiveTripMapSurface(
                      utility: widget.utility,
                      onMapCreated: _handleMapCreated,
                      onSelectStop: _handleSelectStop,
                      onAddStopAtPoint: widget.onAddStopAtPoint,
                    )
                  : _FallbackTripMapSurface(
                      utility: widget.utility,
                      height: widget.height,
                      onAddStopAtPoint: widget.onAddStopAtPoint,
                    ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _MapSummaryPill(
                label: '${widget.utility.stopCount} places',
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapSummaryPill(label: '${resolvedLocations.length} sharing'),
                  const SizedBox(width: 8),
                  _MapActionButton(
                    tooltip: 'Center route',
                    icon: Icons.center_focus_strong_rounded,
                    onPressed: widget.utility.plannedStops.isEmpty
                        ? null
                        : () => _fitCameraToPlannedStops(animated: true),
                  ),
                  if (widget.showExpandButton) ...[
                    const SizedBox(width: 8),
                    _MapActionButton(
                      tooltip: 'Expand map',
                      icon: Icons.open_in_full_rounded,
                      onPressed: () => _openExpandedMap(context),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.utility.plannedStops.isEmpty)
              const Positioned.fill(
                child: IgnorePointer(child: Center(child: _MapEmptyState())),
              )
            else
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: _SelectedStopCard(
                  utility: widget.utility,
                  selectedStop: selectedStop,
                  sharingCount: selectedStop == null
                      ? 0
                      : _shareCountForStop(
                          utility: widget.utility,
                          stopId: selectedStop.id,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMapCreated(AppleMapController controller) {
    _controller = controller;
    unawaited(_fitCameraToPlannedStops(animated: false));
  }

  void _handleSelectStop(String stopId) {
    if (_selectedStopId == stopId) {
      return;
    }

    setState(() {
      _selectedStopId = stopId;
    });
  }

  Future<void> _fitCameraToPlannedStops({required bool animated}) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final stops = widget.utility.plannedStops;
    final update = switch (stops.length) {
      0 => CameraUpdate.newCameraPosition(_defaultCameraPosition),
      1 => CameraUpdate.newLatLngZoom(_latLngFor(stops.first.position), 14.8),
      _ => CameraUpdate.newLatLngBounds(_boundsForStops(stops), 64),
    };

    if (animated) {
      await controller.animateCamera(update);
    } else {
      await controller.moveCamera(update);
    }
  }

  String? _resolvedSelectedStopId() {
    final currentId = _selectedStopId;
    if (currentId != null && widget.utility.stopById(currentId) != null) {
      return currentId;
    }
    return widget.utility.plannedStops.isEmpty
        ? null
        : widget.utility.plannedStops.first.id;
  }

  TripStop? _selectedStop() {
    final selectedStopId = _resolvedSelectedStopId();
    if (selectedStopId == null) {
      return null;
    }
    return widget.utility.stopById(selectedStopId);
  }

  static String _stopSignature(UtilityInstance utility) {
    return utility.plannedStops
        .map(
          (stop) =>
              '${stop.id}:${stop.position.latitude}:${stop.position.longitude}:${stop.order}',
        )
        .join('|');
  }

  Future<void> _openExpandedMap(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ExpandedTripMapPage(
          utility: widget.utility,
          onAddStopAtPoint: widget.onAddStopAtPoint,
        ),
      ),
    );
  }
}

class _InteractiveTripMapSurface extends StatelessWidget {
  const _InteractiveTripMapSurface({
    required this.utility,
    required this.onMapCreated,
    required this.onSelectStop,
    required this.onAddStopAtPoint,
  });

  final UtilityInstance utility;
  final ValueChanged<AppleMapController> onMapCreated;
  final ValueChanged<String> onSelectStop;
  final ValueChanged<GeoPoint>? onAddStopAtPoint;

  @override
  Widget build(BuildContext context) {
    return AppleMap(
      key: const ValueKey('trip-map-surface'),
      initialCameraPosition: _defaultCameraPosition,
      onMapCreated: onMapCreated,
      mapType: MapType.standard,
      compassEnabled: false,
      trafficEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      pitchGesturesEnabled: false,
      annotations: _annotations(),
      polylines: _polylines(),
      onLongPress: onAddStopAtPoint == null
          ? null
          : (position) {
              onAddStopAtPoint!(
                GeoPoint(
                  latitude: position.latitude,
                  longitude: position.longitude,
                ),
              );
            },
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
      },
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 104),
    );
  }

  Set<Annotation> _annotations() {
    return utility.plannedStops
        .map(
          (stop) => Annotation(
            annotationId: AnnotationId('stop:${stop.id}'),
            position: _latLngFor(stop.position),
            infoWindow: InfoWindow(
              title: '${stop.order}. ${stop.title}',
              snippet: _annotationSubtitle(stop),
            ),
            onTap: () => onSelectStop(stop.id),
          ),
        )
        .toSet();
  }

  String? _annotationSubtitle(TripStop stop) {
    final shareCount = _shareCountForStop(utility: utility, stopId: stop.id);
    final address = stop.address?.trim();
    if (address != null && address.isNotEmpty) {
      return shareCount > 0 ? '$address • $shareCount sharing' : address;
    }

    final note = stop.note?.trim();
    if (note != null && note.isNotEmpty) {
      return shareCount > 0 ? '$note • $shareCount sharing' : note;
    }
    if (shareCount > 0) {
      return '$shareCount sharing';
    }
    return null;
  }

  Set<Polyline> _polylines() {
    if (utility.plannedStops.length < 2) {
      return const <Polyline>{};
    }

    return <Polyline>{
      Polyline(
        polylineId: PolylineId('planned-route'),
        color: AppPalette.primary,
        width: 5,
        points: utility.plannedStops
            .map((stop) => _latLngFor(stop.position))
            .toList(growable: false),
      ),
    };
  }
}

class _FallbackTripMapSurface extends StatelessWidget {
  const _FallbackTripMapSurface({
    required this.utility,
    required this.height,
    this.onAddStopAtPoint,
  });

  final UtilityInstance utility;
  final double height;
  final ValueChanged<GeoPoint>? onAddStopAtPoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = TripMapViewport.fromUtility(utility);
        return GestureDetector(
          key: const ValueKey('trip-map-surface'),
          behavior: HitTestBehavior.opaque,
          onLongPressStart: onAddStopAtPoint == null
              ? null
              : (details) {
                  onAddStopAtPoint!(
                    viewport.pointForOffset(
                      details.localPosition,
                      Size(constraints.maxWidth, height),
                    ),
                  );
                },
          child: CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: _FallbackTripMapPainter(
              utility: utility,
              viewport: viewport,
            ),
          ),
        );
      },
    );
  }
}

class _MapSummaryPill extends StatelessWidget {
  const _MapSummaryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppPalette.text,
          ),
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.border),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ExpandedTripMapPage extends StatelessWidget {
  const _ExpandedTripMapPage({required this.utility, this.onAddStopAtPoint});

  final UtilityInstance utility;
  final ValueChanged<GeoPoint>? onAddStopAtPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip map')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return TripMap(
                utility: utility,
                height: constraints.maxHeight,
                onAddStopAtPoint: onAddStopAtPoint,
                showExpandButton: false,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Long press to add the first place.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Use the real map to place stops, see the route shape, and keep the outing easy to read.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedStopCard extends StatelessWidget {
  const _SelectedStopCard({
    required this.utility,
    required this.selectedStop,
    required this.sharingCount,
  });

  final UtilityInstance utility;
  final TripStop? selectedStop;
  final int sharingCount;

  @override
  Widget build(BuildContext context) {
    final stop = selectedStop;
    final routeSpan = _routeSpanMiles(utility.plannedStops);
    final topLine = stop == null
        ? 'Route overview'
        : 'Stop ${stop.order} of ${utility.plannedStops.length}';
    final secondary = stop == null
        ? '${utility.plannedStops.length} planned places'
        : stop.address?.trim().isNotEmpty == true
        ? stop.address!.trim()
        : (stop.note?.trim().isNotEmpty == true
              ? stop.note!.trim()
              : 'Planned destination');
    final tertiaryParts = <String>[
      if (sharingCount > 0) '$sharingCount sharing',
      if (stop?.note?.trim().isNotEmpty == true &&
          stop?.address?.trim() != stop?.note?.trim())
        stop!.note!.trim(),
      if (routeSpan != null) '~${routeSpan.toStringAsFixed(1)} mi span',
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              topLine,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stop?.title ?? utility.plannedStops.first.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
            ),
            if (tertiaryParts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                tertiaryParts.join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FallbackTripMapPainter extends CustomPainter {
  const _FallbackTripMapPainter({
    required this.utility,
    required this.viewport,
  });

  final UtilityInstance utility;
  final TripMapViewport viewport;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF3F6FB), Color(0xFFE5EEF9)],
      ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final gridPaint = Paint()
      ..color = AppPalette.border.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final dx = size.width * i / 4;
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    if (utility.plannedStops.length >= 2) {
      final polyline = Path();
      for (var i = 0; i < utility.plannedStops.length; i++) {
        final stop = utility.plannedStops[i];
        final point = viewport.offsetForPoint(stop.position, size);
        if (i == 0) {
          polyline.moveTo(point.dx, point.dy);
        } else {
          polyline.lineTo(point.dx, point.dy);
        }
      }

      final routePaint = Paint()
        ..color = AppPalette.primary.withValues(alpha: 0.82)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(polyline, routePaint);
    }

    for (final stop in utility.plannedStops) {
      final offset = viewport.offsetForPoint(stop.position, size);
      canvas.drawCircle(
        offset.translate(0, 5),
        16,
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );
      canvas.drawCircle(offset, 16, Paint()..color = Colors.white);
      canvas.drawCircle(
        offset,
        16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppPalette.primary,
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${stop.order}',
          style: const TextStyle(
            color: AppPalette.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        offset - Offset(labelPainter.width / 2, labelPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FallbackTripMapPainter oldDelegate) {
    return oldDelegate.utility != utility || oldDelegate.viewport != viewport;
  }
}

class TripMapViewport {
  const TripMapViewport({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  factory TripMapViewport.fromUtility(UtilityInstance utility) {
    final points = utility.plannedStops
        .map((stop) => stop.position)
        .toList(growable: false);

    if (points.isEmpty) {
      return const TripMapViewport(
        minLatitude: 37.99,
        maxLatitude: 38.07,
        minLongitude: -78.56,
        maxLongitude: -78.44,
      );
    }

    var minLatitude = points.first.latitude;
    var maxLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLongitude = points.first.longitude;

    for (final point in points.skip(1)) {
      minLatitude = math.min(minLatitude, point.latitude);
      maxLatitude = math.max(maxLatitude, point.latitude);
      minLongitude = math.min(minLongitude, point.longitude);
      maxLongitude = math.max(maxLongitude, point.longitude);
    }

    final latitudePadding = math.max((maxLatitude - minLatitude) * 0.22, 0.01);
    final longitudePadding = math.max(
      (maxLongitude - minLongitude) * 0.22,
      0.01,
    );

    return TripMapViewport(
      minLatitude: minLatitude - latitudePadding,
      maxLatitude: maxLatitude + latitudePadding,
      minLongitude: minLongitude - longitudePadding,
      maxLongitude: maxLongitude + longitudePadding,
    );
  }

  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  Offset offsetForPoint(GeoPoint point, Size size) {
    const padding = 28.0;
    final drawableWidth = size.width - (padding * 2);
    final drawableHeight = size.height - (padding * 2);
    final longitudeSpan = math.max(maxLongitude - minLongitude, 0.0001);
    final latitudeSpan = math.max(maxLatitude - minLatitude, 0.0001);

    final dx =
        padding +
        (((point.longitude - minLongitude) / longitudeSpan) * drawableWidth);
    final dy =
        padding +
        ((1 - ((point.latitude - minLatitude) / latitudeSpan)) *
            drawableHeight);
    return Offset(dx, dy);
  }

  GeoPoint pointForOffset(Offset offset, Size size) {
    const padding = 28.0;
    final clampedX = offset.dx.clamp(padding, size.width - padding);
    final clampedY = offset.dy.clamp(padding, size.height - padding);
    final drawableWidth = size.width - (padding * 2);
    final drawableHeight = size.height - (padding * 2);

    final longitude =
        minLongitude +
        (((clampedX - padding) / drawableWidth) *
            (maxLongitude - minLongitude));
    final latitude =
        minLatitude +
        ((1 - ((clampedY - padding) / drawableHeight)) *
            (maxLatitude - minLatitude));

    return GeoPoint(latitude: latitude, longitude: longitude);
  }

  @override
  bool operator ==(Object other) {
    return other is TripMapViewport &&
        other.minLatitude == minLatitude &&
        other.maxLatitude == maxLatitude &&
        other.minLongitude == minLongitude &&
        other.maxLongitude == maxLongitude;
  }

  @override
  int get hashCode =>
      Object.hash(minLatitude, maxLatitude, minLongitude, maxLongitude);
}

const CameraPosition _defaultCameraPosition = CameraPosition(
  target: LatLng(38.0336, -78.5080),
  zoom: 13.2,
);

LatLng _latLngFor(GeoPoint point) => LatLng(point.latitude, point.longitude);

LatLngBounds _boundsForStops(List<TripStop> stops) {
  var south = stops.first.position.latitude;
  var north = stops.first.position.latitude;
  var west = stops.first.position.longitude;
  var east = stops.first.position.longitude;

  for (final stop in stops.skip(1)) {
    south = math.min(south, stop.position.latitude);
    north = math.max(north, stop.position.latitude);
    west = math.min(west, stop.position.longitude);
    east = math.max(east, stop.position.longitude);
  }

  const minPadding = 0.01;
  final latPadding = math.max((north - south) * 0.22, minPadding);
  final lngPadding = math.max((east - west) * 0.22, minPadding);

  return LatLngBounds(
    southwest: LatLng(south - latPadding, west - lngPadding),
    northeast: LatLng(north + latPadding, east + lngPadding),
  );
}

int _shareCountForStop({
  required UtilityInstance utility,
  required String stopId,
}) {
  return utility.resolvedLocationShares
      .where((location) => location.stop.id == stopId)
      .length;
}

double? _routeSpanMiles(List<TripStop> stops) {
  if (stops.length < 2) {
    return null;
  }

  var meters = 0.0;
  for (var index = 1; index < stops.length; index++) {
    final previous = stops[index - 1];
    final current = stops[index];
    meters += Geolocator.distanceBetween(
      previous.position.latitude,
      previous.position.longitude,
      current.position.latitude,
      current.position.longitude,
    );
  }

  return meters / 1609.344;
}
