import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  _Header(
                    userContact: userContact,
                    onCreateOuting: () => _showCreateBoardSheet(context),
                    onSignOut: onSignOut,
                  ),
                  const SizedBox(height: 24),
                  if (utilities.isNotEmpty) ...[
                    _DashboardStats(utilities: utilities),
                    const SizedBox(height: 20),
                    Text(
                      'Your outings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (utilities.isEmpty)
                    _EmptyState(
                      onCreateOuting: () => _showCreateBoardSheet(context),
                    )
                  else
                    ...utilities.map(
                      (utility) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OutingCard(
                          utility: utility,
                          onOpen: () => onOpenUtility(utility.id),
                          onCopyLink: () => _copyOutingLink(context, utility),
                        ),
                      ),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.onCreateOuting,
    this.userContact,
    this.onSignOut,
  });

  final VoidCallback onCreateOuting;
  final String? userContact;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Outings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Every outing starts the same way: name it, find the best time on the availability board, then add places, GPS sharing, and optional costs only if the group needs them.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppPalette.mutedText,
                  height: 1.5,
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onCreateOuting,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New outing'),
              ),
              if (userContact != null)
                OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(userContact!),
                ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 16),
                actions,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 18), actions],
          );
        },
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({required this.utilities});

  final List<UtilityInstance> utilities;

  @override
  Widget build(BuildContext context) {
    final totalResponses = utilities.fold<int>(
      0,
      (total, utility) => total + utility.responseCount,
    );
    final totalStops = utilities.fold<int>(
      0,
      (total, utility) => total + utility.stopCount,
    );
    final totalExpenses = utilities.fold<int>(
      0,
      (total, utility) => total + utility.expenseCount,
    );
    final activeShares = utilities.fold<int>(
      0,
      (total, utility) => total + utility.activeLocationShareCount,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricPill(label: '${utilities.length} outings'),
        _MetricPill(label: '$totalResponses responses'),
        _MetricPill(label: '$totalStops places planned'),
        _MetricPill(label: '$activeShares live shares'),
        _MetricPill(label: '$totalExpenses expenses logged'),
      ],
    );
  }
}

class _OutingCard extends StatelessWidget {
  const _OutingCard({
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
    final topScore = utility.optionScores.isEmpty
        ? null
        : utility.optionScores.first;
    final bestOverlap = utility.participants.isEmpty
        ? 'No participants yet'
        : topScore == null
        ? 'No time slots yet'
        : '${topScore.votes}/${utility.participants.length} available';
    final nextStep = utility.responseCount == 0
        ? 'Collect the first availability response'
        : utility.stopCount == 0
        ? 'Add the first destination'
        : utility.expenseTrackingEnabled && utility.expenseCount == 0
        ? 'Add expenses only if this outing needs them'
        : 'Open the outing and keep planning';

    return AppSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            utility.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateRange(utility),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                label:
                    '${utility.responseCount}/${utility.participants.length} responded',
              ),
              _MetricPill(label: bestOverlap),
              _MetricPill(label: '${utility.stopCount} places'),
              _MetricPill(
                label: utility.expenseTrackingEnabled
                    ? '${utility.expenseCount} expenses'
                    : 'Expenses off',
              ),
              _MetricPill(label: 'Organizer: ${utility.createdBy}'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_rounded, color: AppPalette.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next step',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppPalette.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextStep,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
              FilledButton(onPressed: onOpen, child: const Text('Open outing')),
              OutlinedButton.icon(
                onPressed: onCopyLink,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy invite link'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateRange(UtilityInstance utility) {
    final startsAt = utility.startsAt;
    final endsAt = utility.endsAt;
    if (startsAt == null || endsAt == null) {
      return 'Weekly outing board';
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

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppPalette.text,
          fontWeight: FontWeight.w700,
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
    return AppSurface(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No outings yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Create the first outing, give it a name, and start with the availability board before you worry about destinations, GPS sharing, or optional costs.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppPalette.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreateOuting,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create outing'),
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

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 16),
      child: AppSurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create outing',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by naming the outing and choosing the availability window. You can add destinations, GPS sharing, and optional expenses after the group agrees on the best time.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.mutedText),
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 20),
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
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Create outing'),
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
