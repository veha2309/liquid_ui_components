import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() {
  testWidgets(
    'nearby members fuse across the former six-item boundary in Frosted',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: LiquidGlassBlend.items(
              size: const Size(500, 400),
              settings: const LiquidGlassSettings(
                rendering: LiquidGlassRendering.frosted,
              ),
              items: [
                for (var i = 0; i < 7; i++)
                  LiquidGlassBlendItem(
                    bounds: i == 0
                        ? const Rect.fromLTWH(20, 20, 68, 68)
                        : i == 6
                        ? const Rect.fromLTWH(96, 20, 68, 68)
                        : Rect.fromLTWH(200, 80 + i * 45, 36, 36),
                    borderRadius: 34,
                    child: Text('$i'),
                  ),
              ],
            ),
          ),
        ),
      );
      final surface = tester.widget<LiquidGlassSurface>(
        find.byType(LiquidGlassSurface),
      );
      final outline = surface.shape!.getOuterPath(
        const Rect.fromLTWH(0, 0, 500, 400),
      );
      // The two original circles leave an eight-pixel gap at x=92.
      expect(outline.contains(const Offset(92, 54)), isTrue);
      expect(outline.contains(const Offset(92, 150)), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'items drag within bounds, retain keyed positions and still tap',
    (tester) async {
      var taps = 0;
      Widget host(bool reversed) {
        final items = [
          for (var i = 0; i < 2; i++)
            LiquidGlassBlendItem(
              key: ValueKey(i),
              bounds: Rect.fromLTWH(i * 150.0, 20, 80, 60),
              child: TextButton(
                onPressed: () => taps++,
                child: Text('Member $i'),
              ),
            ),
        ];
        return MaterialApp(
          home: Center(
            child: LiquidGlassBlend.items(
              size: const Size(300, 220),
              items: reversed ? items.reversed.toList() : items,
            ),
          ),
        );
      }

      await tester.pumpWidget(host(false));
      final member = find.text('Member 0');
      final before = tester.getCenter(member);
      await tester.drag(member, const Offset(60, 70));
      await tester.pumpAndSettle();
      final moved = tester.getCenter(member);
      expect(moved.dx, greaterThan(before.dx + 30));
      expect(moved.dy, greaterThan(before.dy + 30));
      await tester.pumpWidget(host(true));
      expect(tester.getCenter(member), moved);
      await tester.tap(member);
      expect(taps, 1);
      await tester.drag(member, const Offset(-2000, -2000));
      await tester.pumpAndSettle();
      expect(tester.getCenter(member).dx, lessThanOrEqualTo(before.dx + 1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('builder accepts more than six arbitrary interactive members', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiquidGlassBlend.builder(
            size: const Size(400, 400),
            itemCount: 13,
            itemBuilder: (context, index) => LiquidGlassBlendItem(
              bounds: Rect.fromLTWH(
                (index % 4) * 90,
                (index ~/ 4) * 90,
                86,
                86,
              ),
              borderRadius: index.isEven ? 43 : 12,
              child: TextButton(
                onPressed: () => taps++,
                child: Text('Action $index'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(TextButton), findsNWidgets(13));
    await tester.tap(find.text('Action 12'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty builder preserves the requested layout size', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: LiquidGlassBlend.builder(
            size: const Size(200, 100),
            itemCount: 0,
            itemBuilder: (_, _) => throw StateError('must not build'),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(
        find.byWidgetPredicate((widget) => widget is LiquidGlassBlend),
      ),
      const Size(200, 100),
    );
  });
}
