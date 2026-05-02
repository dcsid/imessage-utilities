import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:flutter/material.dart';

const _tabularNumerals = [FontFeature.tabularFigures()];

const _monthLabels = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// Shared outing card used on Home (vivid) and Archive (muted).
class OutingSticker extends StatelessWidget {
  const OutingSticker({
    super.key,
    required this.utility,
    required this.onOpen,
    required this.onCopyLink,
    required this.onDelete,
    this.muted = false,
  });

  final UtilityInstance utility;
  final VoidCallback onOpen;
  final VoidCallback onCopyLink;
  final VoidCallback onDelete;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppPalette.accentFor(utility.id);
    final dateLabel = _formatDateRange(utility);

    final topScore = utility.optionScores.isEmpty
        ? null
        : utility.optionScores.first;
    final headlineLine = utility.participants.isEmpty
        ? 'Add participants to start collecting'
        : topScore == null
        ? 'No time slots yet'
        : '${topScore.votes} of ${utility.participants.length} agree on the top window';
    final nextStep = muted
        ? 'Reopen to revisit the plan'
        : utility.responseCount == 0
        ? 'Collect the first availability response'
        : utility.stopCount == 0
        ? 'Add the first destination'
        : utility.expenseTrackingEnabled && utility.expenseCount == 0
        ? 'Log expenses if the group needs them'
        : 'Open and keep planning';

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.border, width: 1.6),
        boxShadow: [
          const BoxShadow(
            color: AppPalette.border,
            offset: Offset(5, 6),
            blurRadius: 0,
          ),
          BoxShadow(
            color: (muted ? AppPalette.mutedText : accent.base)
                .withValues(alpha: muted ? 0.12 : 0.22),
            offset: const Offset(0, 22),
            blurRadius: 38,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OutingHeader(
              accent: accent,
              title: utility.title,
              dateLabel: dateLabel,
              organizer: utility.createdBy,
              muted: muted,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NextStepCallout(
                    accent: accent,
                    nextStep: nextStep,
                    muted: muted,
                  ),
                  const SizedBox(height: 18),
                  _StatRow(
                    items: [
                      _StatRowItem(
                        value:
                            '${utility.responseCount}/${utility.participants.length}',
                        label: 'responded',
                      ),
                      _StatRowItem(
                        value: utility.stopCount.toString(),
                        label: 'places',
                      ),
                      _StatRowItem(
                        value: utility.activeLocationShareCount.toString(),
                        label: 'live',
                      ),
                      _StatRowItem(
                        value: utility.expenseTrackingEnabled
                            ? utility.expenseCount.toString()
                            : '—',
                        label: 'expenses',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    headlineLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.mutedText,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _OpenButton(
                          accent: accent,
                          muted: muted,
                          label: muted ? 'Reopen' : 'Open',
                          onPressed: onOpen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _IconAction(
                        icon: Icons.link_rounded,
                        tooltip: 'Copy invite link',
                        onPressed: onCopyLink,
                      ),
                      const SizedBox(width: 10),
                      _IconAction(
                        icon: Icons.more_horiz_rounded,
                        tooltip: 'More',
                        onPressed: () => _showOutingActionSheet(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOutingActionSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _OutingActionSheet(
        title: utility.title,
        onCopyLink: () {
          Navigator.of(sheetContext).pop();
          onCopyLink();
        },
        onDelete: () async {
          Navigator.of(sheetContext).pop();
          final confirmed = await _confirmDelete(context, utility.title);
          if (confirmed && context.mounted) {
            onDelete();
          }
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppPalette.border, width: 1.6),
            ),
            backgroundColor: AppPalette.surface,
            title: const Text('Delete this outing?'),
            content: Text(
              '"$title" will be removed for everyone you shared it with. This cannot be undone.',
              style: const TextStyle(color: AppPalette.mutedText, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDateRange(UtilityInstance utility) {
    final startsAt = utility.startsAt;
    final endsAt = utility.endsAt;
    if (startsAt == null || endsAt == null) {
      return 'Weekly board';
    }
    final startMonth = _monthLabels[startsAt.month - 1];
    final endMonth = _monthLabels[endsAt.month - 1];
    if (startsAt.month == endsAt.month) {
      return '$startMonth ${startsAt.day}–${endsAt.day}';
    }
    return '$startMonth ${startsAt.day} – $endMonth ${endsAt.day}';
  }
}

class _OutingHeader extends StatelessWidget {
  const _OutingHeader({
    required this.accent,
    required this.title,
    required this.dateLabel,
    required this.organizer,
    required this.muted,
  });

  final OutingAccent accent;
  final String title;
  final String dateLabel;
  final String organizer;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Muted variant uses an ink gradient instead of the accent color so
    // archived outings clearly read as past while keeping a luxe feel.
    final gradient = muted
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2F26), AppPalette.border],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.base,
              Color.lerp(accent.base, accent.ink, 0.45) ?? accent.base,
            ],
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(gradient: gradient),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (muted)
                      _MonogramChip(
                        label: 'ARCHIVED',
                        foreground: Colors.white,
                        borderColor: Colors.white.withValues(alpha: 0.55),
                      ),
                    if (muted) const SizedBox(width: 8),
                    _MonogramChip(
                      label: dateLabel,
                      foreground: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _MonogramChip(
                        label: 'BY ${organizer.toUpperCase()}',
                        foreground: Colors.white,
                        borderColor: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          OutingGlyph(accent: accent, size: 52),
        ],
      ),
    );
  }
}

class _MonogramChip extends StatelessWidget {
  const _MonogramChip({
    required this.label,
    required this.foreground,
    required this.borderColor,
  });

  final String label;
  final Color foreground;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NextStepCallout extends StatelessWidget {
  const _NextStepCallout({
    required this.accent,
    required this.nextStep,
    required this.muted,
  });

  final OutingAccent accent;
  final String nextStep;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final fill = muted ? AppPalette.surfaceMuted : accent.soft;
    final edge = muted
        ? AppPalette.borderSoft
        : accent.base.withValues(alpha: 0.35);
    final chipColor = muted ? AppPalette.ink : accent.base;
    final inkColor = muted ? AppPalette.ink : accent.ink;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: edge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.north_east_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  muted ? 'WRAPPED' : 'NEXT',
                  style: TextStyle(
                    color: inkColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextStep,
                  style: TextStyle(
                    color: inkColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.3,
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

class _StatRowItem {
  const _StatRowItem({required this.value, required this.label});
  final String value;
  final String label;
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.items});

  final List<_StatRowItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 30,
              color: AppPalette.borderSoft,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  items[i].value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabularNumerals,
                    color: AppPalette.ink,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  items[i].label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppPalette.mutedText,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _OpenButton extends StatelessWidget {
  const _OpenButton({
    required this.accent,
    required this.muted,
    required this.label,
    required this.onPressed,
  });

  final OutingAccent accent;
  final bool muted;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shadowColor = muted ? AppPalette.borderSoft : accent.base;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppPalette.ink,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.95),
                offset: const Offset(3, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppPalette.canvas,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppPalette.canvas,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.border, width: 1.4),
            ),
            child: Icon(icon, color: AppPalette.ink, size: 20),
          ),
        ),
      ),
    );
  }
}

class _OutingActionSheet extends StatelessWidget {
  const _OutingActionSheet({
    required this.title,
    required this.onCopyLink,
    required this.onDelete,
  });

  final String title;
  final VoidCallback onCopyLink;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: AppSurface(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppPalette.borderSoft,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _SheetRow(
              icon: Icons.link_rounded,
              label: 'Copy invite link',
              onTap: onCopyLink,
            ),
            const Divider(height: 1, color: AppPalette.borderSoft),
            _SheetRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete outing',
              destructive: true,
              onTap: onDelete,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppPalette.danger : AppPalette.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
