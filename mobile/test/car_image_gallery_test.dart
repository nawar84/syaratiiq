import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/src/features/marketplace/presentation/widgets/car_image_gallery.dart';

void main() {
  const sampleUrls = [
    'https://picsum.photos/seed/car1/800/600',
    'https://picsum.photos/seed/car2/800/600',
    'https://picsum.photos/seed/car3/800/600',
  ];

  Future<void> pumpGallery(WidgetTester tester, {List<String> urls = sampleUrls}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CarImageGallery(imageUrls: urls),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows zoom hint and image counter', (tester) async {
    await pumpGallery(tester);

    expect(find.text('اضغط للتكبير'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.byIcon(Icons.zoom_in), findsOneWidget);
  });

  testWidgets('tap on image opens fullscreen viewer', (tester) async {
    await pumpGallery(tester);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CarImageViewerScreen), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('viewer opens at selected image index', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () => CarImageViewerScreen.open(
                  context,
                  imageUrls: sampleUrls,
                  initialIndex: 2,
                ),
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('pinch zoom disables page scroll while zoomed', (tester) async {
    await pumpGallery(tester);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    viewer.transformationController!.value = Matrix4.diagonal3Values(2.5, 2.5, 1);
    await tester.pump();

    final pageView = tester.widget<PageView>(
      find.descendant(
        of: find.byType(CarImageViewerScreen),
        matching: find.byType(PageView),
      ),
    );
    expect(pageView.physics, isA<NeverScrollableScrollPhysics>());
  });

  testWidgets('closing viewer returns to car gallery', (tester) async {
    await pumpGallery(tester);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CarImageViewerScreen), findsOneWidget);

    final closeButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(CarImageViewerScreen),
        matching: find.byType(IconButton),
      ),
    );
    closeButton.onPressed?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CarImageViewerScreen), findsNothing);
    expect(find.text('اضغط للتكبير'), findsOneWidget);
  });

  testWidgets('single image hides counter badge on preview', (tester) async {
    await pumpGallery(tester, urls: [sampleUrls.first]);

    expect(find.text('1/1'), findsNothing);
    expect(find.text('اضغط للتكبير'), findsOneWidget);
  });
}
