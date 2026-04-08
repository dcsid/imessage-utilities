import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:chat_utilities_hub/src/presentation/availability_board.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:chat_utilities_hub/src/presentation/section_header.dart';
import 'package:chat_utilities_hub/src/presentation/utility_kind_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UtilityDetailScreen extends StatelessWidget {
  const UtilityDetailScreen({
    super.key,
    required this.utility,
    required this.onBack,
    required this.onSaveResponse,
    required this.onVoteForVenue,
    required this.onAddVenueOption,
    required this.onToggleChecklistItem,
    required this.onAddChecklistItem,
  });

  final UtilityInstance utility;
  final VoidCallback onBack;
  final void Function({
    required String utilityId,
    required String participantName,
    required Set<String> selectedOptionIds,
  })
  onSaveResponse;
  final void Function({required String utilityId, required int venueIndex})
  onVoteForVenue;
  final void Function({
    required String utilityId,
    required String name,
    required String detail,
  })
  onAddVenueOption;
  final void Function({required String utilityId, required int checklistIndex})
  onToggleChecklistItem;
  final void Function({
    required String utilityId,
    required String title,
    required String assignee,
  })
  onAddChecklistItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = utilityKindColor(utility.kind);
    final shareUri = UtilityLink.forUtility(
      utility.id,
      kind: utility.kind.name,
    ).toString();
    final topScore = utility.optionScores.first;
    final pending = utility.participants.length - utility.responseCount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(utility.title),
        actions: [
          IconButton(
            tooltip: 'Copy link',
            onPressed: () => _copyShareLink(context, shareUri),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: AppBackdrop(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                AppSurface(
                  radius: 38,
                  padding: const EdgeInsets.all(28),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.94),
                      AppPalette.heroStart,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderColor: Colors.white.withValues(alpha: 0.12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 860;
                      final mainColumn = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _HeroChip(
                                label: utility.kind.label,
                                foregroundColor: Colors.white,
                              ),
                              _HeroChip(
                                label:
                                    '${utility.responseCount}/${utility.participants.length} responded',
                                foregroundColor: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            utility.prompt,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${utility.eventSummary} Created by ${utility.createdBy}, with Messages acting as the quick-create surface and Flutter handling the full planning board.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              shareUri,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      );

                      final summaryPanel = Column(
                        children: [
                          _SummaryMetric(
                            label: 'Best overlap',
                            value:
                                '${topScore.votes}/${utility.participants.length}',
                            detail: formatUtilityOption(topScore.option),
                            accent: AppPalette.lime,
                          ),
                          const SizedBox(height: 12),
                          _SummaryMetric(
                            label: 'Waiting on',
                            value: '$pending',
                            detail: 'people to respond',
                            accent: AppPalette.gold,
                          ),
                          if (utility.closesAt != null) ...[
                            const SizedBox(height: 12),
                            _SummaryMetric(
                              label: 'Closes',
                              value: formatDeadline(utility.closesAt!),
                              detail: 'current response window',
                              accent: AppPalette.sky,
                            ),
                          ],
                        ],
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: mainColumn),
                            const SizedBox(width: 18),
                            Expanded(flex: 4, child: summaryPanel),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          mainColumn,
                          const SizedBox(height: 18),
                          summaryPanel,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  eyebrow: 'When2Meet board',
                  title: 'Availability grid',
                  description:
                      'This is the main product surface: a full overlap board people can open from Messages, mobile, or desktop before any other event-planning step happens.',
                ),
                const SizedBox(height: 18),
                AppSurface(
                  child: AvailabilityBoard(utility: utility, accent: accent),
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  eyebrow: 'Respond now',
                  title: 'Fill in availability',
                  description:
                      'Pick a participant, tap the time windows that work, and save back into the shared board.',
                ),
                const SizedBox(height: 18),
                _ResponseComposerCard(
                  utility: utility,
                  accent: accent,
                  onSaveResponse: onSaveResponse,
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  eyebrow: 'Ranked schedule overlap',
                  title: 'Best overlap',
                  description:
                      'The ranked view makes it easy to summarize the strongest options back into iMessage after people fill in the board.',
                ),
                const SizedBox(height: 18),
                ...utility.optionScores.map(
                  (score) => _AvailabilityScoreCard(
                    score: score,
                    totalParticipants: utility.participants.length,
                    accent: accent,
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  eyebrow: 'Event planning stack',
                  title: 'Venue vote and checklist',
                  description:
                      'Time overlap is the hero, but the same plan should also hold the next decisions that keep an event moving.',
                ),
                const SizedBox(height: 18),
                _buildPlanningTools(context),
                const SizedBox(height: 28),
                const SectionHeader(
                  eyebrow: 'Shared group',
                  title: 'Participants',
                  description:
                      'Everyone stays tied to the same planning board so headcount, overlap, and final details never drift apart.',
                ),
                const SizedBox(height: 18),
                AppSurface(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: utility.participants
                        .map(
                          (participant) => _ParticipantChip(name: participant),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader(
                  eyebrow: 'Current submissions',
                  title: 'Responses',
                  description:
                      'These are the selections the native Messages surface and the Flutter planning app will both read from the same backend later on.',
                ),
                const SizedBox(height: 18),
                _buildResponses(context),
                const SizedBox(height: 28),
                const SectionHeader(
                  eyebrow: 'Messages-native flow',
                  title: 'iMessage integration path',
                  description:
                      'The extension should stay lightweight: create in chat, respond quickly, then open this full board only when someone needs the richer planner.',
                ),
                const SizedBox(height: 18),
                _buildIntegrationFlow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanningTools(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 960
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Venue shortlist',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showAddVenueSheet(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add venue'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...utility.venueOptions.asMap().entries.map(
                      (entry) => _PlanningVenueRow(
                        option: entry.value,
                        onVote:
                            () => onVoteForVenue(
                              utilityId: utility.id,
                              venueIndex: entry.key,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Checklist',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showAddChecklistSheet(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text('Add task'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...utility.checklistItems.asMap().entries.map(
                      (entry) => _ChecklistRow(
                        item: entry.value,
                        onToggle:
                            () => onToggleChecklistItem(
                              utilityId: utility.id,
                              checklistIndex: entry.key,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntegrationFlow(BuildContext context) {
    return AppSurface(
      fillColor: Colors.white.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: utility.planningUpdates
            .map((update) => _PlanningUpdateRow(update: update))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildResponses(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 960
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: utility.responses
              .map(
                (response) => SizedBox(
                  width: cardWidth,
                  child: _ResponseCard(
                    response: response,
                    utility: utility,
                    accent: utilityKindColor(utility.kind),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Future<void> _copyShareLink(BuildContext context, String shareUri) async {
    await Clipboard.setData(ClipboardData(text: shareUri));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Planning link copied.')));
  }

  Future<void> _showAddVenueSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_VenueDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddVenueSheet(),
    );
    if (result == null || !context.mounted) {
      return;
    }

    onAddVenueOption(
      utilityId: utility.id,
      name: result.name,
      detail: result.detail,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${result.name} to the venue shortlist.')),
    );
  }

  Future<void> _showAddChecklistSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_ChecklistDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddChecklistSheet(participants: utility.participants),
    );
    if (result == null || !context.mounted) {
      return;
    }

    onAddChecklistItem(
      utilityId: utility.id,
      title: result.title,
      assignee: result.assignee,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${result.title}" to the checklist.')),
    );
  }
}

class _AvailabilityScoreCard extends StatelessWidget {
  const _AvailabilityScoreCard({
    required this.score,
    required this.totalParticipants,
    required this.accent,
  });

  final UtilityOptionScore score;
  final int totalParticipants;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverage = score.coverage(totalParticipants);

    return AppSurface(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.schedule_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatUtilityOption(score.option),
                      style: theme.textTheme.titleLarge?.copyWith(height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${score.votes} of $totalParticipants people selected this slot.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppPalette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${(coverage * 100).round()}%',
                style: theme.textTheme.headlineSmall?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: coverage,
              backgroundColor: const Color(0xFFE3EAF2),
              color: accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            score.responders.isEmpty
                ? 'No one has selected this slot yet.'
                : 'Available: ${score.responders.join(', ')}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
  });

  final String label;
  final String value;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      padding: const EdgeInsets.all(18),
      fillColor: Colors.white.withValues(alpha: 0.12),
      borderColor: Colors.white.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: accent,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantChip extends StatelessWidget {
  const _ParticipantChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((piece) => piece.isNotEmpty)
        .take(2)
        .map((piece) => piece.characters.first.toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppPalette.heroMiddle, AppPalette.sky],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PlanningVenueRow extends StatelessWidget {
  const _PlanningVenueRow({required this.option, required this.onVote});

  final PlanningVenueOption option;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9F0A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: Color(0xFFFF9F0A),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  option.detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.mutedText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              FilledButton.tonalIcon(
                onPressed: onVote,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9F0A).withValues(
                    alpha: 0.14,
                  ),
                  foregroundColor: const Color(0xFFFF9F0A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.how_to_vote_rounded, size: 18),
                label: const Text('Vote'),
              ),
              const SizedBox(height: 8),
              Text(
                '${option.votes} votes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFF9F0A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item, required this.onToggle});

  final PlanningChecklistItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = item.isComplete ? AppPalette.lime : AppPalette.gold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.isComplete ? Icons.check_rounded : Icons.schedule_rounded,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Owner: ${item.assignee}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: onToggle,
            style: FilledButton.styleFrom(
              backgroundColor: accent.withValues(alpha: 0.14),
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            icon: Icon(
              item.isComplete ? Icons.undo_rounded : Icons.check_rounded,
              size: 18,
            ),
            label: Text(item.isComplete ? 'Reopen' : 'Complete'),
          ),
        ],
      ),
    );
  }
}

class _PlanningUpdateRow extends StatelessWidget {
  const _PlanningUpdateRow({required this.update});

  final PlanningUpdate update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppPalette.heroMiddle.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppPalette.heroMiddle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(update.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  update.detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.mutedText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseComposerCard extends StatefulWidget {
  const _ResponseComposerCard({
    required this.utility,
    required this.accent,
    required this.onSaveResponse,
  });

  final UtilityInstance utility;
  final Color accent;
  final void Function({
    required String utilityId,
    required String participantName,
    required Set<String> selectedOptionIds,
  })
  onSaveResponse;

  @override
  State<_ResponseComposerCard> createState() => _ResponseComposerCardState();
}

class _ResponseComposerCardState extends State<_ResponseComposerCard> {
  late String _participantName;
  late Set<String> _selectedOptionIds;

  @override
  void initState() {
    super.initState();
    _participantName = _initialParticipant(widget.utility);
    _selectedOptionIds = _selectionsFor(widget.utility, _participantName);
  }

  @override
  void didUpdateWidget(covariant _ResponseComposerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.utility != widget.utility) {
      if (!widget.utility.participants.contains(_participantName)) {
        _participantName = _initialParticipant(widget.utility);
      }
      _selectedOptionIds = _selectionsFor(widget.utility, _participantName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingResponse = widget.utility.responseForParticipant(
      _participantName,
    );

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('${widget.utility.id}-$_participantName'),
                  initialValue: _participantName,
                  decoration: const InputDecoration(labelText: 'Participant'),
                  items: widget.utility.participants
                      .map(
                        (participant) => DropdownMenuItem<String>(
                          value: participant,
                          child: Text(participant),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _participantName = value;
                      _selectedOptionIds = _selectionsFor(
                        widget.utility,
                        _participantName,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              _HeroChip(
                label: existingResponse == null ? 'No reply yet' : 'Editing reply',
                foregroundColor: widget.accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Tap every time block that works for $_participantName.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
            ),
          ),
          const SizedBox(height: 18),
          AvailabilityBoard(
            utility: widget.utility,
            accent: widget.accent,
            mode: AvailabilityBoardMode.selection,
            selectedOptionIds: _selectedOptionIds,
            onToggleOption: (optionId) {
              setState(() {
                final nextSelections = Set<String>.from(_selectedOptionIds);
                if (!nextSelections.add(optionId)) {
                  nextSelections.remove(optionId);
                }
                _selectedOptionIds = nextSelections;
              });
            },
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _selectedOptionIds.isEmpty
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
                child: const Text('Reset to saved'),
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
    return utility.participants.first;
  }

  Set<String> _selectionsFor(UtilityInstance utility, String participantName) {
    final response = utility.responseForParticipant(participantName);
    return response == null
        ? <String>{}
        : Set<String>.from(response.selectedOptionIds);
  }
}

class _VenueDraft {
  const _VenueDraft({required this.name, required this.detail});

  final String name;
  final String detail;
}

class _ChecklistDraft {
  const _ChecklistDraft({required this.title, required this.assignee});

  final String title;
  final String assignee;
}

class _AddVenueSheet extends StatefulWidget {
  const _AddVenueSheet();

  @override
  State<_AddVenueSheet> createState() => _AddVenueSheetState();
}

class _AddVenueSheetState extends State<_AddVenueSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _detailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _detailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final detail = _detailController.text.trim();
    if (name.isEmpty || detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add both a venue name and a short note.')),
      );
      return;
    }

    Navigator.of(context).pop(_VenueDraft(name: name, detail: detail));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 16),
      child: AppSurface(
        radius: 30,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add venue idea', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Drop a shortlist option onto this board so the schedule winner can turn into a final plan quickly.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Venue name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Quick note'),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('Add venue'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChecklistSheet extends StatefulWidget {
  const _AddChecklistSheet({required this.participants});

  final List<String> participants;

  @override
  State<_AddChecklistSheet> createState() => _AddChecklistSheetState();
}

class _AddChecklistSheetState extends State<_AddChecklistSheet> {
  late final TextEditingController _titleController;
  late String _assignee;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _assignee = widget.participants.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a task title before saving.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _ChecklistDraft(title: title, assignee: _assignee),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 16),
      child: AppSurface(
        radius: 30,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add checklist task',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Keep the post-scheduling work attached to the same board so the plan stays in one place.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _assignee,
              decoration: const InputDecoration(labelText: 'Assignee'),
              items: widget.participants
                  .map(
                    (participant) => DropdownMenuItem<String>(
                      value: participant,
                      child: Text(participant),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _assignee = value;
                });
              },
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Add task'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.response,
    required this.utility,
    required this.accent,
  });

  final UtilityResponse response;
  final UtilityInstance utility;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedOptions = utility.options
        .where((option) => response.selectedOptionIds.contains(option.id))
        .toList(growable: false);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.person_rounded, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.participantName,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Responded ${formatDeadline(response.respondedAt)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppPalette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: selectedOptions
                .map(
                  (option) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatUtilityOption(option),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.foregroundColor});

  final String label;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: foregroundColor),
      ),
    );
  }
}
