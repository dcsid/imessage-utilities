import 'package:chat_utilities_hub/src/models/expense_entry.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:flutter/material.dart';

const _tabularNumerals = [FontFeature.tabularFigures()];

class ExpenseTrackingPanel extends StatelessWidget {
  const ExpenseTrackingPanel({
    super.key,
    required this.utility,
    required this.onEnableExpenseTracking,
    required this.onAddExpense,
    required this.onRemoveExpense,
  });

  final UtilityInstance utility;
  final void Function({required String utilityId}) onEnableExpenseTracking;
  final void Function({
    required String utilityId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> splitBetween,
    String? note,
  })
  onAddExpense;
  final void Function({required String utilityId, required String expenseId})
  onRemoveExpense;

  @override
  Widget build(BuildContext context) {
    if (!utility.expenseTrackingEnabled) {
      return AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optional: expense tracking',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Turn this on only if the outing needs shared costs. Once enabled, the group can log payments and quickly see who owes whom.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onEnableExpenseTracking(utilityId: utility.id),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Add expense tracking'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 640;
                  final action = FilledButton.icon(
                    onPressed: () => _showAddExpenseSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add expense'),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _ExpenseHeading(utility: utility)),
                        const SizedBox(width: 16),
                        action,
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExpenseHeading(utility: utility),
                      const SizedBox(height: 16),
                      action,
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              if (utility.expenses.isEmpty)
                Text(
                  'No expenses added yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.mutedText,
                  ),
                )
              else
                ...utility.expenses.map(
                  (expense) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExpenseRow(
                      expense: expense,
                      onRemove: () {
                        onRemoveExpense(
                          utilityId: utility.id,
                          expenseId: expense.id,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettleUpCard(utility: utility),
      ],
    );
  }

  Future<void> _showAddExpenseSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_AddExpenseResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddExpenseSheet(utility: utility),
    );

    if (result == null || !context.mounted) {
      return;
    }

    onAddExpense(
      utilityId: utility.id,
      title: result.title,
      amount: result.amount,
      paidBy: result.paidBy,
      splitBetween: result.splitBetween,
      note: result.note,
    );
  }
}

class _ExpenseHeading extends StatelessWidget {
  const _ExpenseHeading({required this.utility});

  final UtilityInstance utility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _currencyLabel(utility.totalExpenseAmount),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: _tabularNumerals,
                color: AppPalette.ink,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'across ${utility.expenseCount} ${utility.expenseCount == 1 ? 'entry' : 'entries'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.mutedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Log who paid, split it however you need. Balances update live below.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppPalette.mutedText,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// Splitwise-style settle-up: per-person net balances at the top, then a
/// simplified list of payments to make. All numbers are tabular so they
/// line up cleanly.
class _SettleUpCard extends StatelessWidget {
  const _SettleUpCard({required this.utility});

  final UtilityInstance utility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppPalette.accentFor(utility.id);
    final balances = utility.expenseBalances
        .where((b) => b.amount.abs() > 0.005)
        .toList(growable: false);
    final settlements = utility.suggestedSettlements;

    return AppSurface(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Settle up',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
                ),
              ),
              const Spacer(),
              if (settlements.isNotEmpty)
                _SettlementCountChip(count: settlements.length),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            settlements.isEmpty
                ? (utility.expenses.isEmpty
                      ? 'Add the first expense to see balances.'
                      : 'Everyone is even — no payments needed.')
                : 'The fewest payments to balance everyone out.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
              height: 1.45,
            ),
          ),
          if (balances.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BalanceStrip(balances: balances),
          ],
          if (settlements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppPalette.borderSoft),
            const SizedBox(height: 16),
            for (var i = 0; i < settlements.length; i++) ...[
              _SettlementRow(settlement: settlements[i]),
              if (i < settlements.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _SettlementCountChip extends StatelessWidget {
  const _SettlementCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count == 1 ? '1 payment' : '$count payments',
        style: const TextStyle(
          color: AppPalette.canvas,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({required this.balances});

  final List<ExpenseBalance> balances;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < balances.length; i++) ...[
            _BalanceCell(balance: balances[i]),
            if (i < balances.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _BalanceCell extends StatelessWidget {
  const _BalanceCell({required this.balance});

  final ExpenseBalance balance;

  @override
  Widget build(BuildContext context) {
    final isCreditor = balance.amount > 0;
    final fill = isCreditor ? AppPalette.successSoft : AppPalette.warningSoft;
    final ink = isCreditor ? AppPalette.success : AppPalette.warning;
    final sign = isCreditor ? '+' : '−';
    final amountLabel =
        '$sign\$${balance.amount.abs().toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ink.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ParticipantAvatar(name: balance.participantName, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                balance.participantName,
                style: const TextStyle(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amountLabel,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFeatures: _tabularNumerals,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.settlement});

  final ExpenseSettlement settlement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ParticipantAvatar(name: settlement.fromParticipant, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settlement.fromParticipant,
                style: const TextStyle(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                'pays ${settlement.toParticipant}',
                style: const TextStyle(
                  color: AppPalette.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.east_rounded,
            color: AppPalette.faintText,
            size: 18,
          ),
        ),
        _ParticipantAvatar(name: settlement.toParticipant, size: 36),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.ink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '\$${settlement.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppPalette.canvas,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: _tabularNumerals,
            ),
          ),
        ),
      ],
    );
  }
}

/// Round, colored circle showing the participant's first initial. The
/// hue is derived from the name so the same person reads as the same
/// "color" everywhere they appear.
class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({required this.name, this.size = 32});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = AppPalette.accentFor(name);
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.base,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.border, width: 1.4),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.onRemove});

  final ExpenseEntry expense;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final splitLabel = expense.splitBetween.join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ParticipantAvatar(name: expense.paidBy, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expense.title,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    _currencyLabel(expense.amount),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: _tabularNumerals,
                      color: AppPalette.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${expense.paidBy} paid • split with $splitLabel',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
              ),
              const SizedBox(height: 2),
              Text(
                formatTime(expense.addedAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.faintText),
              ),
              if (expense.note?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  expense.note!.trim(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: onRemove,
          tooltip: 'Remove expense',
          icon: const Icon(Icons.delete_outline_rounded),
          color: AppPalette.mutedText,
        ),
      ],
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({required this.utility});

  final UtilityInstance utility;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _paidByController;
  late final TextEditingController _splitBetweenController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _paidByController = TextEditingController(text: widget.utility.createdBy);
    _splitBetweenController = TextEditingController(
      text: widget.utility.participants.join(', '),
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _paidByController.dispose();
    _splitBetweenController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final paidBy = _paidByController.text.trim();
    final splitBetween = _splitBetweenController.text
        .split(',')
        .map((participant) => participant.trim())
        .where((participant) => participant.isNotEmpty)
        .toList(growable: false);

    if (title.isEmpty || amount == null || amount <= 0 || paidBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a title, payer, and amount greater than zero.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _AddExpenseResult(
        title: title,
        amount: amount,
        paidBy: paidBy,
        splitBetween: splitBetween.isEmpty ? <String>[paidBy] : splitBetween,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
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
              'Add expense',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Log the payment once, then let the app work out who owes whom.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.mutedText),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Expense name',
                hintText: 'Dinner, parking, tickets...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paidByController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Paid by'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _splitBetweenController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Split with',
                hintText: 'Alex, Sam, Priya',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
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
                    child: const Text('Add expense'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExpenseResult {
  const _AddExpenseResult({
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    this.note,
  });

  final String title;
  final double amount;
  final String paidBy;
  final List<String> splitBetween;
  final String? note;
}

String _currencyLabel(double amount) => '\$${amount.toStringAsFixed(2)}';
