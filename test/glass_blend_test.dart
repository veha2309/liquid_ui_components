import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_glass.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/blending_demo.dart';

void main() {
  testWidgets(
    'demo inherits blur and opacity while viscosity changes independently',
    (tester) async {
      Widget host(double blur, double opacity) => MaterialApp(
        home: Scaffold(
          body: LiquidGlassTheme(
            settings: LiquidGlassSettings(
              blur: blur,
              opacity: opacity,
              rendering: LiquidGlassRendering.frosted,
            ),
            child: const BlendingDemo(),
          ),
        ),
      );
      await tester.pumpWidget(host(3, 0.12));
      await tester.pumpAndSettle();
      LiquidGlassBlend blend() => tester
          .widgetList<LiquidGlassBlend>(find.byType(LiquidGlassBlend))
          .firstWhere((b) => b.playgroundSize != null);
      expect(blend().settings!.blur, 3);
      expect(blend().settings!.opacity, 0.12);
      final drag = find.byKey(const ValueKey('blend-drag-0'));
      await tester.drag(drag, const Offset(25, 25));
      await tester.pumpAndSettle();
      final position = tester.getCenter(drag);
      tester.widget<Slider>(find.byType(Slider)).onChanged!(0.9);
      await tester.pumpAndSettle();
      expect(blend().viscosity, 0.9);
      expect(blend().settings!.blur, 3);
      await tester.pumpWidget(host(12, 0.7));
      await tester.pumpAndSettle();
      expect(blend().settings!.blur, 12);
      expect(blend().settings!.opacity, 0.7);
      expect((tester.getCenter(drag) - position).distance, lessThan(0.1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('separated drops keep their diameter and do not form a neck', (
    tester,
  ) async {
    for (final distance in [112.0, 140.0, 190.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiquidGlassBlend(
                separation: distance,
                settings: const LiquidGlassSettings(
                  rendering: LiquidGlassRendering.frosted,
                ),
                first: const Icon(Icons.pause),
                second: const Icon(Icons.music_note),
              ),
            ),
          ),
        ),
      );
      final surface = tester.widget<LiquidGlassSurface>(
        find.byType(LiquidGlassSurface),
      );
      final path = surface.shape!.getOuterPath(
        Rect.fromLTWH(0, 0, distance + 96, 96),
      );
      final drops = path.computeMetrics().toList();
      expect(drops.length, 2);
      for (final drop in drops) {
        expect(
          drop.extractPath(0, drop.length).getBounds().height,
          closeTo(96, 0.1),
        );
      }
      expect(path.contains(Offset(48 + distance / 2, 48)), isFalse);
    }
  });

  testWidgets('both lenses drag freely, stay bounded and retain taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LiquidGlassBlend.draggable(
              size: const Size(320, 240),
              first: IconButton(
                onPressed: () => taps++,
                icon: const Icon(Icons.pause),
              ),
              second: const Icon(Icons.music_note),
            ),
          ),
        ),
      ),
    );
    final first = find.byKey(const ValueKey('blend-drag-0'));
    final second = find.byKey(const ValueKey('blend-drag-1'));
    final start = tester.getCenter(first);
    final other = tester.getCenter(second);
    await tester.drag(first, const Offset(32, 40));
    await tester.pumpAndSettle();
    expect(tester.getCenter(first).dx, greaterThan(start.dx + 15));
    expect(tester.getCenter(first).dy, greaterThan(start.dy + 20));
    expect((tester.getCenter(second) - other).distance, lessThan(0.1));
    final secondStart = tester.getCenter(second);
    await tester.drag(second, const Offset(-25, -30));
    await tester.pumpAndSettle();
    expect(tester.getCenter(second).dy, lessThan(secondStart.dy - 10));
    await tester.tap(find.byIcon(Icons.pause));
    expect(taps, 1);
    final arena = tester.getRect(find.byType(LiquidGlassBlend).first);
    await tester.drag(first, const Offset(-1000, -1000));
    await tester.pumpAndSettle();
    expect(arena.contains(tester.getCenter(first)), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blend fuses, separates, and preserves control actions', (
    tester,
  ) async {
    var presses = 0;
    Widget host(double separation, {bool solid = false}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: LiquidGlassBlend(
            separation: separation,
            settings: LiquidGlassSettings(
              rendering: LiquidGlassRendering.frosted,
              reduceTransparency: solid,
            ),
            first: IconButton(
              onPressed: () => presses++,
              tooltip: 'Pause',
              icon: const Icon(Icons.pause),
            ),
            second: const Icon(Icons.music_note),
          ),
        ),
      ),
    );
    Path outline() {
      final surface = tester.widget<LiquidGlassSurface>(
        find.byType(LiquidGlassSurface),
      );
      return surface.shape!.getOuterPath(
        Offset.zero & tester.getSize(find.byType(LiquidGlassBlend)),
      );
    }

    await tester.pumpWidget(host(96));
    await tester.pumpAndSettle();
    expect(outline().computeMetrics().length, 1);
    await tester.tap(find.byTooltip('Pause'));
    expect(presses, 1);
    await tester.pumpWidget(host(160));
    await tester.pumpAndSettle();
    expect(outline().computeMetrics().length, 2);
    await tester.pumpWidget(host(96, solid: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pause'));
    expect(presses, 2);
    expect(tester.takeException(), isNull);
  });
}
