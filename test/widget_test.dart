import 'package:chat_utilities_hub/src/app.dart';
import 'package:chat_utilities_hub/src/data/in_memory_utility_repository.dart';
import 'package:chat_utilities_hub/src/data/local_utility_repository.dart';
import 'package:chat_utilities_hub/src/models/create_planning_board_input.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/trip_place_match.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/presentation/trip_planning_panel.dart';
import 'package:chat_utilities_hub/src/screens/utility_detail_screen.dart';
import 'package:chat_utilities_hub/src/services/trip_place_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder pageScrollable() => find.byWidgetPredicate(
  (widget) =>
      widget is Scrollable && widget.axisDirection == AxisDirection.down,
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

class _FakeTripPlaceService extends TripPlaceService {
  const _FakeTripPlaceService();

  @override
  Future<List<TripPlaceMatch>> searchPlaces(
    String query, {
    GeoPoint? near,
  }) async {
    final base = near ?? const GeoPoint(latitude: 38.0336, longitude: -78.5080);
    return <TripPlaceMatch>[
      TripPlaceMatch(
        title: query.trim(),
        subtitle: '123 Test Lane, Charlottesville, VA',
        position: base,
      ),
    ];
  }

  @override
  Future<TripPlaceMatch?> reverseGeocode(GeoPoint point) async {
    return TripPlaceMatch(
      title: 'Pinned place',
      subtitle: '123 Test Lane, Charlottesville, VA',
      position: point,
    );
  }
}

class _TripPlanningHarness extends StatefulWidget {
  const _TripPlanningHarness({required this.repository, required this.boardId});

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
                showLiveMap: false,
                onAddTripStop:
                    ({
                      required utilityId,
                      required title,
                      required position,
                      String? address,
                      String? note,
                    }) {
                      widget.repository.addTripStop(
                        utilityId: utilityId,
                        title: title,
                        position: position,
                        address: address,
                        note: note,
                      );
                      _refresh();
                    },
                onRemoveTripStop: ({required utilityId, required stopId}) {
                  widget.repository.removeTripStop(
                    utilityId: utilityId,
                    stopId: stopId,
                  );
                  _refresh();
                },
                onSaveLocationShare:
                    ({
                      required utilityId,
                      required participantName,
                      required mode,
                      required stopId,
                      String? statusMessage,
                      required bool isBusy,
                    }) {
                      widget.repository.saveLocationShare(
                        utilityId: utilityId,
                        participantName: participantName,
                        mode: mode,
                        stopId: stopId,
                        statusMessage: statusMessage,
                        isBusy: isBusy,
                      );
                      _refresh();
                    },
                onEndLocationShare:
                    ({required utilityId, required participantName}) {
                      widget.repository.endLocationShare(
                        utilityId: utilityId,
                        participantName: participantName,
                      );
                      _refresh();
                    },
                placeService: const _FakeTripPlaceService(),
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

    expect(find.text('Outings'), findsOneWidget);
    expect(find.text('No outings yet'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create outing'), findsWidgets);
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
    expect(find.text('Outing flow'), findsOneWidget);
  });

  testWidgets('keeps create board available after boards exist', (
    tester,
  ) async {
    final repository = createTestRepository();

    await tester.pumpWidget(ChatUtilitiesHubApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'New outing'), findsOneWidget);
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
      find.widgetWithText(FilledButton, 'Save availability'),
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

  testWidgets(
    'vertical drags inside the board keep drawing instead of scrolling the page',
    (tester) async {
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
        find.widgetWithText(FilledButton, 'Save availability'),
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
    },
  );

  testWidgets('adds a planned place from the trip map', (tester) async {
    final repository = createTestRepository();
    final board = createTestBoard(repository);

    await tester.pumpWidget(
      _TripPlanningHarness(repository: repository, boardId: board.id),
    );
    await tester.pumpAndSettle();

    final tripMap = find.byKey(const ValueKey('trip-map-surface'));
    expect(tripMap, findsOneWidget);
    await tester.pumpAndSettle();

    await tester.longPress(tripMap);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save place'));
    await tester.pumpAndSettle();

    expect(repository.getAll().first.plannedStops.single.title, 'Pinned place');
    expect(
      repository.getAll().first.plannedStops.single.address,
      '123 Test Lane, Charlottesville, VA',
    );
  });

  testWidgets('removes a planned place from the trip list', (tester) async {
    final repository = createTestRepository();
    final board = createTestBoard(repository);

    await tester.pumpWidget(
      _TripPlanningHarness(repository: repository, boardId: board.id),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('trip-map-surface')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save place'));
    await tester.pumpAndSettle();

    expect(repository.getAll().first.plannedStops, hasLength(1));

    final deleteButton = find.byIcon(Icons.delete_outline_rounded).first;
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(repository.getAll().first.plannedStops, isEmpty);
    expect(find.text('No places added yet.'), findsOneWidget);
  });

  testWidgets('shows status and expand controls in trip planning', (
    tester,
  ) async {
    final repository = createTestRepository();
    final board = createTestBoard(repository);

    await tester.pumpWidget(
      _TripPlanningHarness(repository: repository, boardId: board.id),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Status message'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Busy'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
  });

  test('stores busy state and status message for a location share', () {
    final repository = createTestRepository();
    final board = createTestBoard(repository);
    final updatedBoard = repository.addTripStop(
      utilityId: board.id,
      title: 'Aquatic and Fitness Center',
      address: '450 Whitehead Rd, Charlottesville, VA',
      position: const GeoPoint(latitude: 38.0346, longitude: -78.5102),
    );

    final savedBoard = repository.saveLocationShare(
      utilityId: updatedBoard.id,
      participantName: 'Alex',
      mode: LocationShareMode.live,
      stopId: updatedBoard.plannedStops.first.id,
      statusMessage: 'Parking on the side lot',
      isBusy: true,
    );

    final share = savedBoard.locationShares.single;
    expect(share.statusMessage, 'Parking on the side lot');
    expect(share.isBusy, isTrue);
  });

  test('expense tracking stays optional and computes settlements', () {
    final repository = createTestRepository();
    final board = createTestBoard(repository);

    final enabledBoard = repository.enableExpenseTracking(utilityId: board.id);
    expect(enabledBoard.expenseTrackingEnabled, isTrue);
    expect(enabledBoard.expenses, isEmpty);

    final withExpense = repository.addExpense(
      utilityId: enabledBoard.id,
      title: 'Dinner',
      amount: 60,
      paidBy: 'Alex',
      splitBetween: const ['Alex', 'Sam', 'Priya'],
    );

    expect(withExpense.expenseCount, 1);
    expect(withExpense.suggestedSettlements, isNotEmpty);
  });

  test('persists outings for the signed-in user', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    final firstRepository = LocalUtilityRepository(preferences: preferences);
    await firstRepository.hydrateForUser('siddus@example.com');
    firstRepository.createPlanningBoard(
      CreatePlanningBoardInput(
        title: 'Saved outing',
        createdBy: 'Sid',
        participants: const ['Alex'],
        startDate: DateTime(2026, 4, 13),
        dayCount: 3,
        dayStart: const Duration(hours: 9),
        dayEnd: const Duration(hours: 18),
      ),
    );

    await Future<void>.delayed(Duration.zero);

    final secondRepository = LocalUtilityRepository(preferences: preferences);
    await secondRepository.hydrateForUser('siddus@example.com');

    expect(secondRepository.getAll(), hasLength(1));
    expect(secondRepository.getAll().single.title, 'Saved outing');
  });
}
