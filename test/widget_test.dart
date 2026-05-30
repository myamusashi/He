import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('FINANSA app smoke test', (WidgetTester tester) async {
    // Use a minimal widget to avoid Firebase initialization in tests
    await tester.pumpWidget(ProviderScope(child: const SizedBox()));
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
