import 'dart:async';

import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/trip_place_match.dart';
import 'package:chat_utilities_hub/src/models/trip_stop.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:chat_utilities_hub/src/presentation/live_outing_map.dart';
import 'package:chat_utilities_hub/src/presentation/trip_map.dart';
import 'package:chat_utilities_hub/src/services/location_service.dart';
import 'package:chat_utilities_hub/src/services/trip_place_service.dart';
import 'package:flutter/material.dart';

class TripPlanningPanel extends StatefulWidget {
  const TripPlanningPanel({
    super.key,
    required this.utility,
    required this.onAddTripStop,
    required this.onRemoveTripStop,
    required this.onSaveLocationShare,
    required this.onEndLocationShare,
    this.placeService = TripPlaceService.instance,
    this.showLiveMap = true,
  });

  final UtilityInstance utility;
  final void Function({
    required String utilityId,
    required String title,
    required GeoPoint position,
    String? address,
    String? note,
  })
  onAddTripStop;
  final void Function({required String utilityId, required String stopId})
  onRemoveTripStop;
  final void Function({
    required String utilityId,
    required String participantName,
    required LocationShareMode mode,
    required String stopId,
    String? statusMessage,
    required bool isBusy,
  })
  onSaveLocationShare;
  final void Function({
    required String utilityId,
    required String participantName,
  })
  onEndLocationShare;
  final TripPlaceService placeService;
  final bool showLiveMap;

  @override
  State<TripPlanningPanel> createState() => _TripPlanningPanelState();
}

class _TripPlanningPanelState extends State<TripPlanningPanel> {
  late final TextEditingController _shareParticipantController;
  late final TextEditingController _shareMessageController;
  late LocationShareMode _selectedMode;
  String? _selectedStopId;
  bool _isBusy = false;
  bool _shareRequestInFlight = false;

  @override
  void initState() {
    super.initState();
    _shareParticipantController = TextEditingController(
      text: widget.utility.createdBy,
    );
    _shareMessageController = TextEditingController();
    _selectedMode = LocationShareMode.live;
    _selectedStopId = widget.utility.plannedStops.isEmpty
        ? null
        : widget.utility.plannedStops.first.id;
    final initialShare = widget.utility.locationShareForParticipant(
      _shareParticipantController.text.trim(),
    );
    if (initialShare != null) {
      _selectedMode = initialShare.mode;
      _selectedStopId = initialShare.stopId;
      _shareMessageController.text = initialShare.statusMessage ?? '';
      _isBusy = initialShare.isBusy;
    }
  }

  @override
  void didUpdateWidget(covariant TripPlanningPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.utility != widget.utility) {
      if (_selectedStopId == null && widget.utility.plannedStops.isNotEmpty) {
        _selectedStopId = widget.utility.plannedStops.first.id;
      } else if (_selectedStopId != null &&
          widget.utility.stopById(_selectedStopId!) == null) {
        _selectedStopId = widget.utility.plannedStops.isEmpty
            ? null
            : widget.utility.plannedStops.first.id;
      }
      _syncShareDraftWithParticipant();
    }
  }

  @override
  void dispose() {
    _shareParticipantController.dispose();
    _shareMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip map',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Drop planned places onto the map, then let people optionally share where they are during the outing.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.mutedText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showAddStopSheet(),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Search place'),
                  ),
                  Text(
                    'or long press the map to drop a pin and let Apple Maps resolve it',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.mutedText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TripMap(
                utility: widget.utility,
                onAddStopAtPoint: _showAddStopSheet,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;
            if (!isWide) {
              return Column(
                children: [
                  _PlannedPlacesCard(
                    utility: widget.utility,
                    onRemoveStop: _removeStop,
                  ),
                  const SizedBox(height: 12),
                  _buildLocationSharingCard(context),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PlannedPlacesCard(
                    utility: widget.utility,
                    onRemoveStop: _removeStop,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildLocationSharingCard(context)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationSharingCard(BuildContext context) {
    final participantName = _shareParticipantController.text.trim();
    final shareMessage = _shareMessageController.text.trim();
    final activeShare = participantName.isEmpty
        ? null
        : widget.utility.locationShareForParticipant(participantName);
    final canSaveShare = participantName.isNotEmpty && _selectedStopId != null;
    final isBroadcasting =
        participantName.isNotEmpty &&
        LocationService().isBroadcastingFor(
          utilityId: widget.utility.id,
          participantName: participantName,
        );

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location sharing',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Use phone GPS for live updates or slower check-ins. Pick a destination, add a short status if you want, and mark yourself busy when you need space.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _shareParticipantController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Sharing as',
              hintText: 'Type your name',
            ),
            onChanged: (_) => _syncShareDraftWithParticipant(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LocationShareMode.values
                .map(
                  (mode) => ChoiceChip(
                    label: Text(mode.label),
                    selected: mode == _selectedMode,
                    onSelected: (_) {
                      setState(() {
                        _selectedMode = mode;
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          if (widget.utility.plannedStops.isEmpty)
            Text(
              'Add at least one place on the map before anyone can share their location.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey<String?>(_selectedStopId),
              initialValue: _selectedStopId,
              decoration: const InputDecoration(labelText: 'Destination'),
              items: widget.utility.plannedStops
                  .map(
                    (stop) => DropdownMenuItem<String>(
                      value: stop.id,
                      child: Text(stop.title),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                setState(() {
                  _selectedStopId = value;
                });
              },
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _shareMessageController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Status message',
              hintText:
                  'Parking on the east side, inside AFAC, grabbing coffee...',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              selected: _isBusy,
              onSelected: (selected) {
                setState(() {
                  _isBusy = selected;
                });
              },
              avatar: const Icon(Icons.do_not_disturb_on_rounded, size: 18),
              label: const Text('Busy'),
            ),
          ),
          if (_selectedMode.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _selectedMode.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: canSaveShare && !_shareRequestInFlight
                    ? () => _startGpsSharing(
                        context,
                        participantName: participantName,
                        statusMessage: shareMessage,
                      )
                    : null,
                icon: const Icon(Icons.location_on_rounded),
                label: Text(
                  activeShare == null && !isBroadcasting
                      ? 'Start GPS sharing'
                      : 'Update GPS sharing',
                ),
              ),
              OutlinedButton(
                onPressed:
                    (activeShare == null && !isBroadcasting) ||
                        _shareRequestInFlight
                    ? null
                    : () => _endGpsSharing(
                        context,
                        participantName: participantName,
                      ),
                child: const Text('End sharing'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (widget.showLiveMap) ...[
            Text(
              'Live outing map',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Pins come from real device GPS. ETA is a rough estimate from current speed toward the selected destination.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.mutedText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            LiveOutingMap(utility: widget.utility),
            const SizedBox(height: 18),
          ],
          if (widget.utility.resolvedLocationShares.isEmpty)
            Text(
              'No active location sharing yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.mutedText),
            )
          else
            ...widget.utility.resolvedLocationShares.map(
              (location) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LocationShareRow(
                  location: location,
                  onEnd: () {
                    widget.onEndLocationShare(
                      utilityId: widget.utility.id,
                      participantName: location.participantName,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _startGpsSharing(
    BuildContext context, {
    required String participantName,
    required String statusMessage,
  }) async {
    final stopId = _selectedStopId;
    if (stopId == null) {
      return;
    }

    setState(() {
      _shareRequestInFlight = true;
    });

    try {
      await LocationService().startBroadcasting(
        utilityId: widget.utility.id,
        participantName: participantName,
        mode: _selectedMode,
        destinationStopId: stopId,
        statusMessage: statusMessage,
        isBusy: _isBusy,
      );
      widget.onSaveLocationShare(
        utilityId: widget.utility.id,
        participantName: participantName,
        mode: _selectedMode,
        stopId: stopId,
        statusMessage: statusMessage,
        isBusy: _isBusy,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS sharing is live for $participantName.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _shareRequestInFlight = false;
        });
      }
    }
  }

  Future<void> _endGpsSharing(
    BuildContext context, {
    required String participantName,
  }) async {
    setState(() {
      _shareRequestInFlight = true;
    });

    try {
      await LocationService().stopBroadcasting();
      widget.onEndLocationShare(
        utilityId: widget.utility.id,
        participantName: participantName,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stopped sharing for $participantName.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _shareRequestInFlight = false;
        });
      }
    }
  }

  Future<void> _showAddStopSheet([GeoPoint? position]) async {
    final result = await showModalBottomSheet<_CreateStopResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateStopSheet(
        initialPosition: position,
        placeService: widget.placeService,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    widget.onAddTripStop(
      utilityId: widget.utility.id,
      title: result.title,
      address: result.address,
      note: result.note,
      position: result.position,
    );
  }

  void _removeStop(TripStop stop) {
    widget.onRemoveTripStop(utilityId: widget.utility.id, stopId: stop.id);
  }

  void _syncShareDraftWithParticipant() {
    final participantName = _shareParticipantController.text.trim();
    final activeShare = participantName.isEmpty
        ? null
        : widget.utility.locationShareForParticipant(participantName);

    setState(() {
      if (activeShare == null) {
        _shareMessageController.value = const TextEditingValue();
        _isBusy = false;
        return;
      }

      _selectedMode = activeShare.mode;
      _selectedStopId = activeShare.stopId;
      final statusMessage = activeShare.statusMessage ?? '';
      _shareMessageController.value = TextEditingValue(
        text: statusMessage,
        selection: TextSelection.collapsed(offset: statusMessage.length),
      );
      _isBusy = activeShare.isBusy;
    });
  }
}

class _PlannedPlacesCard extends StatelessWidget {
  const _PlannedPlacesCard({required this.utility, required this.onRemoveStop});

  final UtilityInstance utility;
  final ValueChanged<TripStop> onRemoveStop;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planned places',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Each stop now comes from Apple Maps search or a reverse-geocoded pin, so the route is built from real places.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (utility.plannedStops.isEmpty)
            Text(
              'No places added yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.mutedText),
            )
          else
            ...utility.plannedStops.map(
              (stop) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TripStopRow(
                  stop: stop,
                  onDelete: () => onRemoveStop(stop),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripStopRow extends StatelessWidget {
  const _TripStopRow({required this.stop, required this.onDelete});

  final TripStop stop;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppPalette.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${stop.order}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.title, style: titleStyle),
              if (stop.address != null && stop.address!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  stop.address!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppPalette.text),
                ),
              ],
              if (stop.note != null && stop.note!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  stop.note!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: 'Remove place',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          color: AppPalette.mutedText,
        ),
      ],
    );
  }
}

class _LocationShareRow extends StatelessWidget {
  const _LocationShareRow({required this.location, required this.onEnd});

  final ResolvedParticipantLocation location;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final detailParts = <String>[
      if (location.isBusy) 'Busy',
      location.mode.label,
      'at ${location.stop.title}',
      'updated ${formatTime(location.sharedAt)}',
    ];

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.participantName,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (location.statusMessage != null &&
                  location.statusMessage!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  location.statusMessage!.trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                detailParts.join(' • '),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(onPressed: onEnd, child: const Text('End')),
      ],
    );
  }
}

class _CreateStopSheet extends StatefulWidget {
  const _CreateStopSheet({required this.placeService, this.initialPosition});

  final TripPlaceService placeService;
  final GeoPoint? initialPosition;

  @override
  State<_CreateStopSheet> createState() => _CreateStopSheetState();
}

class _CreateStopSheetState extends State<_CreateStopSheet> {
  late final TextEditingController _searchController;
  late final TextEditingController _noteController;
  Timer? _searchDebounce;
  List<TripPlaceMatch> _results = const <TripPlaceMatch>[];
  TripPlaceMatch? _selectedPlace;
  bool _isLoading = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _noteController = TextEditingController();
    final initialPosition = widget.initialPosition;
    if (initialPosition != null) {
      unawaited(_prefillFromDroppedPin(initialPosition));
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 16),
      child: AppSurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add place',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Search Apple Maps for a real place or address. If you dropped a pin, we will try to resolve it automatically.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.mutedText),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Search place',
                hintText: 'Aquatic and Fitness Center, restaurant, address...',
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchDebounce?.cancel();
                                setState(() {
                                  _searchController.clear();
                                  _results = const <TripPlaceMatch>[];
                                  _selectedPlace = null;
                                  _feedbackMessage = null;
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                            )),
              ),
              onChanged: _handleQueryChanged,
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _feedbackMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
              ),
            ],
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppPalette.border),
                    color: AppPalette.surfaceMuted,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppPalette.border),
                    itemBuilder: (context, index) {
                      final place = _results[index];
                      final isSelected = place == _selectedPlace;
                      return ListTile(
                        title: Text(place.primaryLabel),
                        subtitle: place.secondaryLabel == null
                            ? null
                            : Text(place.secondaryLabel!),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppPalette.primary,
                              )
                            : null,
                        onTap: () => _selectPlace(place),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Meet outside, reservation at 7, etc.',
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _selectedPlace == null
                  ? 'Pick a real place result before saving so the map has a trustworthy address.'
                  : 'Selected location will be saved with its Apple Maps address and coordinates.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _selectedPlace == null ? null : _submit,
                  child: const Text('Save place'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _prefillFromDroppedPin(GeoPoint point) async {
    setState(() {
      _isLoading = true;
      _feedbackMessage = 'Resolving dropped pin with Apple Maps...';
    });

    final place = await widget.placeService.reverseGeocode(point);
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      if (place == null) {
        _feedbackMessage =
            'Could not resolve that pin. Search for a place instead.';
        return;
      }
      _selectedPlace = place;
      _searchController.text = place.primaryLabel;
      _results = <TripPlaceMatch>[place];
      _feedbackMessage = 'Pin matched to a real Apple Maps place.';
    });
  }

  void _handleQueryChanged(String value) {
    _searchDebounce?.cancel();
    final trimmedValue = value.trim();
    setState(() {
      _selectedPlace = null;
      _feedbackMessage = null;
      if (trimmedValue.isEmpty) {
        _results = const <TripPlaceMatch>[];
      }
    });

    if (trimmedValue.length < 2) {
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(trimmedValue),
    );
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final results = await widget.placeService.searchPlaces(
      query,
      near: widget.initialPosition,
    );
    if (!mounted || _searchController.text.trim() != query) {
      return;
    }

    setState(() {
      _isLoading = false;
      _results = results;
      _feedbackMessage = results.isEmpty
          ? 'No Apple Maps matches yet. Try a fuller place name or address.'
          : null;
    });
  }

  void _selectPlace(TripPlaceMatch place) {
    setState(() {
      _selectedPlace = place;
      _searchController.text = place.primaryLabel;
      _feedbackMessage =
          'Selected real place: ${place.secondaryLabel ?? place.primaryLabel}';
    });
  }

  void _submit() {
    final place = _selectedPlace;
    if (place == null) {
      return;
    }

    Navigator.of(context).pop(
      _CreateStopResult(
        title: place.primaryLabel,
        address: place.secondaryLabel ?? '',
        note: _noteController.text.trim(),
        position: place.position,
      ),
    );
  }
}

class _CreateStopResult {
  const _CreateStopResult({
    required this.title,
    required this.address,
    required this.note,
    required this.position,
  });

  final String title;
  final String address;
  final String note;
  final GeoPoint position;
}
