import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';
import 'package:liquid_ui_components_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('gallery material does not change after a scroll frame settles', (
    tester,
  ) async {
    final capture = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: const GlassGallery(animateBackground: false),
      ),
    );
    await tester.pumpAndSettle();
    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    final dpr = View.of(capture.currentContext!).devicePixelRatio;
    Future<List<int>> pixels() async {
      final box =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await box.toImage(pixelRatio: dpr);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List();
    }

    for (final mode in [
      LiquidGlassRendering.frosted,
      LiquidGlassRendering.balanced,
      LiquidGlassRendering.automatic,
    ]) {
      await tester.scrollUntilVisible(
        find.text('Glass quality'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final menu = tester.widget<DropdownButtonFormField<LiquidGlassRendering>>(
        find.byType(DropdownButtonFormField<LiquidGlassRendering>),
      );
      menu.onChanged!(mode);
      await tester.pumpAndSettle();
      for (final offset in [0.0, 120.0, 400.0, 700.0, 1000.0, 400.0]) {
        controller.jumpTo(offset.clamp(0, controller.position.maxScrollExtent));
        await tester.pump();
        final first = await pixels();
        await tester.pumpAndSettle();
        final settled = await pixels();
        final width = (tester.getSize(find.byKey(capture)).width * dpr).round();
        // Exclude the navigation bar's intentional compact/expanded animation.
        final end = first.length - (width * 140 * dpr).round() * 4;
        var changed = 0;
        for (var i = 0; i < end; i += 4) {
          var difference = 0;
          for (var c = 0; c < 3; c++) {
            difference += (first[i + c] - settled[i + c]).abs();
          }
          if (difference > 24) changed++;
        }
        debugPrint(
          'GALLERY_SCROLL_PIXELS mode=${mode.name} offset=$offset changed=$changed',
        );
        expect(
          changed,
          0,
          reason: 'Glass material should not change after scrolling stops.',
        );
      }
      if (mode == LiquidGlassRendering.frosted) {
        controller.jumpTo(0);
        await tester.pumpAndSettle();
        final drag = await tester.startGesture(const Offset(8, 350));
        for (var step = 0; step < 8; step++) {
          await drag.moveBy(const Offset(0, -24));
          await tester.pump();
          final moving = await pixels();
          await tester.pumpAndSettle();
          final settled = await pixels();
          final width = (tester.getSize(find.byKey(capture)).width * dpr)
              .round();
          final end = moving.length - (width * 140 * dpr).round() * 4;
          var changed = 0;
          for (var i = 0; i < end; i += 4) {
            var diff = 0;
            for (var c = 0; c < 3; c++) {
              diff += (moving[i + c] - settled[i + c]).abs();
            }
            if (diff > 24) changed++;
          }
          debugPrint('GALLERY_DRAG_PIXELS step=$step changed=$changed');
          expect(
            changed,
            0,
            reason: 'Glass should stay stable while the finger remains down.',
          );
        }
        await drag.up();
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('compare moving glass with its settled shader at the same offset', (
    tester,
  ) async {
    final controller = ScrollController();
    final capture = GlobalKey();
    final target = GlobalKey();
    addTearDown(controller.dispose);
    Future<List<int>> pixels() async {
      final box =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await box.toImage(
        pixelRatio: View.of(capture.currentContext!).devicePixelRatio,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!.buffer.asUint8List();
    }

    for (final mode in [
      LiquidGlassRendering.frosted,
      LiquidGlassRendering.balanced,
      LiquidGlassRendering.automatic,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: capture,
              child: Stack(
                children: [
                  const Positioned.fill(child: CustomPaint(painter: _Grid())),
                  ListView(
                    controller: controller,
                    children: [
                      const SizedBox(height: 160),
                      Center(
                        child: LiquidGlassSurface(
                          key: target,
                          settings: LiquidGlassSettings(
                            rendering: mode,
                            blur: 4,
                            opacity: 0.12,
                            magnification: 1.12,
                            animationDuration: Duration.zero,
                          ),
                          child: const SizedBox(width: 220, height: 120),
                        ),
                      ),
                      const SizedBox(height: 1800),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      final baseline = await pixels();
      final original = tester.getRect(find.byKey(target));
      final dpr = View.of(capture.currentContext!).devicePixelRatio;
      final imageWidth = (tester.getSize(find.byKey(capture)).width * dpr)
          .round();
      for (final offset in [0.0, 80.0, 160.0, 200.0, 240.0, 80.0]) {
        controller.jumpTo(offset);
        await tester.pump();
        final first = await pixels();
        await tester.pumpAndSettle();
        final settled = await pixels();
        var changed = 0;
        var total = 0;
        for (var i = 0; i < first.length; i += 4) {
          var difference = 0;
          for (var c = 0; c < 3; c++) {
            difference += (first[i + c] - settled[i + c]).abs();
          }
          if (difference > 24) changed++;
          total += difference;
        }
        var shifted = 0;
        var checked = 0;
        final current = tester.getRect(find.byKey(target));
        final height = first.length ~/ 4 ~/ imageWidth;
        for (var y = 8; y < 112; y += 2) {
          for (var x = 8; x < 212; x += 2) {
            final cy = ((current.top + y) * dpr).round();
            if (cy < 2 || cy >= height - 2) continue;
            final cx = ((current.left + x) * dpr).round();
            final by = ((original.top + y) * dpr).round();
            final bx = ((original.left + x) * dpr).round();
            var diff = 0;
            for (var c = 0; c < 3; c++) {
              diff +=
                  (first[(cy * imageWidth + cx) * 4 + c] -
                          baseline[(by * imageWidth + bx) * 4 + c])
                      .abs();
            }
            if (diff > 30) shifted++;
            checked++;
          }
        }
        debugPrint(
          'SCROLL_TRANSLATION ${mode.name} offset=$offset shifted=$shifted checked=$checked',
        );
        expect(
          changed,
          0,
          reason: 'The first scroll frame must match its settled shader.',
        );
        debugPrint(
          'SCROLL_PIXELS ${mode.name} offset=$offset changed=$changed mean=${total / first.length * 4 / 3}',
        );
      }
      expect(tester.takeException(), isNull);
    }
  });
}

class _Grid extends CustomPainter {
  const _Grid();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xff162e4e), BlendMode.src);
    for (var y = 0.0; y < size.height; y += 20) {
      for (var x = 0.0; x < size.width; x += 20) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, 10, 10),
          Paint()
            ..color = (y / 20).round().isEven
                ? const Color(0xfff0cc88)
                : const Color(0xff70e0da),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Grid oldDelegate) => false;
}
