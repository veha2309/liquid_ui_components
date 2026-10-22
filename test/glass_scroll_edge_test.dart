import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

const blue = Color(0xff0000ff);
const captureKey = ValueKey('edge-capture');

Widget scene(
  ScrollController controller, {
  bool reverse = false,
  double contentHeight = 1000,
  double opacity = 1,
  LiquidGlassScrollEdgeStyle style = LiquidGlassScrollEdgeStyle.soft,
  Widget? child,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: RepaintBoundary(
        key: captureKey,
        child: SizedBox(
          width: 200,
          height: 200,
          child: ColoredBox(
            color: blue,
            child: LiquidGlassScrollEdge(
              topExtent: 48,
              bottomExtent: 48,
              color: Colors.white,
              opacity: opacity,
              style: style,
              child:
                  child ??
                  ListView(
                    controller: controller,
                    reverse: reverse,
                    padding: EdgeInsets.zero,
                    children: [SizedBox(height: contentHeight)],
                  ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<int> redAt(WidgetTester tester, int y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(captureKey),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final red = bytes.getUint8((y * image.width + 100) * 4);
    image.dispose();
    return red;
  }))!;
}

void main() {
  testWidgets('edges follow content boundaries and leave the center clear', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(scene(controller));
    await tester.pumpAndSettle();
    expect(await redAt(tester, 1), 0);
    expect(await redAt(tester, 198), greaterThan(240));
    expect(await redAt(tester, 100), 0);
    controller.jumpTo(16);
    await tester.pump();
    final partial = await redAt(tester, 1);
    expect(partial, inInclusiveRange(115, 135));
    controller.jumpTo(64);
    await tester.pump();
    expect(await redAt(tester, 1), greaterThan(240));
    expect(await redAt(tester, 198), greaterThan(240));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(await redAt(tester, 198), 0);
    expect(await redAt(tester, 1), greaterThan(240));
  });

  testWidgets('reverse lists map their boundaries to the physical edges', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(scene(controller, reverse: true));
    await tester.pumpAndSettle();
    expect(await redAt(tester, 1), greaterThan(240));
    expect(await redAt(tester, 198), 0);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(await redAt(tester, 1), 0);
    expect(await redAt(tester, 198), greaterThan(240));
  });

  testWidgets(
    'short content and content resizing clear unnecessary edge paint',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(scene(controller));
      await tester.pumpAndSettle();
      expect(await redAt(tester, 198), greaterThan(240));
      await tester.pumpWidget(scene(controller, contentHeight: 100));
      await tester.pumpAndSettle();
      expect(await redAt(tester, 1), 0);
      expect(await redAt(tester, 198), 0);
    },
  );

  testWidgets('parent rebuilds preserve the current edge state', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(scene(controller));
    await tester.pumpAndSettle();
    controller.jumpTo(64);
    await tester.pump();
    await tester.pumpWidget(scene(controller));
    await tester.pump();
    expect(await redAt(tester, 1), greaterThan(240));
    expect(await redAt(tester, 198), greaterThan(240));
  });

  testWidgets('hard edges stay uniform while opacity zero removes separation', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      scene(controller, style: LiquidGlassScrollEdgeStyle.hard),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(64);
    await tester.pump();
    expect(await redAt(tester, 40), 255);
    expect(await redAt(tester, 100), 0);
    await tester.pumpWidget(scene(controller, opacity: 0));
    await tester.pump();
    expect(await redAt(tester, 1), 0);
    expect(await redAt(tester, 198), 0);
  });

  testWidgets('edge paint does not block taps or expose decorative semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var tapped = 0;
    await tester.pumpWidget(
      scene(
        controller,
        child: ListView(
          controller: controller,
          padding: EdgeInsets.zero,
          children: [
            GestureDetector(
              onTap: () => tapped++,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: 200,
                child: Semantics(label: 'Scrollable content'),
              ),
            ),
            const SizedBox(height: 1000),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(captureKey));
    await tester.tapAt(Offset(rect.center.dx, rect.bottom - 10));
    expect(tapped, 1);
    expect(find.bySemanticsLabel('Scrollable content'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'scroll updates repaint without rebuilding the viewport or adding filters',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var builds = 0;
      await tester.pumpWidget(
        scene(
          controller,
          child: Builder(
            builder: (_) {
              builds++;
              return ListView(
                controller: controller,
                children: const [SizedBox(height: 1000)],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 1; i <= 8; i++) {
        controller.jumpTo(i * 10.0);
        await tester.pump();
      }
      expect(builds, 1);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets(
    'horizontal scrolling does not activate vertical edge separation',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        scene(
          controller,
          child: ListView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            children: const [SizedBox(width: 1000)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.jumpTo(100);
      await tester.pump();
      expect(await redAt(tester, 1), 0);
      expect(await redAt(tester, 198), 0);
    },
  );
}
