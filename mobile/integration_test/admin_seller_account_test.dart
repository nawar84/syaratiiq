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
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 500));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for $finder');
  }

  Finder adminTab(String label) => find.descendant(
        of: find.byType(TabBar),
        matching: find.text(label),
      );

  Future<void> tapAdminTab(WidgetTester tester, String label) async {
    final finder = adminTab(label);
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.ensureVisible(finder);
      await tester.pump(const Duration(milliseconds: 200));
      try {
        final rect = tester.getRect(finder);
        final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
        if (rect.center.dx >= 0 && rect.center.dx <= screenWidth) {
          await tester.tap(finder, warnIfMissed: false);
          await tester.pump();
          return;
        }
      } catch (_) {}
      await tester.drag(find.byType(TabBar), const Offset(-120, 0));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
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

  Future<void> openAdminManagement(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await waitFor(tester, find.text('إدارة المنصة'));
  }

  testWidgets('admin subscriptions tab loads', (tester) async {
    await loginAsAdmin(tester);
    await openAdminManagement(tester);

    await tapAdminTab(tester, 'الاشتراكات');
    await tester.pump(const Duration(seconds: 3));

    await waitFor(tester, find.byType(ListTile));
    expect(find.byType(ListTile), findsWidgets);
  });

  testWidgets('admin can generate seller account from seller accounts tab', (tester) async {
    await loginAsAdmin(tester);
    await openAdminManagement(tester);

    await tapAdminTab(tester, 'حسابات البائعين');
    await tester.pump(const Duration(seconds: 2));
    await waitFor(tester, find.text('إنشاء حساب بائع'));

    await tester.tap(find.text('إنشاء حساب بائع'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await waitFor(tester, find.text('إنشاء حساب بائع', skipOffstage: false));

    final uniquePhone = '078${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final formFields = find.byType(TextFormField);

    await tester.enterText(formFields.at(0), 'معرض اختبار ${DateTime.now().second}');
    await tester.enterText(formFields.at(1), 'مالك اختبار');
    await tester.enterText(formFields.at(2), uniquePhone);
    await tester.pump();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownMenuItem<int>).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('إنشاء حساب البائع'));
    await tester.tap(find.text('إنشاء حساب البائع'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));

    await waitFor(tester, find.text('تم إنشاء حساب البائع'));
    expect(find.textContaining('اسم المستخدم'), findsOneWidget);
    expect(find.textContaining('كلمة المرور'), findsOneWidget);
    expect(find.text('نسخ بيانات الدخول'), findsOneWidget);

    await tester.tap(find.text('تم'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await waitFor(tester, find.textContaining('showroom_'));
    expect(find.textContaining('معرض اختبار'), findsWidgets);
  });
}
