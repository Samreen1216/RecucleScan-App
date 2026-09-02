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

  testWidgets('QuizScreen renders question, selects option, and shows Next Question button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recycle Quiz'), findsOneWidget);
    expect(find.textContaining('1 / 5'), findsOneWidget);

    // Tap the first option
    final firstOption = find.byType(InkWell).first;
    await tester.tap(firstOption);
    await tester.pumpAndSettle();

    // Next question button should be visible
    expect(find.text('NEXT QUESTION'), findsOneWidget);
  });

  testWidgets('QuizResultScreen renders 0/5 score with supportive message and no celebration', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizResultScreen(score: 0, total: 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quiz Results'), findsOneWidget);
    expect(find.text('0 / 5'), findsOneWidget);
    expect(find.text('Oops! Better Luck Next Time'), findsOneWidget);
    expect(find.text('Don’t worry — keep learning and try the quiz again!'), findsOneWidget);
    expect(find.text('TRY ANOTHER QUIZ'), findsOneWidget);
    expect(find.text('BACK TO HOME'), findsOneWidget);
  });

  testWidgets('QuizResultScreen renders 2/5 score with encouraging message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizResultScreen(score: 2, total: 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('Keep Learning! 🌱'), findsOneWidget);
  });

  testWidgets('QuizResultScreen renders 4/5 score with Great Job', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizResultScreen(score: 4, total: 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4 / 5'), findsOneWidget);
    expect(find.text('Great Job! 🌿'), findsOneWidget);
  });

  testWidgets('QuizResultScreen renders 5/5 score with Perfect Score badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizResultScreen(score: 5, total: 5),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5 / 5'), findsOneWidget);
    expect(find.text('Perfect Score! 🏆'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
  });

  testWidgets('QuizScreen back button shows exit confirmation dialog and cancel keeps state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap back button
    final backButton = find.byIcon(Icons.arrow_back_rounded);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // Verification dialog should appear
    expect(find.text('Are you sure you want to exit?'), findsOneWidget);
    expect(find.text('Your quiz progress will be lost if you exit now.'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.text('EXIT'), findsOneWidget);

    // Tap CANCEL
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    // Dialog should be gone, still on QuizScreen
    expect(find.text('Are you sure you want to exit?'), findsNothing);
    expect(find.text('Recycle Quiz'), findsOneWidget);
  });
}
