import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_ui_components_example/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'glass quality modes stay usable through scrolling and edge drags',
    (tester) async {
      await tester.pumpWidget(const GlassGallery(animateBackground: false));
      await tester.pumpAndSettle();
      expect(
        ui.ImageFilter.isShaderFilterSupported,
        isTrue,
        reason: 'Run this rendering regression on an Impeller device.',
      );
      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
      final list = find.byType(ListView);
      // Hold past the top edge, then release, exercising the edge-effect path.
      final topDrag = await tester.startGesture(tester.getCenter(list));
      await topDrag.moveBy(const Offset(0, 180));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await topDrag.up();
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('glass-scroll-top');
      for (var i = 0; i < 3; i++) {
        await tester.drag(list, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      final bottomDrag = await tester.startGesture(tester.getCenter(list));
      await bottomDrag.moveBy(const Offset(0, -180));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await bottomDrag.up();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('glass-scroll-bottom');
      await tester.tap(find.text('Balanced'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full refraction').last);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('glass-full-refraction');
      for (var i = 0; i < 3; i++) {
        await tester.drag(list, const Offset(0, 400));
        await tester.pumpAndSettle();
      }
      expect(find.text('Save collection').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('Showing weekly activity'), findsOneWidget);
    },
  );
}
