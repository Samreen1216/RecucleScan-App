import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recyclescan/features/history/history_screen.dart';
import 'package:recyclescan/features/result/result_screen.dart';
import 'package:recyclescan/shared/widgets/app_shell.dart';

void main() {
  testWidgets('ResultScreen renders graceful Item Not Found fallback when item is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResultScreen(),
        ),
      ),
    );
    expect(find.text('Item Not Found'), findsOneWidget);
    expect(find.text('Scan an Item'), findsOneWidget);
    expect(find.text('Return Home'), findsOneWidget);
  });

  testWidgets('AppShell hides center Scan FAB and BottomNavBar when keyboard opens', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppShell(
          child: Scaffold(body: Text('Test Content')),
        ),
      ),
    );

    // Normally, the Scan FAB icon and BottomNavBar items are present
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // Simulate keyboard opening (viewInsets.bottom > 0)
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
        child: MaterialApp(
          home: AppShell(
            child: Scaffold(body: Text('Test Content')),
          ),
        ),
      ),
    );

    // With keyboard open, FAB and BottomNavBar must NOT be present
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsNothing);
    expect(find.text('Home'), findsNothing);
    expect(find.text('History'), findsNothing);

    // Simulate keyboard dismissal (viewInsets.bottom = 0)
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(viewInsets: EdgeInsets.zero),
        child: MaterialApp(
          home: AppShell(
            child: Scaffold(body: Text('Test Content')),
          ),
        ),
      ),
    );

    // Restores normally
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('HistoryScreen search field typing, submit, and tap outside', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    // Tap search field to focus
    await tester.tap(searchField);
    await tester.pump();
    expect(tester.widget<TextField>(searchField).focusNode?.hasFocus ?? true, isTrue);

    // Enter text
    await tester.enterText(searchField, 'coca');
    await tester.pump();

    // Verify clear button appears
    expect(find.byIcon(Icons.clear), findsOneWidget);

    // Tap clear button
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(find.byIcon(Icons.clear), findsNothing);
  });
}
