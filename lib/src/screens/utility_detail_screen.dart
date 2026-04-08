import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
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
  });

  final UtilityInstance utility;
  final VoidCallback onBack;

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
                            'Created by ${utility.createdBy}. Shared into Messages as a compact utility card, with the companion app handling deeper edits, history, and future utility types.',
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
                  eyebrow: 'Ranked schedule overlap',
                  title: 'Best overlap',
                  description:
                      'Each slot is scored by how many people selected it, which keeps the current MVP aligned with a When2Meet-style decision flow.',
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
                  eyebrow: 'Shared group',
                  title: 'Participants',
                  description:
                      'This section becomes reusable once the app expands beyond availability into other lightweight utilities.',
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
                      'The app already exposes the response details the future backend and Messages extension will synchronize.',
                ),
                const SizedBox(height: 18),
                _buildResponses(context),
                const SizedBox(height: 16),
                AppSurface(
                  fillColor: Colors.white.withValues(alpha: 0.68),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Future expansion stays inside the same shell',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Because this screen is backed by a generic utility model rather than a hard-coded schedule view, it can grow into polls, shared checklists, and group picks once the native Messages extension begins sending those utility links.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppPalette.mutedText,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    ).showSnackBar(const SnackBar(content: Text('Utility link copied.')));
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
