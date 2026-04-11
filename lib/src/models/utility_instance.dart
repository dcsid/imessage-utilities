import 'dart:math' as math;

import 'package:chat_utilities_hub/src/models/expense_entry.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/participant_location_share.dart';
import 'package:chat_utilities_hub/src/models/trip_stop.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';

class UtilityInstance {
  const UtilityInstance({
    required this.id,
    required this.title,
    required this.createdBy,
    required this.participants,
    required this.options,
    required this.responses,
    this.expenseTrackingEnabled = false,
    this.expenses = const [],
    this.plannedStops = const [],
    this.locationShares = const [],
    this.closesAt,
  });

  final String id;
  final String title;
  final String createdBy;
  final List<String> participants;
  final List<UtilityOption> options;
  final List<UtilityResponse> responses;
  final bool expenseTrackingEnabled;
  final List<ExpenseEntry> expenses;
  final List<TripStop> plannedStops;
  final List<ParticipantLocationShare> locationShares;
  final DateTime? closesAt;

  int get responseCount => responses.length;

  int get pendingResponseCount => participants.length - responseCount;

  int get stopCount => plannedStops.length;

  int get activeLocationShareCount => resolvedLocationShares.length;

  int get expenseCount => expenses.length;

  double get totalExpenseAmount =>
      expenses.fold(0, (total, expense) => total + expense.amount);

  DateTime? get startsAt {
    DateTime? first;
    for (final option in options) {
      final startAt = option.startAt;
      if (startAt == null) {
        continue;
      }
      if (first == null || startAt.isBefore(first)) {
        first = startAt;
      }
    }
    return first;
  }

  DateTime? get endsAt {
    DateTime? last;
    for (final option in options) {
      final endAt = option.endAt;
      if (endAt == null) {
        continue;
      }
      if (last == null || endAt.isAfter(last)) {
        last = endAt;
      }
    }
    return last;
  }

  UtilityResponse? responseForParticipant(String participantName) {
    for (final response in responses) {
      if (response.participantName == participantName) {
        return response;
      }
    }
    return null;
  }

  TripStop? stopById(String stopId) {
    for (final stop in plannedStops) {
      if (stop.id == stopId) {
        return stop;
      }
    }
    return null;
  }

  ParticipantLocationShare? locationShareForParticipant(
    String participantName,
  ) {
    for (final share in locationShares) {
      if (share.participantName == participantName) {
        return share;
      }
    }
    return null;
  }

  List<ResolvedParticipantLocation> get resolvedLocationShares {
    final resolved = <ResolvedParticipantLocation>[];
    for (final share in locationShares) {
      final stop = stopById(share.stopId);
      if (stop == null) {
        continue;
      }
      resolved.add(ResolvedParticipantLocation(share: share, stop: stop));
    }
    return resolved;
  }

  UtilityInstance copyWith({
    String? id,
    String? title,
    String? createdBy,
    List<String>? participants,
    List<UtilityOption>? options,
    List<UtilityResponse>? responses,
    bool? expenseTrackingEnabled,
    List<ExpenseEntry>? expenses,
    List<TripStop>? plannedStops,
    List<ParticipantLocationShare>? locationShares,
    DateTime? closesAt,
  }) {
    return UtilityInstance(
      id: id ?? this.id,
      title: title ?? this.title,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      options: options ?? this.options,
      responses: responses ?? this.responses,
      expenseTrackingEnabled:
          expenseTrackingEnabled ?? this.expenseTrackingEnabled,
      expenses: expenses ?? this.expenses,
      plannedStops: plannedStops ?? this.plannedStops,
      locationShares: locationShares ?? this.locationShares,
      closesAt: closesAt ?? this.closesAt,
    );
  }

  List<UtilityOptionScore> get optionScores {
    final scores = options
        .map(
          (option) => UtilityOptionScore(
            option: option,
            votes: selectionCountForOption(option.id),
            responders: respondersForOption(option.id),
          ),
        )
        .toList(growable: false);

    scores.sort((left, right) {
      final voteCompare = right.votes.compareTo(left.votes);
      if (voteCompare != 0) {
        return voteCompare;
      }
      return left.option.sortOrder.compareTo(right.option.sortOrder);
    });

    return scores;
  }

  int selectionCountForOption(String optionId) {
    return responses
        .where((response) => response.selectedOptionIds.contains(optionId))
        .length;
  }

  List<String> respondersForOption(String optionId) {
    return responses
        .where((response) => response.selectedOptionIds.contains(optionId))
        .map((response) => response.participantName)
        .toList(growable: false);
  }

  List<ExpenseBalance> get expenseBalances {
    final balancesInCents = <String, int>{};

    void ensureParticipant(String participantName) {
      final normalized = participantName.trim();
      if (normalized.isEmpty) {
        return;
      }
      balancesInCents.putIfAbsent(normalized, () => 0);
    }

    for (final participant in participants) {
      ensureParticipant(participant);
    }

    for (final expense in expenses) {
      ensureParticipant(expense.paidBy);
      for (final participant in expense.splitBetween) {
        ensureParticipant(participant);
      }

      final amountInCents = (expense.amount * 100).round();
      balancesInCents.update(
        expense.paidBy,
        (balance) => balance + amountInCents,
      );

      final splitBetween = expense.splitBetween.isEmpty
          ? <String>[expense.paidBy]
          : expense.splitBetween;
      final baseShare = amountInCents ~/ splitBetween.length;
      final remainder = amountInCents.remainder(splitBetween.length);

      for (var index = 0; index < splitBetween.length; index++) {
        final participantName = splitBetween[index];
        final shareInCents = baseShare + (index < remainder ? 1 : 0);
        balancesInCents.update(
          participantName,
          (balance) => balance - shareInCents,
        );
      }
    }

    final balances = balancesInCents.entries
        .where((entry) => entry.value != 0)
        .map(
          (entry) => ExpenseBalance(
            participantName: entry.key,
            amount: entry.value / 100,
          ),
        )
        .toList(growable: false);

    balances.sort((left, right) => right.amount.compareTo(left.amount));
    return balances;
  }

  List<ExpenseSettlement> get suggestedSettlements {
    final creditors = expenseBalances
        .where((balance) => balance.amount > 0.009)
        .map(
          (balance) => ExpenseBalance(
            participantName: balance.participantName,
            amount: balance.amount,
          ),
        )
        .toList(growable: true);
    final debtors = expenseBalances
        .where((balance) => balance.amount < -0.009)
        .map(
          (balance) => ExpenseBalance(
            participantName: balance.participantName,
            amount: balance.amount,
          ),
        )
        .toList(growable: true);

    final settlements = <ExpenseSettlement>[];
    var creditorIndex = 0;
    var debtorIndex = 0;

    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];
      final amount = math.min(creditor.amount, -debtor.amount);
      if (amount > 0.009) {
        settlements.add(
          ExpenseSettlement(
            fromParticipant: debtor.participantName,
            toParticipant: creditor.participantName,
            amount: double.parse(amount.toStringAsFixed(2)),
          ),
        );
      }

      final remainingCreditor = creditor.amount - amount;
      final remainingDebtor = debtor.amount + amount;
      creditors[creditorIndex] = ExpenseBalance(
        participantName: creditor.participantName,
        amount: remainingCreditor,
      );
      debtors[debtorIndex] = ExpenseBalance(
        participantName: debtor.participantName,
        amount: remainingDebtor,
      );

      if (remainingCreditor.abs() < 0.009) {
        creditorIndex += 1;
      }
      if (remainingDebtor.abs() < 0.009) {
        debtorIndex += 1;
      }
    }

    return settlements;
  }
}

class ResolvedParticipantLocation {
  const ResolvedParticipantLocation({required this.share, required this.stop});

  final ParticipantLocationShare share;
  final TripStop stop;

  String get participantName => share.participantName;

  LocationShareMode get mode => share.mode;

  DateTime get sharedAt => share.sharedAt;

  String? get statusMessage => share.statusMessage;

  bool get isBusy => share.isBusy;
}

class UtilityOptionScore {
  const UtilityOptionScore({
    required this.option,
    required this.votes,
    required this.responders,
  });

  final UtilityOption option;
  final int votes;
  final List<String> responders;

  double coverage(int totalParticipants) {
    if (totalParticipants == 0) {
      return 0;
    }

    return votes / totalParticipants;
  }
}
