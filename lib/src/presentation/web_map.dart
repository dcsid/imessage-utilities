import 'package:chat_utilities_hub/src/models/ModelProvider.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/services/mapbox_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Web-only trip planning map. Renders raster tiles (Mapbox if a token is
/// configured, OSM otherwise) plus numbered pins for each planned stop.
class WebTripMap extends StatelessWidget {
  const WebTripMap({super.key, required this.utility, this.height = 320});

  final UtilityInstance utility;
  final double height;

  @override
  Widget build(BuildContext context) {
    final stops = utility.plannedStops;
    final center = stops.isEmpty
        ? const LatLng(38.0336, -78.5080) // Charlottesville fallback
        : LatLng(stops.first.position.latitude, stops.first.position.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: stops.isEmpty ? 12 : 13.5,
                minZoom: 2,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: mapTileUrlTemplate,
                  userAgentPackageName: 'com.siddus.chat_utilities_hub',
                ),
                if (stops.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < stops.length; i++)
                        Marker(
                          width: 36,
                          height: 36,
                          point: LatLng(
                            stops[i].position.latitude,
                            stops[i].position.longitude,
                          ),
                          child: _StopPin(
                            order: stops[i].order,
                            accent: AppPalette.accentFor(utility.id),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const _AttributionBadge(),
          ],
        ),
      ),
    );
  }
}

/// Web-only live outing map — same tile layer + a marker per active
/// participant location event.
class WebLiveOutingMap extends StatelessWidget {
  const WebLiveOutingMap({
    super.key,
    required this.utility,
    required this.events,
    this.height = 320,
  });

  final UtilityInstance utility;
  final List<ParticipantLocationEvent> events;
  final double height;

  @override
  Widget build(BuildContext context) {
    final firstEvent = events.isNotEmpty ? events.first : null;
    final firstStop = utility.plannedStops.isNotEmpty
        ? utility.plannedStops.first
        : null;
    final center = firstEvent != null
        ? LatLng(firstEvent.lat, firstEvent.lng)
        : firstStop != null
        ? LatLng(firstStop.position.latitude, firstStop.position.longitude)
        : const LatLng(38.0336, -78.5080);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                minZoom: 2,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: mapTileUrlTemplate,
                  userAgentPackageName: 'com.siddus.chat_utilities_hub',
                ),
                MarkerLayer(
                  markers: [
                    if (firstStop != null)
                      Marker(
                        width: 30,
                        height: 30,
                        point: LatLng(
                          firstStop.position.latitude,
                          firstStop.position.longitude,
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: AppPalette.ink,
                          size: 22,
                        ),
                      ),
                    for (final event in events)
                      Marker(
                        width: 36,
                        height: 36,
                        point: LatLng(event.lat, event.lng),
                        child: _ParticipantPin(
                          name: event.participantName,
                          isBusy: event.isBusy ?? false,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const _AttributionBadge(),
          ],
        ),
      ),
    );
  }
}

class _StopPin extends StatelessWidget {
  const _StopPin({required this.order, required this.accent});

  final int order;
  final OutingAccent accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.base,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.ink, width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.border,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        '$order',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ParticipantPin extends StatelessWidget {
  const _ParticipantPin({required this.name, required this.isBusy});

  final String name;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final accent = AppPalette.accentFor(name);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isBusy ? AppPalette.warning : accent.base,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.ink, width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.border,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _AttributionBadge extends StatelessWidget {
  const _AttributionBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          mapAttribution,
          style: const TextStyle(
            color: AppPalette.mutedText,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
