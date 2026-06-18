import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;
import 'package:mobile/src/core/theme/silver_bottom_navigation_bar.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/car_detail_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/widgets/car_image_gallery.dart';
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

  Future<void> ensureLoggedIn(WidgetTester tester) async {
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

    if (find.text('تسجيل الدخول').evaluate().isNotEmpty) {
      final fields = find.byType(TextFormField);
      expect(fields, findsAtLeast(2));

      await tester.enterText(fields.at(0), 'buyer');
      await tester.enterText(fields.at(1), '1234');
      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();
    }

    await waitFor(tester, find.byType(SilverBottomNavigationBar));
  }

  testWidgets('restart app, open car details, tap image to zoom', (tester) async {
    await ensureLoggedIn(tester);

    await tester.tap(find.byIcon(Icons.directions_car_filled_outlined));
    await tester.pump(const Duration(milliseconds: 500));
    await waitFor(tester, find.byType(CarStudioCard));

    await tester.tap(find.byType(CarStudioCard).first);
    await waitFor(tester, find.byType(CarDetailScreen));
    await waitFor(tester, find.text('اضغط للتكبير'));

    final galleryTap = find.descendant(
      of: find.byType(CarImageGallery),
      matching: find.byType(GestureDetector),
    );
    expect(galleryTap, findsWidgets);

    await tester.tap(galleryTap.first);
    await tester.pump(const Duration(milliseconds: 500));
    await waitFor(tester, find.byType(CarImageViewerScreen));

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byTooltip('إغلاق'), findsOneWidget);
  });
}
