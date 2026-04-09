import 'dart:math' as math;

import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:flutter/material.dart';

class TripMap extends StatelessWidget {
  const TripMap({
    super.key,
    required this.utility,
    this.height = 280,
    this.onAddStopAtPoint,
  });

  final UtilityInstance utility;
  final double height;
  final ValueChanged<GeoPoint>? onAddStopAtPoint;

  @override
  Widget build(BuildContext context) {
    final resolvedLocations = utility.resolvedLocationShares;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = TripMapViewport.fromUtility(utility);
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GestureDetector(
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
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TripMapPainter(
                        utility: utility,
                        viewport: viewport,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _MapSummaryPill(
                      label: '${utility.stopCount} places',
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _MapSummaryPill(
                      label: '${resolvedLocations.length} sharing',
                    ),
                  ),
                  if (utility.plannedStops.isEmpty)
                    const Center(
                      child: _MapEmptyState(),
                    )
                  else
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: _MapFooter(
                        utility: utility,
                        resolvedLocations: resolvedLocations,
                      ),
                    ),
                ],
              ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The board stays simple: drop stops onto the trip map, then let people share where they are.',
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

class _MapFooter extends StatelessWidget {
  const _MapFooter({
    required this.utility,
    required this.resolvedLocations,
  });

  final UtilityInstance utility;
  final List<ResolvedParticipantLocation> resolvedLocations;

  @override
  Widget build(BuildContext context) {
    final placeSummary = utility.plannedStops.take(3).map((stop) => stop.title).join(' • ');
    final sharingSummary = resolvedLocations.isEmpty
        ? 'No live shares yet'
        : resolvedLocations
              .take(3)
              .map((location) => '${location.participantName} at ${location.stop.title}')
              .join(' • ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              placeSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppPalette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sharingSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripMapPainter extends CustomPainter {
  const _TripMapPainter({
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
        colors: [
          Color(0xFFF4F7FB),
          Color(0xFFE9F1FF),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);
    _paintGrid(canvas, size);
    _paintRoads(canvas, size);
    _paintRoute(canvas, size);
    _paintStops(canvas, size);
    _paintLiveLocations(canvas, size);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppPalette.border.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    const divisions = 5;
    for (var index = 1; index < divisions; index++) {
      final horizontalY = size.height * index / divisions;
      canvas.drawLine(
        Offset(0, horizontalY),
        Offset(size.width, horizontalY),
        gridPaint,
      );

      final verticalX = size.width * index / divisions;
      canvas.drawLine(
        Offset(verticalX, 0),
        Offset(verticalX, size.height),
        gridPaint,
      );
    }
  }

  void _paintRoads(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadShadowPaint = Paint()
      ..color = AppPalette.border.withValues(alpha: 0.45)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final primaryRoad = Path()
      ..moveTo(size.width * 0.05, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.46,
        size.width * 0.52,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.64,
        size.width * 0.94,
        size.height * 0.18,
      );

    final secondaryRoad = Path()
      ..moveTo(size.width * 0.12, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.18,
        size.width * 0.42,
        size.height * 0.34,
      )
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.62,
        size.width * 0.86,
        size.height * 0.76,
      );

    canvas.drawPath(primaryRoad, roadShadowPaint);
    canvas.drawPath(primaryRoad, roadPaint);
    canvas.drawPath(secondaryRoad, roadShadowPaint);
    canvas.drawPath(secondaryRoad, roadPaint);
  }

  void _paintRoute(Canvas canvas, Size size) {
    if (utility.plannedStops.length < 2) {
      return;
    }

    final routePath = Path();
    for (var index = 0; index < utility.plannedStops.length; index++) {
      final stop = utility.plannedStops[index];
      final offset = viewport.offsetForPoint(stop.position, size);
      if (index == 0) {
        routePath.moveTo(offset.dx, offset.dy);
      } else {
        routePath.lineTo(offset.dx, offset.dy);
      }
    }

    final routeShadowPaint = Paint()
      ..color = AppPalette.border
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePaint = Paint()
      ..color = AppPalette.primary.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(routePath, routeShadowPaint);
    canvas.drawPath(routePath, routePaint);
  }

  void _paintStops(Canvas canvas, Size size) {
    for (final stop in utility.plannedStops) {
      final offset = viewport.offsetForPoint(stop.position, size);

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.08);
      canvas.drawCircle(offset.translate(0, 6), 18, shadowPaint);

      final fillPaint = Paint()..color = Colors.white;
      canvas.drawCircle(offset, 18, fillPaint);

      final borderPaint = Paint()
        ..color = AppPalette.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(offset, 18, borderPaint);

      final numberPainter = TextPainter(
        text: TextSpan(
          text: '${stop.order}',
          style: const TextStyle(
            color: AppPalette.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      numberPainter.paint(
        canvas,
        offset - Offset(numberPainter.width / 2, numberPainter.height / 2),
      );
    }
  }

  void _paintLiveLocations(Canvas canvas, Size size) {
    final grouped = <String, List<ResolvedParticipantLocation>>{};
    for (final location in utility.resolvedLocationShares) {
      grouped.putIfAbsent(location.stop.id, () => <ResolvedParticipantLocation>[]).add(location);
    }

    for (final entry in grouped.entries) {
      final stop = utility.stopById(entry.key);
      if (stop == null) {
        continue;
      }
      final stopOffset = viewport.offsetForPoint(stop.position, size);
      final locations = entry.value;
      for (var index = 0; index < locations.length; index++) {
        final angle = (-math.pi / 2) + (index * (2 * math.pi / locations.length));
        final distance = locations.length == 1 ? 0.0 : 30.0;
        final markerOffset = Offset(
          stopOffset.dx + (math.cos(angle) * distance),
          stopOffset.dy + (math.sin(angle) * distance),
        );
        _paintShareMarker(
          canvas,
          markerOffset,
          locations[index].participantName,
        );
      }
    }
  }

  void _paintShareMarker(Canvas canvas, Offset offset, String participantName) {
    final fillPaint = Paint()..color = AppPalette.success;
    canvas.drawCircle(offset, 12, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(offset, 12, borderPaint);

    final initials = _initialsFor(participantName);
    final labelPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
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

  String _initialsFor(String value) {
    final pieces = value.trim().split(RegExp(r'\s+'));
    if (pieces.isEmpty || pieces.first.isEmpty) {
      return '?';
    }
    if (pieces.length == 1) {
      final token = pieces.first;
      return token.substring(0, math.min(2, token.length)).toUpperCase();
    }
    return '${pieces.first[0]}${pieces.last[0]}'.toUpperCase();
  }

  @override
  bool shouldRepaint(covariant _TripMapPainter oldDelegate) {
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
    final points = <GeoPoint>[
      for (final stop in utility.plannedStops) stop.position,
      for (final location in utility.resolvedLocationShares) location.stop.position,
    ];

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

    final latitudePadding = math.max((maxLatitude - minLatitude) * 0.2, 0.01);
    final longitudePadding = math.max((maxLongitude - minLongitude) * 0.2, 0.01);

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

    final dx = padding + (((point.longitude - minLongitude) / longitudeSpan) * drawableWidth);
    final dy = padding + ((1 - ((point.latitude - minLatitude) / latitudeSpan)) * drawableHeight);
    return Offset(dx, dy);
  }

  GeoPoint pointForOffset(Offset offset, Size size) {
    const padding = 28.0;
    final clampedX = offset.dx.clamp(padding, size.width - padding);
    final clampedY = offset.dy.clamp(padding, size.height - padding);
    final drawableWidth = size.width - (padding * 2);
    final drawableHeight = size.height - (padding * 2);

    final longitude = minLongitude + (((clampedX - padding) / drawableWidth) * (maxLongitude - minLongitude));
    final latitude = minLatitude + ((1 - ((clampedY - padding) / drawableHeight)) * (maxLatitude - minLatitude));

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
  int get hashCode => Object.hash(
    minLatitude,
    maxLatitude,
    minLongitude,
    maxLongitude,
  );
}
