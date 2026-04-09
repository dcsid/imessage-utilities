import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_link.dart';
import 'package:chat_utilities_hub/src/presentation/app_backdrop.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:chat_utilities_hub/src/presentation/availability_board.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.utilities,
    required this.onOpenUtility,
    required this.onCreateBoard,
  });

  final List<UtilityInstance> utilities;
  final ValueChanged<String> onOpenUtility;
  final ValueChanged<CreatePlanningBoardInput> onCreateBoard;

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
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  if (utilities.isEmpty)
                    _EmptyState(onCreateBoard: () => _showCreateBoardSheet(context))
                  else
                    ...utilities.map((utility) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _BoardCard(
                        utility: utility,
                        onOpen: () => onOpenUtility(utility.id),
                        onCopyLink: () => _copyBoardLink(context, utility),
                      ),
                    )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                'Plan Together',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A minimal group outing planner: find overlap fast, map the stops you care about, and keep optional location sharing simple.',
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
                onPressed: () => _showCreateBoardSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create board'),
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
            children: [
              copy,
              const SizedBox(height: 18),
              actions,
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCreateBoardSheet(BuildContext context) async {
    final result = await showModalBottomSheet<CreatePlanningBoardInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreatePlanningBoardSheet(),
    );

    if (result != null && context.mounted) {
      onCreateBoard(result);
    }
  }

  Future<void> _copyBoardLink(
    BuildContext context,
    UtilityInstance utility,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: UtilityLink.forUtility(utility.id).toString()),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Board link copied.')),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
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
    final topScore = utility.optionScores.first;
    final bestOverlap = utility.participants.isEmpty
        ? 'No participants yet'
        : '${topScore.votes}/${utility.participants.length} available';

    return AppSurface(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 760;
          final summary = Column(
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
                  _MetricPill(label: 'Created by ${utility.createdBy}'),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: onOpen,
                    child: const Text('Open board'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onCopyLink,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy link'),
                  ),
                ],
              ),
            ],
          );

          final preview = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: AppPalette.surfaceMuted,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AvailabilityBoard(
                  utility: utility,
                  accent: AppPalette.primary,
                  compact: true,
                ),
              ),
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: summary),
                const SizedBox(width: 18),
                Expanded(flex: 4, child: preview),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summary,
              const SizedBox(height: 18),
              preview,
            ],
          );
        },
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
  const _EmptyState({required this.onCreateBoard});

  final VoidCallback onCreateBoard;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No boards yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start with a clean weekly board, then add the places your outing needs once the timing is clear.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppPalette.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreateBoard,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create board'),
          ),
        ],
      ),
    );
  }
}

class _CreatePlanningBoardSheet extends StatefulWidget {
  const _CreatePlanningBoardSheet();

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
    _createdByController = TextEditingController();
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
        const SnackBar(content: Text('Add both a board title and your name.')),
      );
      return;
    }
    if (_endHour <= _startHour) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an end time after the start time.')),
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
              'Create board',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep it simple: title, owner, optional starting participants, and the weekly window.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Board title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _createdByController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Created by'),
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
                    child: const Text('Create board'),
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
    return formatTime(DateTime(2026, 1, 1, hour));
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          borderRadius: BorderRadius.circular(18),
          onChanged: onChanged,
          items: values
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    '$label: ${labelBuilder?.call(item) ?? item}',
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}
