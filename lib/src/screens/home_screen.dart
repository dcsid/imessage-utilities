import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/planning_board_draft.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_kind.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:chat_utilities_hub/src/presentation/availability_board.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:chat_utilities_hub/src/presentation/section_header.dart';
import 'package:chat_utilities_hub/src/presentation/utility_kind_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.utilities,
    required this.onOpenUtility,
    required this.onOpenLink,
    required this.onCreateBoard,
    required this.composeDraft,
    required this.onComposeDraftHandled,
  });

  final List<UtilityInstance> utilities;
  final ValueChanged<String> onOpenUtility;
  final bool Function(String rawLink) onOpenLink;
  final ValueChanged<CreatePlanningBoardInput> onCreateBoard;
  final PlanningBoardDraft? composeDraft;
  final VoidCallback onComposeDraftHandled;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _linkController;
  String? _activeComposeDraftSignature;

  @override
  void initState() {
    super.initState();
    final sampleUtility = widget.utilities.first;
    _linkController = TextEditingController(
      text: UtilityLink.forUtility(
        sampleUtility.id,
        kind: sampleUtility.kind.name,
      ).toString(),
    );
    _scheduleComposeDraftIfNeeded();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFirstId = oldWidget.utilities.isEmpty ? null : oldWidget.utilities.first.id;
    final newFirstId = widget.utilities.isEmpty ? null : widget.utilities.first.id;
    if (oldFirstId != newFirstId && widget.utilities.isNotEmpty) {
      final sampleUtility = widget.utilities.first;
      _linkController.text = UtilityLink.forUtility(
        sampleUtility.id,
        kind: sampleUtility.kind.name,
      ).toString();
    }
    if (oldWidget.composeDraft != null && widget.composeDraft == null) {
      _activeComposeDraftSignature = null;
    }
    _scheduleComposeDraftIfNeeded();
  }

  void _scheduleComposeDraftIfNeeded() {
    final composeDraft = widget.composeDraft;
    if (composeDraft == null) {
      return;
    }

    final signature = _composeDraftSignature(composeDraft);
    if (_activeComposeDraftSignature == signature) {
      return;
    }
    _activeComposeDraftSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.composeDraft == null) {
        return;
      }
      _showCreateBoardSheet(
        draft: widget.composeDraft,
        clearComposeDraftWhenDone: true,
      );
    });
  }

  Future<void> _showCreateBoardSheet({
    PlanningBoardDraft? draft,
    bool clearComposeDraftWhenDone = false,
  }) async {
    final result = await showModalBottomSheet<CreatePlanningBoardInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePlanningBoardSheet(draft: draft),
    );

    if (clearComposeDraftWhenDone && mounted) {
      widget.onComposeDraftHandled();
    }

    if (result == null || !mounted) {
      return;
    }

    widget.onCreateBoard(result);
  }

  @override
  Widget build(BuildContext context) {
    final featuredUtility = widget.utilities.first;

    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  _buildHero(featuredUtility),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    eyebrow: 'Availability first',
                    title: 'Plan around the scheduling board',
                    description:
                        'The core product is a full When2Meet-style planning board. Venue choice, guest updates, and reminders sit around the same event instead of becoming separate apps.',
                  ),
                  const SizedBox(height: 18),
                  ...widget.utilities.map(_buildUtilityCard),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    eyebrow: 'Messages handoff',
                    title: 'Preview the iMessage handoff',
                    description:
                        'The native Messages extension stays thin. It creates the availability board in chat, then hands people into this richer Flutter planner when they need the full board.',
                  ),
                  const SizedBox(height: 18),
                  _buildLinkPreviewCard(),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    eyebrow: 'Event planning extras',
                    title: 'Built around the schedule',
                    description:
                        'Scheduling is the hero, but a good event planner also needs a venue vote, a checklist, and guest communication tied to the same plan.',
                  ),
                  const SizedBox(height: 18),
                  _buildFutureUtilities(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(UtilityInstance utility) {
    final theme = Theme.of(context);
    final topScore = utility.optionScores.first;
    final responseRate = utility.responseCount / utility.participants.length;

    return AppSurface(
      radius: 38,
      padding: const EdgeInsets.all(28),
      gradient: const LinearGradient(
        colors: [
          AppPalette.heroStart,
          AppPalette.heroMiddle,
          AppPalette.heroEnd,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Colors.white.withValues(alpha: 0.16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 840;

          final mainPanel = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'When2Meet plus iMessage',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Plan the event in chat, then open the full board in Flutter.',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'This product starts as a real availability planner people could use even without Messages. The iMessage extension becomes the fastest way to create and share the board inside a group thread.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showCreateBoardSheet(),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppPalette.heroStart,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create a board'),
                  ),
                  FilledButton.icon(
                    onPressed: () => widget.onOpenUtility(utility.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open planning board'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _previewLink,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_outward_rounded),
                    label: const Text('Preview iMessage handoff'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HeroMetric(
                    label: 'Reply rate',
                    value: '${(responseRate * 100).round()}%',
                  ),
                  _HeroMetric(
                    label: 'Boards live',
                    value: '${widget.utilities.length}',
                  ),
                  _HeroMetric(
                    label: 'Best slot',
                    value: '${topScore.votes}/${utility.participants.length}',
                  ),
                ],
              ),
            ],
          );

          final sidePanel = _HeroSidePanel(
            utility: utility,
            topScore: topScore,
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: mainPanel),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: sidePanel),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [mainPanel, const SizedBox(height: 20), sidePanel],
          );
        },
      ),
    );
  }

  Widget _buildUtilityCard(UtilityInstance utility) {
    final theme = Theme.of(context);
    final topScore = utility.optionScores.first;
    final accent = utilityKindColor(utility.kind);
    final responseRate = utility.responseCount / utility.participants.length;
    final pending = utility.participants.length - utility.responseCount;
    final shareUri = UtilityLink.forUtility(
      utility.id,
      kind: utility.kind.name,
    ).toString();

    return AppSurface(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 62,
                width: 62,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  utilityKindIcon(utility.kind),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _CapsuleTag(label: utility.kind.label, accent: accent),
                        _CapsuleTag(
                          label:
                              '${utility.responseCount}/${utility.participants.length} responses',
                          accent: AppPalette.heroMiddle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      utility.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      utility.eventSummary,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppPalette.mutedText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () => widget.onOpenUtility(utility.id),
                style: FilledButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: 0.14),
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: responseRate,
              backgroundColor: const Color(0xFFE7EEF5),
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$pending people still need to respond before the event time is safe to lock.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
            ),
          ),
          const SizedBox(height: 22),
          AvailabilityBoard(utility: utility, accent: accent, compact: true),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 760;
              final overlapCard = _HighlightPanel(
                title: 'Best overlap right now',
                value: formatUtilityOption(topScore.option),
                description:
                    '${topScore.votes} of ${utility.participants.length} people can make this slot, so this is the strongest candidate to send back to Messages.',
                accent: accent,
                icon: Icons.auto_awesome_rounded,
              );
              final shareCard = _HighlightPanel(
                title: 'Messages-ready handoff',
                value: shareUri,
                description: utility.closesAt == null
                    ? 'Openable by the Flutter planner today and the native Messages extension once that shell is wired in.'
                    : 'The current response window closes ${formatDeadline(utility.closesAt!)}.',
                accent: AppPalette.heroMiddle,
                icon: Icons.link_rounded,
                monospaceValue: true,
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: overlapCard),
                    const SizedBox(width: 14),
                    Expanded(child: shareCard),
                  ],
                );
              }

              return Column(
                children: [overlapCard, const SizedBox(height: 14), shareCard],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLinkPreviewCard() {
    final theme = Theme.of(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Use this until the Messages composer is fully wired in.',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'The link below is the same contract the native iMessage extension will send. It keeps the planning flow mostly in Flutter and Dart while letting Messages own the quick in-chat entry point.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppPalette.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planning link',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.mutedText,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  _linkController.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.text,
                    height: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap and hold to select it, or use the actions below.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _previewLink,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.heroMiddle,
                ),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Open planning board'),
              ),
              OutlinedButton.icon(
                onPressed: _copySampleLink,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy planning link'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFutureUtilities() {
    final utilities = UtilityKind.values
        .where((kind) => kind != UtilityKind.availability)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 960
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth > 620
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: utilities
              .map(
                (kind) => SizedBox(
                  width: cardWidth,
                  child: _buildFutureUtilityCard(kind),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildFutureUtilityCard(UtilityKind kind) {
    final theme = Theme.of(context);
    final accent = utilityKindColor(kind);

    return AppSurface(
      padding: const EdgeInsets.all(20),
      fillColor: Colors.white.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(utilityKindIcon(kind), color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            kind.label,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            kind.blurb,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _CapsuleTag(
            label: 'Built for the same planning board',
            accent: accent,
          ),
        ],
      ),
    );
  }

  Future<void> _copySampleLink() async {
    await Clipboard.setData(ClipboardData(text: _linkController.text));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Planning link copied.')));
  }

  void _previewLink() {
    final wasOpened = widget.onOpenLink(_linkController.text);
    if (wasOpened || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('That link does not match a known planning board yet.'),
      ),
    );
  }

  String _composeDraftSignature(PlanningBoardDraft draft) {
    return [
      draft.title ?? '',
      draft.prompt ?? '',
      draft.createdBy ?? '',
      draft.participants.join(','),
    ].join('|');
  }
}

class _HeroSidePanel extends StatelessWidget {
  const _HeroSidePanel({required this.utility, required this.topScore});

  final UtilityInstance utility;
  final UtilityOptionScore topScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shareUri = UtilityLink.forUtility(
      utility.id,
      kind: utility.kind.name,
    ).toString();

    return AppSurface(
      radius: 30,
      padding: const EdgeInsets.all(20),
      fillColor: Colors.white.withValues(alpha: 0.16),
      borderColor: Colors.white.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live planning board',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            utility.title,
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            formatUtilityOption(topScore.option),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${topScore.votes} people overlap here right now. Venue voting comes next.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
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
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapsuleTag extends StatelessWidget {
  const _CapsuleTag({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accent),
      ),
    );
  }
}

class _HighlightPanel extends StatelessWidget {
  const _HighlightPanel({
    required this.title,
    required this.value,
    required this.description,
    required this.accent,
    required this.icon,
    this.monospaceValue = false,
  });

  final String title;
  final String value;
  final String description;
  final Color accent;
  final IconData icon;
  final bool monospaceValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: monospaceValue
                ? theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: AppPalette.text,
                    height: 1.45,
                  )
                : theme.textTheme.titleLarge?.copyWith(height: 1.25),
          ),
          const SizedBox(height: 8),
          Text(
            description,
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

class _CreatePlanningBoardSheet extends StatefulWidget {
  const _CreatePlanningBoardSheet({this.draft});

  final PlanningBoardDraft? draft;

  @override
  State<_CreatePlanningBoardSheet> createState() =>
      _CreatePlanningBoardSheetState();
}

class _CreatePlanningBoardSheetState extends State<_CreatePlanningBoardSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _promptController;
  late final TextEditingController _creatorController;
  late final TextEditingController _participantsController;
  late DateTime _startDate;
  late int _dayCount;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final draft = widget.draft;
    _titleController = TextEditingController(
      text: draft?.title ?? 'Team dinner plan',
    );
    _promptController = TextEditingController(
      text:
          draft?.prompt ??
          'Find the best overlap first, then use the same board to finish the event details.',
    );
    _creatorController = TextEditingController(text: draft?.createdBy ?? 'Maya');
    _participantsController = TextEditingController(
      text: draft != null && draft.participants.isNotEmpty
          ? draft.participants.join(', ')
          : 'Maya, Jordan, Ari, Nina, Chris',
    );
    _startDate = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    _dayCount = 4;
    _startTime = const TimeOfDay(hour: 18, minute: 0);
    _endTime = const TimeOfDay(hour: 21, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _creatorController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _startDate,
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(selected.year, selected.month, selected.day);
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  void _submit() {
    final participants = _participantsController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (_titleController.text.trim().isEmpty ||
        _creatorController.text.trim().isEmpty ||
        participants.length < 2 ||
        endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a title, at least two participants, and a valid time range.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      CreatePlanningBoardInput(
        title: _titleController.text.trim(),
        prompt: _promptController.text.trim(),
        createdBy: _creatorController.text.trim(),
        participants: participants,
        startDate: _startDate,
        dayCount: _dayCount,
        dayStart: Duration(minutes: startMinutes),
        dayEnd: Duration(minutes: endMinutes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 16),
      child: AppSurface(
        radius: 32,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create planning board', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'This keeps the full board in Flutter/Dart, while the future iMessage extension can become the quick-create surface later.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppPalette.mutedText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Plan summary'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _creatorController,
                decoration: const InputDecoration(labelText: 'Organizer'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _participantsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Participants',
                  hintText: 'Maya, Jordan, Ari',
                ),
              ),
              const SizedBox(height: 16),
              Text('Scheduling window', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PickerButton(
                    label: 'Start date',
                    value:
                        '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                    onPressed: _pickStartDate,
                  ),
                  _PickerButton(
                    label: 'Start time',
                    value: _startTime.format(context),
                    onPressed: () => _pickTime(isStart: true),
                  ),
                  _PickerButton(
                    label: 'End time',
                    value: _endTime.format(context),
                    onPressed: () => _pickTime(isStart: false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Days to include', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [3, 4, 5, 7]
                    .map(
                      (count) => ChoiceChip(
                        label: Text('$count days'),
                        selected: _dayCount == count,
                        onSelected: (_) => setState(() => _dayCount = count),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Create board'),
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
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.mutedText,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
