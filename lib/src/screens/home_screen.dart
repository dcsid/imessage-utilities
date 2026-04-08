import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_kind.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
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
  });

  final List<UtilityInstance> utilities;
  final ValueChanged<String> onOpenUtility;
  final bool Function(String rawLink) onOpenLink;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _linkController;

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
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
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
                    eyebrow: 'Live utility',
                    title: 'Messages-first utility hub',
                    description:
                        'The app starts with a When2Meet-style flow, but the shell is generic enough to become a broader toolkit for chat-native coordination.',
                  ),
                  const SizedBox(height: 18),
                  ...widget.utilities.map(_buildUtilityCard),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    eyebrow: 'Deep link handoff',
                    title: 'Try a share link',
                    description:
                        'This simulates the handoff a native iMessage extension will use to drop people into the richer Flutter experience.',
                  ),
                  const SizedBox(height: 18),
                  _buildLinkPreviewCard(),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    eyebrow: 'Future modules',
                    title: 'Expansion path',
                    description:
                        'Availability is just the first utility. The same structure can host more group-decision tools once the Messages extension and backend are wired in.',
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
                  'Messages-first utility hub',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Build the kind of utility people actually use mid-conversation.',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'This prototype pairs a future native iMessage extension with a richer Flutter companion app, starting with availability overlap and leaving room for polls, picks, and checklists later.',
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
                    onPressed: () => widget.onOpenUtility(utility.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppPalette.heroMiddle,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open availability prototype'),
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
                    label: const Text('Preview share-link handoff'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HeroMetric(
                    label: 'Response rate',
                    value: '${(responseRate * 100).round()}%',
                  ),
                  _HeroMetric(
                    label: 'Future modules',
                    value: '${UtilityKind.values.length - 1}',
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
                      utility.prompt,
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
            '$pending people still need to respond before the thread reaches full overlap.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 760;
              final overlapCard = _HighlightPanel(
                title: 'Best overlap right now',
                value: formatUtilityOption(topScore.option),
                description:
                    '${topScore.votes} of ${utility.participants.length} people can make this slot.',
                accent: accent,
                icon: Icons.auto_awesome_rounded,
              );
              final shareCard = _HighlightPanel(
                title: 'Share-ready handoff',
                value: shareUri,
                description: utility.closesAt == null
                    ? 'Openable by the companion app today and the future Messages extension later.'
                    : 'Closes ${formatDeadline(utility.closesAt!)}.',
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
            'Use this while demoing on desktop.',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'System-level Messages handoff is still future work, but this lets you simulate the exact utility-link contract inside the companion app today.',
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
                  'Utility link',
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
                  'Tap and hold to select, or use the actions below.',
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
                label: const Text('Preview linked utility'),
              ),
              OutlinedButton.icon(
                onPressed: _copySampleLink,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy sample link'),
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
            label: 'Designed to plug into the same shell',
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
    ).showSnackBar(const SnackBar(content: Text('Sample link copied.')));
  }

  void _previewLink() {
    final wasOpened = widget.onOpenLink(_linkController.text);
    if (wasOpened || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('That link does not match a known utility yet.'),
      ),
    );
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
            'Live prototype',
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
            '${topScore.votes} people overlap here right now.',
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
