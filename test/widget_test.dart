import 'package:chat_utilities_hub/src/app.dart';
import 'package:chat_utilities_hub/src/data/in_memory_utility_repository.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/screens/utility_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder pageScrollable() => find.byWidgetPredicate(
  (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
);

InMemoryUtilityRepository createTestRepository() {
  final repository = InMemoryUtilityRepository();
  repository.createPlanningBoard(
    CreatePlanningBoardInput(
      title: 'Team dinner',
      createdBy: 'Alex',
      participants: const ['Sam', 'Priya'],
      startDate: DateTime(2026, 4, 13),
      dayCount: 7,
      dayStart: const Duration(hours: 8),
      dayEnd: const Duration(hours: 22),
    ),
  );
  return repository;
}

UtilityInstance createTestBoard(InMemoryUtilityRepository repository) {
  return repository.getAll().first;
}

void main() {
  testWidgets('shows the simplified planner empty state', (tester) async {
    await tester.pumpWidget(const ChatUtilitiesHubApp());
    await tester.pumpAndSettle();

    expect(find.text('Plan Together'), findsOneWidget);
    expect(find.text('No boards yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create board'), findsWidgets);
  });

  testWidgets('opens a utility from a launch link', (tester) async {
    final repository = createTestRepository();
    final board = createTestBoard(repository);

    await tester.pumpWidget(
      ChatUtilitiesHubApp(
        repository: repository,
        initialLink: 'chatutilitieshub://utility/${board.id}',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(UtilityDetailScreen), findsOneWidget);
    expect(find.text(board.title), findsWidgets);
    expect(find.text('Availability board'), findsOneWidget);
  });

  testWidgets('paints and erases availability by dragging across the board', (
    tester,
  ) async {
    final repository = createTestRepository();
    final board = createTestBoard(repository);

    await tester.pumpWidget(
      ChatUtilitiesHubApp(
        repository: repository,
        initialLink: 'chatutilitieshub://utility/${board.id}',
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Fill in availability'),
      300,
      scrollable: pageScrollable().first,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Taylor');
    await tester.pumpAndSettle();

    FilledButton saveButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save availability'),
    );

    expect(find.text('0 blocks selected'), findsOneWidget);
    expect(saveButton().onPressed, isNull);

    final gridFinder = find.byKey(
      const ValueKey('availability-board-grid-selection'),
    );
    await tester.ensureVisible(gridFinder);
    await tester.pumpAndSettle();

    final topLeft = tester.getTopLeft(gridFinder);
    final size = tester.getSize(gridFinder);
    final start = topLeft + Offset(size.width * 0.18, size.height * 0.42);

    final paintGesture = await tester.startGesture(start);
    await paintGesture.moveBy(Offset(size.width * 0.08, 0));
    await tester.pump();
    await paintGesture.moveBy(Offset(size.width * 0.12, 0));
    await tester.pump();
    await paintGesture.up();
    await tester.pumpAndSettle();

    expect(find.text('0 blocks selected'), findsNothing);
    expect(saveButton().onPressed, isNotNull);

    final eraseGesture = await tester.startGesture(start);
    await eraseGesture.moveBy(Offset(size.width * 0.08, 0));
    await tester.pump();
    await eraseGesture.moveBy(Offset(size.width * 0.12, 0));
    await tester.pump();
    await eraseGesture.up();
    await tester.pumpAndSettle();

    expect(find.text('0 blocks selected'), findsOneWidget);
    expect(saveButton().onPressed, isNull);
  });

  testWidgets('vertical drags inside the board keep drawing instead of scrolling the page', (
    tester,
  ) async {
    final repository = createTestRepository();
    final board = createTestBoard(repository);

    await tester.pumpWidget(
      ChatUtilitiesHubApp(
        repository: repository,
        initialLink: 'chatutilitieshub://utility/${board.id}',
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Fill in availability'),
      300,
      scrollable: pageScrollable().first,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Jordan');
    await tester.pumpAndSettle();

    final gridFinder = find.byKey(
      const ValueKey('availability-board-grid-selection'),
    );
    await tester.ensureVisible(gridFinder);
    await tester.pumpAndSettle();

    final pageScrollState = tester.state<ScrollableState>(
      pageScrollable().first,
    );
    final startingOffset = pageScrollState.position.pixels;

    final topLeft = tester.getTopLeft(gridFinder);
    final size = tester.getSize(gridFinder);
    final start = topLeft + Offset(size.width * 0.38, size.height * 0.25);

    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveBy(Offset(0, size.height * 0.08));
    await tester.pump();
    await gesture.moveBy(Offset(0, size.height * 0.12));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final endingOffset = pageScrollState.position.pixels;
    expect((endingOffset - startingOffset).abs(), lessThan(1));
    expect(find.text('0 blocks selected'), findsNothing);
  });
}
