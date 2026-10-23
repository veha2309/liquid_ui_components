import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() {
  testWidgets(
    'scrolling from a held switch clears its lens before pointer up',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: [
                const SizedBox(height: 200),
                Center(
                  child: LiquidGlassSwitch(
                    value: false,
                    onChanged: (_) => changes++,
                    semanticLabel: 'Scroll test toggle',
                    settings: const LiquidGlassSettings(
                      rendering: LiquidGlassRendering.frosted,
                    ),
                  ),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      final thumb = find.byKey(const ValueKey('glass-switch-thumb'));
      final gesture = await tester.startGesture(tester.getCenter(thumb));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getSize(thumb).width, 32);
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -50));
      await tester.pump(const Duration(milliseconds: 250));
      expect(controller.offset, greaterThan(0));
      expect(tester.getSize(thumb).width, 24);
      expect(
        tester.widget<LiquidGlassSurface>(thumb).settings!.rendering,
        LiquidGlassRendering.frosted,
      );
      expect(changes, 0);
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LiquidGlassSwitch));
      await tester.pumpAndSettle();
      expect(changes, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
