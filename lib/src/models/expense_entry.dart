class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    required this.addedAt,
    this.note,
  });

  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> splitBetween;
  final DateTime addedAt;
  final String? note;

  ExpenseEntry copyWith({
    String? id,
    String? title,
    double? amount,
    String? paidBy,
    List<String>? splitBetween,
    DateTime? addedAt,
    String? note,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      splitBetween: splitBetween ?? this.splitBetween,
      addedAt: addedAt ?? this.addedAt,
      note: note ?? this.note,
    );
  }
}

class ExpenseBalance {
  const ExpenseBalance({required this.participantName, required this.amount});

  final String participantName;
  final double amount;
}

class ExpenseSettlement {
  const ExpenseSettlement({
    required this.fromParticipant,
    required this.toParticipant,
    required this.amount,
  });

  final String fromParticipant;
  final String toParticipant;
  final double amount;
}
