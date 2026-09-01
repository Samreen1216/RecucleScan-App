import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recyclescan/features/result/result_screen.dart';

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
}
