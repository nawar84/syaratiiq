import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;
import 'package:mobile/src/core/theme/silver_bottom_navigation_bar.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/car_detail_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/widgets/car_studio_card.dart';

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

  Future<void> loginAsBuyer(WidgetTester tester) async {
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
    await tester.enterText(fields.at(0), 'buyer');
    await tester.enterText(fields.at(1), '1234');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    await waitFor(tester, find.text('المفضلة'));
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('buyer sees and can tap call and whatsapp buttons', (tester) async {
    await loginAsBuyer(tester);

    await tester.tap(find.byIcon(Icons.directions_car_filled_outlined));
    await tester.pump(const Duration(seconds: 3));
    await waitFor(tester, find.byType(CarStudioCard));

    await tester.tap(find.byType(CarStudioCard).first);
    await waitFor(tester, find.byType(CarDetailScreen));
    await waitFor(tester, find.text('الماركة'));
    await waitFor(tester, find.text('اتصال'));
    await waitFor(tester, find.text('واتساب'));
    expect(find.byIcon(Icons.phone), findsOneWidget);
    expect(find.byIcon(Icons.chat), findsOneWidget);

    await tester.tap(find.text('اتصال'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('واتساب'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CarDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
