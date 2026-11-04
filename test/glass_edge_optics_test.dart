import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() {
  test('edge optics scale gently with size and preserve a clear center', () {
    const settings = LiquidGlassSettings();
    final small = settings.resolveEdgeOptics(const Size(120, 48));
    final reference = settings.resolveEdgeOptics(const Size(120, 64));
    final large = settings.resolveEdgeOptics(const Size(320, 240));
    expect(small.refractionWidth, lessThan(reference.refractionWidth));
    expect(small.depth, lessThan(reference.depth));
    expect(large.refractionWidth, greaterThan(reference.refractionWidth));
    expect(large.depth, greaterThan(reference.depth));
    expect(
      settings.resolveEdgeOptics(const Size(4, 4)).refractionWidth,
      closeTo(0.88, 0.001),
    );
    expect(settings.resolveEdgeOptics(Size.zero), (
      refractionWidth: 0.0,
      depth: 0.0,
    ));
    expect(
      settings
          .copyWith(refractionWidth: 0)
          .resolveEdgeOptics(const Size(100, 100)),
      (refractionWidth: 0.0, depth: 0.0),
    );
    final fixed = settings
        .copyWith(scaleRefractionWithSize: false)
        .resolveEdgeOptics(const Size(120, 48));
    expect(fixed.refractionWidth, 8);
    expect(fixed.depth, settings.depth);
  });

  test('new edge controls survive copyWith and work in the clear preset', () {
    const settings = LiquidGlassSettings.clear(
      lightDirection: 270,
      refractionWidth: 12,
      scaleRefractionWithSize: false,
      edgeAmbientIntensity: 0.6,
      edgeLightSpread: 0.8,
    );
    final copy = settings.copyWith(opacity: 0.2);
    expect(copy.lightDirection, 270);
    expect(copy.refractionWidth, 12);
    expect(copy.scaleRefractionWithSize, isFalse);
    expect(copy.edgeAmbientIntensity, 0.6);
    expect(copy.edgeLightSpread, 0.8);
    expect(
      () => LiquidGlassSettings(lightDirection: double.nan),
      throwsAssertionError,
    );
    expect(
      () => LiquidGlassSettings.clear(refractionWidth: -1),
      throwsAssertionError,
    );
    expect(() => LiquidGlassSettings(edgeLightSpread: 2), throwsAssertionError);
  });

  testWidgets('frosted rim follows light direction without additional blur', (
    tester,
  ) async {
    const captureKey = ValueKey('rim-capture');
    Widget scene(double direction, {bool highContrast = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: captureKey,
              child: ColoredBox(
                color: const Color(0xff0000ff),
                child: LiquidGlassSurface(
                  settings: LiquidGlassSettings(
                    rendering: LiquidGlassRendering.frosted,
                    opacity: 0,
                    blur: 0,
                    tintColor: Colors.white,
                    borderWidth: 2,
                    lightIntensity: 1,
                    lightDirection: direction,
                    edgeAmbientIntensity: 0,
                    shadowOpacity: 0,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(width: 120, height: 80),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Future<({int top, int bottom})> pixels() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(captureKey),
      );
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final result = (
          top: bytes.getUint8((image.width + 60) * 4),
          bottom: bytes.getUint8((78 * image.width + 60) * 4),
        );
        image.dispose();
        return result;
      }))!;
    }

    await tester.pumpWidget(scene(90));
    await tester.pumpAndSettle();
    final above = await pixels();
    expect(above.top, greaterThan(above.bottom + 20));
    await tester.pumpWidget(scene(270));
    await tester.pumpAndSettle();
    final below = await pixels();
    expect(below.bottom, greaterThan(below.top + 20));
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pumpWidget(scene(270, highContrast: true));
    await tester.pumpAndSettle();
    final solid = await pixels();
    expect(solid.top, closeTo(solid.bottom, 1));
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
