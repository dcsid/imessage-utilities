import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:chat_utilities_hub/src/presentation/availability_board.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:chat_utilities_hub/src/presentation/expense_tracking_panel.dart';
import 'package:chat_utilities_hub/src/presentation/trip_planning_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UtilityDetailScreen extends StatefulWidget {
  const UtilityDetailScreen({
    super.key,
    required this.utility,
    required this.onBack,
    required this.onSaveResponse,
    required this.onAddTripStop,
    required this.onRemoveTripStop,
    required this.onEnableExpenseTracking,
    required this.onAddExpense,
    required this.onRemoveExpense,
    required this.onSaveLocationShare,
    required this.onEndLocationShare,
  });

  final UtilityInstance utility;
  final VoidCallback onBack;
  final void Function({
    required String utilityId,
    required String participantName,
    required Set<String> selectedOptionIds,
  })
  onSaveResponse;
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
  final void Function({required String utilityId}) onEnableExpenseTracking;
  final void Function({
    required String utilityId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> splitBetween,
    String? note,
  })
  onAddExpense;
  final void Function({required String utilityId, required String expenseId})
  onRemoveExpense;
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

  @override
  State<UtilityDetailScreen> createState() => _UtilityDetailScreenState();
}

class _UtilityDetailScreenState extends State<UtilityDetailScreen> {
  bool _isAvailabilityBoardInteracting = false;

  void _setAvailabilityBoardInteraction(bool isInteracting) {
    if (_isAvailabilityBoardInteracting == isInteracting) {
      return;
    }

    setState(() {
      _isAvailabilityBoardInteracting = isInteracting;
    });
  }

  @override
  Widget build(BuildContext context) {
    final utility = widget.utility;
    final rankedScores = utility.optionScores.take(5).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(utility.title),
        actions: [
          IconButton(
            tooltip: 'Copy link',
            onPressed: () => _copyShareLink(context, utility.id),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: AppBackdrop(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              physics: _isAvailabilityBoardInteracting
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _OverviewCard(utility: utility),
                const SizedBox(height: 20),
                _WorkflowCard(utility: utility),
                const SizedBox(height: 20),
                const _SectionTitle(
                  title: 'Step 1: Find a time',
                  subtitle:
                      'Start every outing here. Everyone marks their free blocks on the weekly board so the group can lock the best time first.',
                ),
                const SizedBox(height: 12),
                _ResponseComposerCard(
                  utility: utility,
                  onSaveResponse: widget.onSaveResponse,
                  onBoardInteractionChanged: _setAvailabilityBoardInteraction,
                ),
                const SizedBox(height: 20),
                AppSurface(
                  child: AvailabilityBoard(
                    utility: utility,
                    accent: AppPalette.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle(
                  title: 'Best times',
                  subtitle:
                      'These are the strongest candidate windows based on the responses currently on the board.',
                ),
                const SizedBox(height: 12),
                AppSurface(
                  child: Column(
                    children: rankedScores
                        .map(
                          (score) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TopTimeRow(
                              score: score,
                              totalParticipants: utility.participants.length,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle(
                  title: 'Step 2: Route and live location',
                  subtitle:
                      'Once timing is clear, plan the route, add real destinations, and use GPS sharing only when the outing needs it.',
                ),
                const SizedBox(height: 12),
                TripPlanningPanel(
                  utility: utility,
                  onAddTripStop: widget.onAddTripStop,
                  onRemoveTripStop: widget.onRemoveTripStop,
                  onSaveLocationShare: widget.onSaveLocationShare,
                  onEndLocationShare: widget.onEndLocationShare,
                ),
                const SizedBox(height: 20),
                const _SectionTitle(
                  title: 'Step 3: Optional trip expenses',
                  subtitle:
                      'Only turn this on if the outing needs shared costs. Otherwise, leave it hidden and keep the plan lightweight.',
                ),
                const SizedBox(height: 12),
                ExpenseTrackingPanel(
                  utility: utility,
                  onEnableExpenseTracking: widget.onEnableExpenseTracking,
                  onAddExpense: widget.onAddExpense,
                  onRemoveExpense: widget.onRemoveExpense,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 720;
                    if (!isWide) {
                      return Column(
                        children: [
                          _ParticipantsCard(utility: utility),
                          const SizedBox(height: 12),
                          _ResponsesCard(utility: utility),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ParticipantsCard(utility: utility)),
                        const SizedBox(width: 12),
                        Expanded(child: _ResponsesCard(utility: utility)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyShareLink(BuildContext context, String utilityId) async {
    await Clipboard.setData(
      ClipboardData(text: UtilityLink.forUtility(utilityId).toString()),
    );
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Board link copied.')));
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.utility});

  final UtilityInstance utility;

  @override
  Widget build(BuildContext context) {
    final startsAt = utility.startsAt;
    final endsAt = utility.endsAt;

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            utility.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _dateRangeLabel(startsAt, endsAt),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppPalette.mutedText),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _OverviewStat(label: 'Organizer', value: utility.createdBy),
              _OverviewStat(
                label: 'Responded',
                value:
                    '${utility.responseCount}/${utility.participants.length}',
              ),
              _OverviewStat(
                label: 'Waiting on',
                value: '${utility.pendingResponseCount}',
              ),
              _OverviewStat(label: 'Places', value: '${utility.stopCount}'),
              _OverviewStat(
                label: 'Sharing',
                value: '${utility.activeLocationShareCount}',
              ),
              _OverviewStat(
                label: 'Expenses',
                value: utility.expenseTrackingEnabled
                    ? '${utility.expenseCount}'
                    : 'Off',
              ),
              if (utility.closesAt != null)
                _OverviewStat(
                  label: 'Closes',
                  value: formatDeadline(utility.closesAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateRangeLabel(DateTime? startsAt, DateTime? endsAt) {
    if (startsAt == null || endsAt == null) {
      return 'Shared weekly availability board';
    }

    final startMonth = _monthLabel(startsAt.month);
    final endMonth = _monthLabel(endsAt.month);
    if (startsAt.month == endsAt.month) {
      return '$startMonth ${startsAt.day}-${endsAt.day}';
    }
    return '$startMonth ${startsAt.day} - $endMonth ${endsAt.day}';
  }

  String _monthLabel(int month) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month - 1];
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.utility});

  final UtilityInstance utility;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outing flow',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'This outing moves in order: confirm the event details, lock a time, then handle the route, live location, and optional costs.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _WorkflowStep(
                step: '1',
                title: 'Free times',
                subtitle: utility.responseCount == 0
                    ? 'Waiting for the first response'
                    : '${utility.responseCount}/${utility.participants.length} responded',
                active: true,
              ),
              _WorkflowStep(
                step: '2',
                title: 'Route + GPS',
                subtitle: utility.stopCount == 0
                    ? 'No places added yet'
                    : '${utility.stopCount} places planned',
              ),
              _WorkflowStep(
                step: '3',
                title: 'Expenses',
                subtitle: utility.expenseTrackingEnabled
                    ? '${utility.expenseCount} expenses logged'
                    : 'Optional',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.step,
    required this.title,
    required this.subtitle,
    this.active = false,
  });

  final String step;
  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? AppPalette.primarySoft : AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppPalette.primary : Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: active ? Colors.white : AppPalette.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppPalette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppPalette.mutedText,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _TopTimeRow extends StatelessWidget {
  const _TopTimeRow({required this.score, required this.totalParticipants});

  final UtilityOptionScore score;
  final int totalParticipants;

  @override
  Widget build(BuildContext context) {
    final coverage = score.coverage(totalParticipants);
    final progressColor = coverage >= 0.66
        ? AppPalette.success
        : coverage >= 0.4
        ? AppPalette.warning
        : AppPalette.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                formatUtilityOption(score.option),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${score.votes}/$totalParticipants',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: coverage,
            color: progressColor,
            backgroundColor: AppPalette.surfaceMuted,
          ),
        ),
        if (score.responders.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            score.responders.join(', '),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
          ),
        ],
      ],
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({required this.utility});

  final UtilityInstance utility;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participants',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: utility.participants
                .map(
                  (participant) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(participant),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ResponsesCard extends StatelessWidget {
  const _ResponsesCard({required this.utility});

  final UtilityInstance utility;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Responses',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (utility.responses.isEmpty)
            Text(
              'No one has responded yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.mutedText),
            )
          else
            ...utility.responses.map(
              (response) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ResponseRow(response: response),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResponseRow extends StatelessWidget {
  const _ResponseRow({required this.response});

  final UtilityResponse response;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                response.participantName,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${response.selectedOptionIds.length} blocks selected',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatTime(response.respondedAt),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
        ),
      ],
    );
  }
}

class _ResponseComposerCard extends StatefulWidget {
  const _ResponseComposerCard({
    required this.utility,
    required this.onSaveResponse,
    this.onBoardInteractionChanged,
  });

  final UtilityInstance utility;
  final void Function({
    required String utilityId,
    required String participantName,
    required Set<String> selectedOptionIds,
  })
  onSaveResponse;
  final ValueChanged<bool>? onBoardInteractionChanged;

  @override
  State<_ResponseComposerCard> createState() => _ResponseComposerCardState();
}

class _ResponseComposerCardState extends State<_ResponseComposerCard> {
  late String _participantName;
  late final TextEditingController _participantController;
  late Set<String> _selectedOptionIds;

  @override
  void initState() {
    super.initState();
    _participantName = _initialParticipant(widget.utility);
    _participantController = TextEditingController(text: _participantName);
    _selectedOptionIds = _selectionsFor(widget.utility, _participantName);
  }

  @override
  void didUpdateWidget(covariant _ResponseComposerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.utility != widget.utility) {
      final typedName = _participantController.text.trim();
      _participantName = typedName.isEmpty
          ? _initialParticipant(widget.utility)
          : typedName;
      _participantController.value = TextEditingValue(
        text: _participantName,
        selection: TextSelection.collapsed(offset: _participantName.length),
      );
      _selectedOptionIds = _selectionsFor(widget.utility, _participantName);
    }
  }

  @override
  void dispose() {
    _participantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingResponse = widget.utility.responseForParticipant(
      _participantName,
    );

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _participantController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Responding as',
                    hintText: 'Type your name',
                  ),
                  onChanged: (value) {
                    final nextName = value.trim();
                    setState(() {
                      _participantName = nextName;
                      _selectedOptionIds = _selectionsFor(
                        widget.utility,
                        nextName,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              _InlineStatusPill(
                label: existingResponse == null ? 'New response' : 'Editing',
              ),
            ],
          ),
          if (widget.utility.participants.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.utility.participants
                  .map(
                    (participant) => ActionChip(
                      label: Text(participant),
                      onPressed: () {
                        setState(() {
                          _participantName = participant;
                          _participantController.value = TextEditingValue(
                            text: participant,
                            selection: TextSelection.collapsed(
                              offset: participant.length,
                            ),
                          );
                          _selectedOptionIds = _selectionsFor(
                            widget.utility,
                            participant,
                          );
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 16),
          AvailabilityBoard(
            utility: widget.utility,
            accent: AppPalette.primary,
            mode: AvailabilityBoardMode.selection,
            selectedOptionIds: _selectedOptionIds,
            onInteractionChanged: widget.onBoardInteractionChanged,
            onSelectionChanged: (nextSelections) {
              setState(() {
                _selectedOptionIds = nextSelections;
              });
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed:
                    _participantName.isEmpty || _selectedOptionIds.isEmpty
                    ? null
                    : () {
                        widget.onSaveResponse(
                          utilityId: widget.utility.id,
                          participantName: _participantName,
                          selectedOptionIds: _selectedOptionIds,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Saved availability for $_participantName.',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save availability'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedOptionIds = _selectionsFor(
                      widget.utility,
                      _participantName,
                    );
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initialParticipant(UtilityInstance utility) {
    for (final participant in utility.participants) {
      if (utility.responseForParticipant(participant) == null) {
        return participant;
      }
    }
    return utility.createdBy;
  }

  Set<String> _selectionsFor(UtilityInstance utility, String participantName) {
    final response = utility.responseForParticipant(participantName);
    return response == null
        ? <String>{}
        : Set<String>.from(response.selectedOptionIds);
  }
}

class _InlineStatusPill extends StatelessWidget {
  const _InlineStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppPalette.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
