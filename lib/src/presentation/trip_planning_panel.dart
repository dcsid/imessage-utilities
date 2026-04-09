import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/trip_stop.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:chat_utilities_hub/src/presentation/trip_map.dart';
import 'package:flutter/material.dart';

class TripPlanningPanel extends StatefulWidget {
  const TripPlanningPanel({
    super.key,
    required this.utility,
    required this.onAddTripStop,
    required this.onSaveLocationShare,
    required this.onEndLocationShare,
  });

  final UtilityInstance utility;
  final void Function({
    required String utilityId,
    required String title,
    required GeoPoint position,
    String? note,
  })
  onAddTripStop;
  final void Function({
    required String utilityId,
    required String participantName,
    required LocationShareMode mode,
    required String stopId,
  })
  onSaveLocationShare;
  final void Function({
    required String utilityId,
    required String participantName,
  })
  onEndLocationShare;

  @override
  State<TripPlanningPanel> createState() => _TripPlanningPanelState();
}

class _TripPlanningPanelState extends State<TripPlanningPanel> {
  late final TextEditingController _shareParticipantController;
  late LocationShareMode _selectedMode;
  String? _selectedStopId;

  @override
  void initState() {
    super.initState();
    _shareParticipantController = TextEditingController(
      text: widget.utility.createdBy,
    );
    _selectedMode = LocationShareMode.live;
    _selectedStopId = widget.utility.plannedStops.isEmpty
        ? null
        : widget.utility.plannedStops.first.id;
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
    }
  }

  @override
  void dispose() {
    _shareParticipantController.dispose();
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Drop planned places onto the map, then let people optionally share where they are during the outing.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.mutedText,
                  height: 1.45,
                ),
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
                  _PlannedPlacesCard(utility: widget.utility),
                  const SizedBox(height: 12),
                  _buildLocationSharingCard(context),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _PlannedPlacesCard(utility: widget.utility)),
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
    final activeShare = participantName.isEmpty
        ? null
        : widget.utility.locationShareForParticipant(participantName);
    final canSaveShare = participantName.isNotEmpty && _selectedStopId != null;

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location sharing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep it optional. People can check in live or on a cadence, and stop sharing whenever they want.',
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
            onChanged: (_) => setState(() {}),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.mutedText,
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedStopId,
              decoration: const InputDecoration(
                labelText: 'Current stop',
              ),
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
          if (_selectedMode.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _selectedMode.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.mutedText,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: canSaveShare
                    ? () {
                        widget.onSaveLocationShare(
                          utilityId: widget.utility.id,
                          participantName: participantName,
                          mode: _selectedMode,
                          stopId: _selectedStopId!,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Updated location sharing for $participantName.',
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.location_on_rounded),
                label: Text(
                  activeShare == null ? 'Start sharing' : 'Update sharing',
                ),
              ),
              OutlinedButton(
                onPressed: activeShare == null
                    ? null
                    : () {
                        widget.onEndLocationShare(
                          utilityId: widget.utility.id,
                          participantName: participantName,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Stopped sharing for $participantName.'),
                          ),
                        );
                      },
                child: const Text('End sharing'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (widget.utility.resolvedLocationShares.isEmpty)
            Text(
              'No active location sharing yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
              ),
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

  Future<void> _showAddStopSheet(GeoPoint position) async {
    final result = await showModalBottomSheet<_CreateStopResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateStopSheet(position: position),
    );

    if (result == null || !context.mounted) {
      return;
    }

    widget.onAddTripStop(
      utilityId: widget.utility.id,
      title: result.title,
      note: result.note,
      position: result.position,
    );
  }
}

class _PlannedPlacesCard extends StatelessWidget {
  const _PlannedPlacesCard({required this.utility});

  final UtilityInstance utility;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planned places',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Long press the map to drop a stop. Keep the route light and easy to scan.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (utility.plannedStops.isEmpty)
            Text(
              'No places added yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
              ),
            )
          else
            ...utility.plannedStops.map(
              (stop) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TripStopRow(stop: stop),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripStopRow extends StatelessWidget {
  const _TripStopRow({required this.stop});

  final TripStop stop;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

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
              if (stop.note != null && stop.note!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  stop.note!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.mutedText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationShareRow extends StatelessWidget {
  const _LocationShareRow({
    required this.location,
    required this.onEnd,
  });

  final ResolvedParticipantLocation location;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.participantName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${location.mode.label} at ${location.stop.title} • updated ${formatTime(location.sharedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onEnd,
          child: const Text('End'),
        ),
      ],
    );
  }
}

class _CreateStopSheet extends StatefulWidget {
  const _CreateStopSheet({required this.position});

  final GeoPoint position;

  @override
  State<_CreateStopSheet> createState() => _CreateStopSheetState();
}

class _CreateStopSheetState extends State<_CreateStopSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Name the stop and keep an optional note for what happens there.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Place name',
                hintText: 'Dinner, parking, pickup spot...',
              ),
            ),
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
              'Pinned on the map already. You can refine the visuals later without changing the route data.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.mutedText,
              ),
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
                  onPressed: _submit,
                  child: const Text('Save place'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a place name first.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _CreateStopResult(
        title: title,
        note: _noteController.text.trim(),
        position: widget.position,
      ),
    );
  }
}

class _CreateStopResult {
  const _CreateStopResult({
    required this.title,
    required this.note,
    required this.position,
  });

  final String title;
  final String note;
  final GeoPoint position;
}
