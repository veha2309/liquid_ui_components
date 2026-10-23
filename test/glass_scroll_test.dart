import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_glass.dart';
import 'package:liquid_ui_components/src/scrolling/liquid_glass_scroll.dart';

class _PaintProbe extends LeafRenderObjectWidget {
  const _PaintProbe(this.onPaint, {super.key});

  final ValueChanged<Offset> onPaint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPaintProbe(onPaint);
}

class _RenderPaintProbe extends RenderBox {
  _RenderPaintProbe(this.onPaint);

  final ValueChanged<Offset> onPaint;

  @override
  void performLayout() => size = constraints.constrain(const Size(80, 80));

  @override
  void paint(PaintingContext context, Offset offset) {
    onPaint(localToGlobal(Offset.zero));
    context.canvas.drawRect(offset & size, Paint()..color = Colors.blue);
  }
}

void main() {
  testWidgets(
    'retained glass repaints at its new position on the first scroll frame',
    (tester) async {
      final vertical = ScrollController();
      final horizontal = ScrollController();
      addTearDown(vertical.dispose);
      addTearDown(horizontal.dispose);
      Offset? paintedPosition;
      var paints = 0;
      const probeKey = ValueKey('paint-probe');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: vertical,
              children: [
                const SizedBox(height: 200),
                SizedBox(
                  height: 100,
                  child: ListView(
                    controller: horizontal,
                    scrollDirection: Axis.horizontal,
                    children: [
                      const SizedBox(width: 120),
                      ScrollAwareGlass(
                        child: RepaintBoundary(
                          child: _PaintProbe((position) {
                            paintedPosition = position;
                            paints++;
                          }, key: probeKey),
                        ),
                      ),
                      const SizedBox(width: 1000),
                    ],
                  ),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      final firstPaints = paints;
      vertical.jumpTo(75);
      horizontal.jumpTo(30);
      await tester.pump();
      expect(paints, greaterThan(firstPaints));
      expect(paintedPosition, tester.getTopLeft(find.byKey(probeKey)));
      expect(paintedPosition, const Offset(90, 125));
      // Reverse direction without a settling frame: both axes must stay aligned.
      vertical.jumpTo(0);
      horizontal.jumpTo(0);
      await tester.pump();
      expect(paintedPosition, const Offset(120, 200));
      await tester.pumpWidget(const SizedBox());
      // Detached optical subtrees must stop receiving scroll notifications.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('glass scroll behavior avoids stretching at both scroll limits', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const LiquidGlassScrollBehavior(),
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: const [
              LiquidGlassSurface(child: SizedBox(height: 100)),
              SizedBox(height: 1800),
              LiquidGlassSurface(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 250));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(controller.offset, controller.position.maxScrollExtent);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.android}));
}
