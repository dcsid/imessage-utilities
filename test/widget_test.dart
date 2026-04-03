import 'package:chat_utilities_hub/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the availability-first utility hub', (tester) async {
    await tester.pumpWidget(const ChatUtilitiesHubApp());
    await tester.pumpAndSettle();

    expect(find.text('Messages-first utility hub'), findsOneWidget);
    expect(find.text('Design sprint sync'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Try a share link'), findsOneWidget);
  });

  testWidgets('opens a utility from a launch link', (tester) async {
    await tester.pumpWidget(
      const ChatUtilitiesHubApp(
        initialLink:
            'chatutilitieshub://utility/design-sprint-sync?kind=availability',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Best overlap'), findsOneWidget);
    expect(find.text('Design sprint sync'), findsWidgets);
    expect(
      find.textContaining('chatutilitieshub://utility/design-sprint-sync'),
      findsOneWidget,
    );
  });
}
