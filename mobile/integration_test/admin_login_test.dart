import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;
import 'package:mobile/src/core/theme/silver_bottom_navigation_bar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 500));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for $finder');
  }

  testWidgets('login as admin', (tester) async {
    app.main();
    await tester.pump();

    await waitFor(
      tester,
      find.byWidgetPredicate(
        (_) =>
            find.text('تسجيل الدخول').evaluate().isNotEmpty ||
            find.byType(SilverBottomNavigationBar).evaluate().isNotEmpty,
      ),
    );

    if (find.byType(SilverBottomNavigationBar).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();
      await waitFor(tester, find.text('تسجيل الدخول'));
    }

    final fields = find.byType(TextFormField);
    expect(fields, findsAtLeast(2));

    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), '1234');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    await waitFor(tester, find.text('الإدارة'));
    expect(find.textContaining('Admin'), findsOneWidget);
  });
}
