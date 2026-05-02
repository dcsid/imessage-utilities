import 'package:chat_utilities_hub/src/auth/identity_helpers.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:chat_utilities_hub/src/presentation/outing_sticker.dart';
import 'package:chat_utilities_hub/src/screens/past_outings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _tabularNumerals = [FontFeature.tabularFigures()];

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.utilities,
    required this.onOpenUtility,
    required this.onCreateBoard,
    required this.onDeleteUtility,
    this.userContact,
    this.onSignOut,
  });

  final List<UtilityInstance> utilities;
  final ValueChanged<String> onOpenUtility;
  final ValueChanged<CreatePlanningBoardInput> onCreateBoard;
  final ValueChanged<String> onDeleteUtility;
  final String? userContact;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active = <UtilityInstance>[];
    final past = <UtilityInstance>[];
    for (final utility in utilities) {
      if (_isPast(utility, now)) {
        past.add(utility);
      } else {
        active.add(utility);
      }
    }

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
                    hasActive: active.isNotEmpty,
                    hasOutings: utilities.isNotEmpty,
                  ),
                  const SizedBox(height: 28),
                  if (active.isNotEmpty) ...[
                    _StatTicker(active: active, past: past),
                    const SizedBox(height: 28),
                    const _SectionRule(label: 'Plans in motion'),
                    const SizedBox(height: 18),
                    ...active.map(
                      (utility) => Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: OutingSticker(
                          utility: utility,
                          onOpen: () => onOpenUtility(utility.id),
                          onCopyLink: () => _copyOutingLink(context, utility),
                          onDelete: () => _handleDelete(context, utility),
                        ),
                      ),
                    ),
                  ] else if (utilities.isNotEmpty) ...[
                    const _ActiveEmptyHint(),
                    const SizedBox(height: 24),
                  ] else
                    _EmptyState(
                      onCreateOuting: () => _showCreateBoardSheet(context),
                    ),
                  if (past.isNotEmpty)
                    _ArchiveEntry(
                      count: past.length,
                      onTap: () => _openArchive(context, past),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openArchive(BuildContext context, List<UtilityInstance> past) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PastOutingsScreen(
          utilities: past,
          onOpenUtility: onOpenUtility,
          onCopyLink: (utility) => _copyOutingLink(context, utility),
          onDeleteUtility: (utility) => onDeleteUtility(utility.id),
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, UtilityInstance utility) {
    onDeleteUtility(utility.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${utility.title}" deleted.')),
      );
    }
  }

  bool _isPast(UtilityInstance utility, DateTime now) {
    final closesAt = utility.closesAt;
    if (closesAt != null) {
      return closesAt.isBefore(now);
    }
    final endsAt = utility.endsAt;
    if (endsAt != null) {
      return endsAt.isBefore(now);
    }
    return false;
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

  static String? _defaultOwnerName(String? userContact) =>
      displayNameFromContact(userContact);

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

class _Headline extends StatelessWidget {
  const _Headline({
    required this.onCreateOuting,
    required this.hasActive,
    required this.hasOutings,
  });

  final VoidCallback onCreateOuting;
  final bool hasActive;
  final bool hasOutings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eyebrow = hasActive
        ? 'PLANS IN MOTION'
        : hasOutings
        ? 'A QUIET WEEK'
        : 'A QUIET DASHBOARD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
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

class _StatTicker extends StatelessWidget {
  const _StatTicker({required this.active, required this.past});

  final List<UtilityInstance> active;
  final List<UtilityInstance> past;

  @override
  Widget build(BuildContext context) {
    final responses = active.fold<int>(
      0,
      (total, u) => total + u.responseCount,
    );
    final stops = active.fold<int>(0, (total, u) => total + u.stopCount);
    final shares = active.fold<int>(
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
          _StatCell(value: active.length, label: 'ACTIVE'),
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
    return Container(width: 1, height: 44, color: AppPalette.borderSoft);
  }
}

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
        Expanded(child: Container(height: 1, color: AppPalette.borderSoft)),
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

/// Shown when the user has outings — but they're all archived. Not the
/// full empty state, just a soft prompt.
class _ActiveEmptyHint extends StatelessWidget {
  const _ActiveEmptyHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing on the calendar.',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Past outings live in the archive. Spin up a new one to fill the week.',
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

/// Subtle entry to the archive. Reads as a "shelf" — wide, low-emphasis,
/// nothing demanding attention.
class _ArchiveEntry extends StatelessWidget {
  const _ArchiveEntry({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            color: AppPalette.canvasDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppPalette.borderSoft, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppPalette.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.archive_outlined,
                  color: AppPalette.canvas,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Archive',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.ink,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count past ${count == 1 ? 'outing' : 'outings'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppPalette.ink,
                size: 20,
              ),
            ],
          ),
        ),
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
