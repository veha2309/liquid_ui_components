import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final mode in LiquidGlassRendering.values.where(
    (m) => m != LiquidGlassRendering.solid,
  )) {
    for (final height in [48.0, 120.0, 650.0]) {
      for (final customShape in [false, if (height == 120) true]) {
        testWidgets(
          '${mode.name} surface height=$height custom=$customShape keeps brightness across clipping',
          (tester) async {
            final controller = ScrollController();
            final capture = GlobalKey();
            final surfaceKey = UniqueKey();
            addTearDown(controller.dispose);
            final material = LiquidGlassSettings(
              rendering: mode,
              blur: 11,
              opacity: 0.33,
              animationDuration: Duration.zero,
            );
            await tester.pumpWidget(
              RepaintBoundary(
                key: capture,
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Panel brightness')),
                    body: ColoredBox(
                      color: const Color(0xff507080),
                      child: BackdropGroup(
                        child: ListView(
                          controller: controller,
                          children: [
                            LiquidGlassSurface(
                              settings: material,
                              child: const SizedBox(height: 40),
                            ),
                            const SizedBox(height: 60),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: LiquidGlassSurface(
                                key: surfaceKey,
                                settings: material,
                                shape: customShape
                                    ? const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20),
                                        ),
                                      )
                                    : null,
                                child: SizedBox(height: height),
                              ),
                            ),
                            const SizedBox(height: 1200),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            Future<List<double>> sample() async {
              final box =
                  capture.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await box.toImage(
                pixelRatio: View.of(capture.currentContext!).devicePixelRatio,
              );
              final data = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!.buffer.asUint8List();
              final sum = List<double>.filled(6, 0);
              final dpr = View.of(capture.currentContext!).devicePixelRatio;
              final centerY =
                  ((tester.getTopLeft(find.byKey(surfaceKey)).dy + height / 2) *
                          dpr)
                      .round();
              // Sample both the center and close to the left rim, where exterior
              // shadows could otherwise leak back through the backdrop's blur kernel.
              for (var patch = 0; patch < 2; patch++) {
                final centerX = patch == 0
                    ? image.width ~/ 2
                    : (32 * dpr).round();
                for (var y = centerY - 4; y < centerY + 4; y++) {
                  for (var x = centerX - 4; x < centerX + 4; x++) {
                    for (var c = 0; c < 3; c++) {
                      sum[patch * 3 + c] +=
                          data[(y * image.width + x) * 4 + c] / 64;
                    }
                  }
                }
              }
              image.dispose();
              return sum;
            }

            final before = await sample();
            expect(
              before.take(3).toList(),
              isNot([80.0, 112.0, 128.0]),
              reason:
                  'The capture must contain rendered glass, not just the background.',
            );
            for (final offset in [60.0, 100.0, 104.0, 60.0]) {
              controller.jumpTo(offset);
              await tester.pumpAndSettle();
              final after = await sample();
              debugPrint(
                'SURFACE_BRIGHTNESS mode=${mode.name} height=$height custom=$customShape offset=$offset before=$before after=$after',
              );
              for (var c = 0; c < before.length; c++) {
                expect(
                  after[c],
                  closeTo(before[c], 1),
                  reason:
                      'Center and rim brightness must stay stable on a constant backdrop.',
                );
              }
            }
          },
        );
      }
    }
  }
}
