import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('thumb matches controlled endpoints and drag in $direction', (
      tester,
    ) async {
      var value = 0.5;
      var starts = 0;
      var ends = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: StatefulBuilder(
                    builder: (context, update) => LiquidGlassSlider(
                      value: value,
                      onChanged: (next) => update(() => value = next),
                      onChangeStart: (_) => starts++,
                      onChangeEnd: (_) => ends++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final slider = find.byType(LiquidGlassSlider);
      final thumb = find.byKey(const ValueKey('glass-slider-thumb'));
      final rect = tester.getRect(slider);
      expect(tester.getCenter(thumb).dx, rect.center.dx);
      final gesture = await tester.startGesture(tester.getCenter(thumb));
      await gesture.moveTo(Offset(rect.right + 50, rect.center.dy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getCenter(thumb).dx, closeTo(rect.right - 32, 0.1));
      expect(value, direction == TextDirection.ltr ? 1 : 0);
      expect(tester.getRect(thumb).right, lessThanOrEqualTo(rect.right));
      await gesture.moveTo(Offset(rect.left - 50, rect.center.dy));
      await tester.pump();
      expect(value, direction == TextDirection.ltr ? 0 : 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getCenter(thumb).dx, closeTo(rect.left + 32, 0.1));
      expect(starts, 1);
      expect(ends, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('disabled slider ignores input and supports narrow bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 90,
              child: LiquidGlassSlider(
                value: 0.4,
                onChanged: null,
                thumbIcon: Icons.volume_up,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(LiquidGlassSlider), const Offset(50, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 0.4);
    expect(tester.takeException(), isNull);
  });
}
