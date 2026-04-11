import 'package:chat_utilities_hub/src/models/expense_entry.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/app_surface.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:flutter/material.dart';

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

    return AppSurface(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Only use this when the outing has shared costs. Log who paid, split it however you need, and the app will summarize the balances.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppPalette.mutedText,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    action,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only use this when the outing has shared costs. Log who paid, split it however you need, and the app will summarize the balances.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.mutedText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ExpensePill(label: '${utility.expenseCount} entries'),
              _ExpensePill(
                label: '${utility.suggestedSettlements.length} settlements',
              ),
              _ExpensePill(label: _currencyLabel(utility.totalExpenseAmount)),
            ],
          ),
          const SizedBox(height: 18),
          if (utility.expenses.isEmpty)
            Text(
              'No expenses added yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.mutedText),
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
          const SizedBox(height: 18),
          Text(
            'Who owes who',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (utility.suggestedSettlements.isEmpty)
            Text(
              utility.expenses.isEmpty
                  ? 'Add the first expense to see balances.'
                  : 'Everyone is settled up.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.mutedText),
            )
          else
            ...utility.suggestedSettlements.map(
              (settlement) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SettlementRow(settlement: settlement),
              ),
            ),
        ],
      ),
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

class _ExpensePill extends StatelessWidget {
  const _ExpensePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${expense.paidBy} paid ${_currencyLabel(expense.amount)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.text),
              ),
              const SizedBox(height: 2),
              Text(
                'Split with $splitLabel • ${formatTime(expense.addedAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.mutedText),
              ),
              if (expense.note?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 2),
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

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.settlement});

  final ExpenseSettlement settlement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${settlement.fromParticipant} owes ${settlement.toParticipant} ${_currencyLabel(settlement.amount)}',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
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
