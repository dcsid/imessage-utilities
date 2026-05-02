import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _tabularNumerals = [FontFeature.tabularFigures()];

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.utilities,
    required this.onOpenUtility,
    required this.onCreateBoard,
    this.userContact,
    this.onSignOut,
  });

  final List<UtilityInstance> utilities;
  final ValueChanged<String> onOpenUtility;
  final ValueChanged<CreatePlanningBoardInput> onCreateBoard;
  final String? userContact;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 48),
                children: [
                  _Wordmark(
                    userContact: userContact,
                    onSignOut: onSignOut,
                  ),
                  const SizedBox(height: 36),
                  _Headline(
                    onCreateOuting: () => _showCreateBoardSheet(context),
                    hasOutings: utilities.isNotEmpty,
                  ),
                  const SizedBox(height: 28),
                  if (utilities.isNotEmpty) ...[
                    _StatTicker(utilities: utilities),
                    const SizedBox(height: 28),
                    const _SectionRule(label: 'Your outings'),
                    const SizedBox(height: 18),
                    ...utilities.map(
                      (utility) => Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: _OutingSticker(
                          utility: utility,
                          onOpen: () => onOpenUtility(utility.id),
                          onCopyLink: () => _copyOutingLink(context, utility),
                        ),
                      ),
                    ),
                  ] else
                    _EmptyState(
                      onCreateOuting: () => _showCreateBoardSheet(context),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateBoardSheet(BuildContext context) async {
    final result = await showModalBottomSheet<CreatePlanningBoardInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePlanningBoardSheet(
        initialOwner: _defaultOwnerName(userContact),
      ),
    );

    if (result != null && context.mounted) {
      onCreateBoard(result);
    }
  }

  static String? _defaultOwnerName(String? userContact) {
    if (userContact == null || userContact.isEmpty) {
      return null;
    }

    if (!userContact.contains('@')) {
      return null;
    }

    final localPart = userContact.split('@').first.trim();
    if (localPart.isEmpty) {
      return userContact;
    }

    return localPart
        .split(RegExp(r'[._-]+'))
        .where((chunk) => chunk.isNotEmpty)
        .map((chunk) => '${chunk[0].toUpperCase()}${chunk.substring(1)}')
        .join(' ');
  }

  Future<void> _copyOutingLink(
    BuildContext context,
    UtilityInstance utility,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: UtilityLink.forUtility(utility.id).toString()),
    );
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invite link copied.')));
  }
}

/// Top-of-page wordmark + the user's account chip.
class _Wordmark extends StatelessWidget {
  const _Wordmark({this.userContact, this.onSignOut});

  final String? userContact;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppPalette.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            'p',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppPalette.canvas,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Plan Together',
          style: theme.textTheme.titleLarge?.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: AppPalette.ink,
          ),
        ),
        const Spacer(),
        if (userContact != null)
          _AccountChip(contact: userContact!, onSignOut: onSignOut),
      ],
    );
  }
}

class _AccountChip extends StatelessWidget {
  const _AccountChip({required this.contact, this.onSignOut});

  final String contact;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final initial = contact.isEmpty ? '?' : contact[0].toUpperCase();
    return InkWell(
      onTap: onSignOut,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppPalette.border, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppPalette.ink,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppPalette.canvas,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Sign out',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editorial display headline + primary "Start an outing" CTA.
class _Headline extends StatelessWidget {
  const _Headline({required this.onCreateOuting, required this.hasOutings});

  final VoidCallback onCreateOuting;
  final bool hasOutings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasOutings ? 'PLANS IN MOTION' : 'A QUIET DASHBOARD',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppPalette.mutedText,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 14),
        RichText(
          text: TextSpan(
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
              height: 1.0,
              fontSize: 44,
            ),
            children: [
              const TextSpan(text: 'Where '),
              TextSpan(
                text: 'when',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppPalette.primary,
                ),
              ),
              const TextSpan(text: '\nmeets '),
              TextSpan(
                text: 'where',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppPalette.primary,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pick a name. Find the time. Drop the pin. Share the moment.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppPalette.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        _PrimaryAction(
          label: 'Start a new outing',
          onPressed: onCreateOuting,
        ),
      ],
    );
  }
}

/// Big chunky CTA — ink fill, hard offset shadow, no rounded-rect blandness.
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppPalette.ink,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppPalette.primary,
                offset: Offset(5, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.canvas,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppPalette.canvas,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppPalette.ink,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal numeric ticker — large display numerals with tabular figures
/// and small labels underneath, separated by ink hairlines.
class _StatTicker extends StatelessWidget {
  const _StatTicker({required this.utilities});

  final List<UtilityInstance> utilities;

  @override
  Widget build(BuildContext context) {
    final responses = utilities.fold<int>(
      0,
      (total, u) => total + u.responseCount,
    );
    final stops = utilities.fold<int>(0, (total, u) => total + u.stopCount);
    final shares = utilities.fold<int>(
      0,
      (total, u) => total + u.activeLocationShareCount,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppPalette.ink, width: 1.4),
          bottom: BorderSide(color: AppPalette.ink, width: 1.4),
        ),
      ),
      child: Row(
        children: [
          _StatCell(value: utilities.length, label: 'OUTINGS'),
          const _StatDivider(),
          _StatCell(value: responses, label: 'RESPONSES'),
          const _StatDivider(),
          _StatCell(value: stops, label: 'PLACES'),
          const _StatDivider(),
          _StatCell(value: shares, label: 'LIVE'),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              value.toString().padLeft(2, '0'),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: _tabularNumerals,
                color: AppPalette.ink,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppPalette.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: AppPalette.borderSoft,
    );
  }
}

/// Section rule — small label sitting on a hairline. Replaces the
/// boilerplate "titleLarge bold heading."
class _SectionRule extends StatelessWidget {
  const _SectionRule({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: AppPalette.ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: AppPalette.borderSoft),
        ),
        const SizedBox(width: 12),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppPalette.ink,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

/// The whole outing card: gradient sticker header up top, cream body
/// underneath. Outer wrap carries the ink stroke, hard shadow, and
/// colored bloom from the outing's accent.
class _OutingSticker extends StatelessWidget {
  const _OutingSticker({
    required this.utility,
    required this.onOpen,
    required this.onCopyLink,
  });

  final UtilityInstance utility;
  final VoidCallback onOpen;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppPalette.accentFor(utility.id);
    final dateLabel = _formatDateRange(utility);

    final topScore = utility.optionScores.isEmpty
        ? null
        : utility.optionScores.first;
    final bestOverlap = utility.participants.isEmpty
        ? 'Add participants to start collecting'
        : topScore == null
        ? 'No time slots yet'
        : '${topScore.votes} of ${utility.participants.length} agree on the top window';
    final nextStep = utility.responseCount == 0
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
            color: accent.base.withValues(alpha: 0.22),
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NextStepCallout(accent: accent, nextStep: nextStep),
                  const SizedBox(height: 18),
                  _StatRow(
                    accent: accent,
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
                    bestOverlap,
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
                        child: _OpenButton(accent: accent, onPressed: onOpen),
                      ),
                      const SizedBox(width: 10),
                      _IconAction(
                        icon: Icons.link_rounded,
                        tooltip: 'Copy invite link',
                        onPressed: onCopyLink,
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

  String _formatDateRange(UtilityInstance utility) {
    final startsAt = utility.startsAt;
    final endsAt = utility.endsAt;
    if (startsAt == null || endsAt == null) {
      return 'Weekly board';
    }
    final startMonth = _monthLabel(startsAt.month);
    final endMonth = _monthLabel(endsAt.month);
    if (startsAt.month == endsAt.month) {
      return '$startMonth ${startsAt.day}–${endsAt.day}';
    }
    return '$startMonth ${startsAt.day} – $endMonth ${endsAt.day}';
  }

  String _monthLabel(int month) {
    const labels = [
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
    return labels[month - 1];
  }
}

class _OutingHeader extends StatelessWidget {
  const _OutingHeader({
    required this.accent,
    required this.title,
    required this.dateLabel,
    required this.organizer,
  });

  final OutingAccent accent;
  final String title;
  final String dateLabel;
  final String organizer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.base,
            Color.lerp(accent.base, accent.ink, 0.45) ?? accent.base,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MonogramChip(
                      label: dateLabel,
                      foreground: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 8),
                    _MonogramChip(
                      label: 'BY ${organizer.toUpperCase()}',
                      foreground: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.55),
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
  const _NextStepCallout({required this.accent, required this.nextStep});

  final OutingAccent accent;
  final String nextStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 14),
      decoration: BoxDecoration(
        color: accent.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.base.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.base,
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
                  'NEXT',
                  style: TextStyle(
                    color: accent.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextStep,
                  style: TextStyle(
                    color: accent.ink,
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
  const _StatRow({required this.accent, required this.items});

  final OutingAccent accent;
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
  const _OpenButton({required this.accent, required this.onPressed});

  final OutingAccent accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
                color: accent.base.withValues(alpha: 0.95),
                offset: const Offset(3, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Open',
                style: TextStyle(
                  color: AppPalette.canvas,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              SizedBox(width: 8),
              Icon(
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateOuting});

  final VoidCallback onCreateOuting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A blank week,',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppPalette.mutedText,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'wide open.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Spin up your first outing — name it, drop in a few names, and the availability board takes it from there.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppPalette.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryAction(
            label: 'Create your first outing',
            onPressed: onCreateOuting,
          ),
        ],
      ),
    );
  }
}

class _CreatePlanningBoardSheet extends StatefulWidget {
  const _CreatePlanningBoardSheet({this.initialOwner});

  final String? initialOwner;

  @override
  State<_CreatePlanningBoardSheet> createState() =>
      _CreatePlanningBoardSheetState();
}

class _CreatePlanningBoardSheetState extends State<_CreatePlanningBoardSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _createdByController;
  late final TextEditingController _participantsController;
  DateTime _startDate = DateTime(2026, 4, 13);
  int _dayCount = 7;
  int _startHour = 8;
  int _endHour = 22;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _createdByController = TextEditingController(text: widget.initialOwner);
    _participantsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _createdByController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final nextDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (nextDate == null) {
      return;
    }

    setState(() {
      _startDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    final createdBy = _createdByController.text.trim();
    if (title.isEmpty || createdBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add both an outing name and organizer.')),
      );
      return;
    }
    if (_endHour <= _startHour) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an end time after the start time.'),
        ),
      );
      return;
    }

    final participants = _participantsController.text
        .split(',')
        .map((participant) => participant.trim())
        .where((participant) => participant.isNotEmpty)
        .toList(growable: false);

    Navigator.of(context).pop(
      CreatePlanningBoardInput(
        title: title,
        createdBy: createdBy,
        participants: participants,
        startDate: _startDate,
        dayCount: _dayCount,
        dayStart: Duration(hours: _startHour),
        dayEnd: Duration(hours: _endHour),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 16),
      child: AppSurface(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppPalette.borderSoft,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(
              'NEW OUTING',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppPalette.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Name it. Set the window.',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add destinations, GPS sharing, and optional expenses once the group lands on a time.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Outing name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _createdByController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Organizer'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _participantsController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Starting participants (optional)',
                hintText: 'Alex, Sam, Priya',
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(_formatStartDate(_startDate)),
                ),
                _LabeledDropdown<int>(
                  label: 'Days',
                  value: _dayCount,
                  values: const [3, 5, 7],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _dayCount = value;
                      });
                    }
                  },
                ),
                _LabeledDropdown<int>(
                  label: 'Start',
                  value: _startHour,
                  values: const [6, 7, 8, 9, 10, 11, 12],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _startHour = value;
                      });
                    }
                  },
                  labelBuilder: _formatHour,
                ),
                _LabeledDropdown<int>(
                  label: 'End',
                  value: _endHour,
                  values: const [18, 19, 20, 21, 22, 23],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _endHour = value;
                      });
                    }
                  },
                  labelBuilder: _formatHour,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryAction(
                    label: 'Create outing',
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatStartDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatHour(int hour) {
    final value = DateTime(2026, 1, 1, hour);
    final normalizedHour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$normalizedHour:$minute $suffix';
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.labelBuilder,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T?> onChanged;
  final String Function(T value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(labelBuilder?.call(item) ?? '$item'),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}
