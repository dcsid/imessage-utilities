import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(utility.title),
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy link',
            onPressed: () => _copyShareLink(context, shareUri),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: [accent, const Color(0xFF102A43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Created by ${utility.createdBy}. Shared into Messages as a compact utility card, with the full app handling deeper availability edits and future utility types.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFE7F0F4),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  shareUri,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFCFE0EA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Best overlap',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...utility.optionScores.map(
            (score) => _AvailabilityScoreCard(
              score: score,
              totalParticipants: utility.participants.length,
              accent: accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Participants',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: utility.participants
                    .map(
                      (participant) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F4EC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          participant,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Responses',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...utility.responses.map(
            (response) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.participantName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Responded ${formatDeadline(response.respondedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF52667A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...utility.options
                        .where(
                          (option) =>
                              response.selectedOptionIds.contains(option.id),
                        )
                        .map(
                          (option) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    formatUtilityOption(option),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFF8F4EC),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Future expansion stays inside the same shell',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This screen is backed by a generic utility model instead of a one-off scheduling screen, so the same app shell can later power polls, shared checklists, and group picks once the native Messages extension sends those links in.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    formatUtilityOption(score.option),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${score.votes}/$totalParticipants',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: coverage,
                backgroundColor: const Color(0xFFE6DDD0),
                color: accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              score.responders.isEmpty
                  ? 'No one has selected this slot yet.'
                  : 'Available: ${score.responders.join(', ')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF52667A),
                height: 1.35,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
