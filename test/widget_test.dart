import 'package:chat_utilities_hub/src/app.dart';
import 'package:chat_utilities_hub/src/data/in_memory_utility_repository.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/trip_planning_panel.dart';
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

class _TripPlanningHarness extends StatefulWidget {
  const _TripPlanningHarness({
    required this.repository,
    required this.boardId,
  });

  final InMemoryUtilityRepository repository;
  final String boardId;

  @override
  State<_TripPlanningHarness> createState() => _TripPlanningHarnessState();
}

class _TripPlanningHarnessState extends State<_TripPlanningHarness> {
  late UtilityInstance _utility;

  @override
  void initState() {
    super.initState();
    _utility = widget.repository.getAll().firstWhere(
      (utility) => utility.id == widget.boardId,
    );
  }

  void _refresh() {
    setState(() {
      _utility = widget.repository.getAll().firstWhere(
        (utility) => utility.id == widget.boardId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TripPlanningPanel(
                utility: _utility,
                onAddTripStop: ({
                  required utilityId,
                  required title,
                  required position,
                  String? note,
                }) {
                  widget.repository.addTripStop(
                    utilityId: utilityId,
                    title: title,
                    position: position,
                    note: note,
                  );
                  _refresh();
                },
                onSaveLocationShare: ({
                  required utilityId,
                  required participantName,
                  required mode,
                  required stopId,
                }) {
                  widget.repository.saveLocationShare(
                    utilityId: utilityId,
                    participantName: participantName,
                    mode: mode,
                    stopId: stopId,
                  );
                  _refresh();
                },
                onEndLocationShare: ({
                  required utilityId,
                  required participantName,
                }) {
                  widget.repository.endLocationShare(
                    utilityId: utilityId,
                    participantName: participantName,
                  );
                  _refresh();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
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

  testWidgets('adds a planned place from the trip map', (tester) async {
    final repository = createTestRepository();
    final board = createTestBoard(repository);

    await tester.pumpWidget(
      _TripPlanningHarness(
        repository: repository,
        boardId: board.id,
      ),
    );
    await tester.pumpAndSettle();

    final tripMap = find.byKey(const ValueKey('trip-map-surface'));
    expect(tripMap, findsOneWidget);
    await tester.pumpAndSettle();

    await tester.longPress(tripMap);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Coffee meetup');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save place'));
    await tester.pumpAndSettle();

    expect(find.text('Coffee meetup'), findsOneWidget);
  });
}
