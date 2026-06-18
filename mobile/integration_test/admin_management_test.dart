import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;
import 'package:mobile/src/core/theme/silver_bottom_navigation_bar.dart';
import 'package:mobile/src/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mobile/src/features/admin/presentation/screens/admin_management_screen.dart';

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

  Future<void> loginAsAdmin(WidgetTester tester) async {
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
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), '1234');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    await waitFor(tester, find.text('الإدارة'));
  }

  testWidgets('admin management tabs and dashboard load', (tester) async {
    await loginAsAdmin(tester);

    await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await waitFor(tester, find.text('إدارة المنصة'));

    await waitFor(tester, find.text('المستخدمون'));
    Finder tab(String label) => find.descendant(
          of: find.byType(TabBar),
          matching: find.text(label),
        );

    await waitFor(tester, find.textContaining('Demo'));

    await tester.tap(tab('المعارض'));
    await tester.pump(const Duration(seconds: 3));
    await waitFor(tester, find.byType(ListTile));

    await tester.tap(tab('السيارات'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(ListTile), findsWidgets);

    await tester.tap(tab('الاشتراكات'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(ListTile), findsWidgets);

    await tester.tap(tab('الإيرادات'));
    await tester.pump(const Duration(seconds: 3));
    await waitFor(tester, find.textContaining('إجمالي الإيرادات'));

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.analytics_outlined),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await waitFor(tester, find.text('لوحة تحكم الإدارة'));
    await waitFor(tester, find.text('إجمالي السيارات'));
    await waitFor(tester, find.text('السيارات لكل محافظة'));
    await waitFor(tester, find.text('المعارض لكل محافظة'));
  });
}
