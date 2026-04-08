import 'package:chat_utilities_hub/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the availability-first planner', (tester) async {
    await tester.pumpWidget(const ChatUtilitiesHubApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Plan the event in chat, then open the full board in Flutter.'),
      findsOneWidget,
    );
    expect(find.text('Spring launch dinner'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Preview the iMessage handoff'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Preview the iMessage handoff'), findsOneWidget);
  });

  testWidgets('opens a utility from a launch link', (tester) async {
    await tester.pumpWidget(
      const ChatUtilitiesHubApp(
        initialLink:
            'chatutilitieshub://utility/spring-launch-dinner?kind=availability',
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Availability grid'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Venue vote and checklist'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Spring launch dinner'), findsWidgets);
    expect(find.text('Venue vote and checklist'), findsOneWidget);
  });

  testWidgets('opens a compose draft from a Messages handoff link', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ChatUtilitiesHubApp(
        initialLink:
            'chatutilitieshub://compose?title=Game%20Night&createdBy=Maya&participants=Maya,Jordan,Ari',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create planning board'), findsOneWidget);
    expect(find.text('Game Night'), findsOneWidget);
    expect(find.text('Maya, Jordan, Ari'), findsWidgets);
  });
}
