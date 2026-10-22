import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// Inspect the renderer owned by liquid_ui_components without making the
// example's public API depend on the optical implementation.
// ignore: depend_on_referenced_packages
import 'package:liquid_glass_easy/liquid_glass_easy.dart' as optical;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_ui_components_example/main.dart';
import 'package:liquid_ui_components/liquid_glass.dart';
import 'package:liquid_ui_components_example/gallery_backdrop.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('balanced mode retains the optical blending pass', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GalleryBackdrop(
            dark: false,
            animated: false,
            child: Center(
              child: LiquidGlassBlend.draggable(
                viscosity: 0.8,
                settings: const LiquidGlassSettings(
                  rendering: LiquidGlassRendering.balanced,
                  blur: 2,
                  opacity: 0.08,
                  depth: 0.15,
                  magnification: 1.06,
                ),
                first: const Icon(Icons.pause),
                second: const Icon(Icons.music_note),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    final blender = tester.widget<optical.LiquidGlassBlender>(
      find.byType(optical.LiquidGlassBlender),
    );
    expect(blender.style.refraction.chromaticAberration, 0);
    expect(
      (blender.style.refraction.refractionType as optical.OpticalRefraction)
          .depth,
      greaterThan(0),
    );
    expect(blender.style.appearance.blur.sigmaX, 2);
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('blend-balanced-separated');
    await tester.drag(
      find.byKey(const ValueKey('blend-drag-0')),
      const Offset(70, 0),
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('blend-balanced-merged');
    expect(tester.takeException(), isNull);
  });
  testWidgets('optical blending paints on the device', (tester) async {
    debugPrint(
      'BLEND shader filters supported: ${ui.ImageFilter.isShaderFilterSupported}',
    );
    await ui.FragmentProgram.fromAsset(
      'packages/liquid_glass_easy/lib/assets/shaders/metaball_glass.frag',
    );
    await tester.pumpWidget(const GlassGallery(animateBackground: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blending'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    void expectFixedDiameter() {
      final lenses = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(optical.LiquidGlassLens),
      );
      expect(lenses, findsNWidgets(2));
      for (final element in lenses.evaluate()) {
        final box = element.findRenderObject()! as RenderBox;
        final rect = MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        );
        expect(rect.width, closeTo(84, 0.1));
        expect(rect.height, closeTo(84, 0.1));
      }
    }

    expectFixedDiameter();
    optical.LiquidGlassStyle currentStyle() => tester
        .widget<optical.LiquidGlassBlender>(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(optical.LiquidGlassBlender),
          ),
        )
        .style;
    final initialStyle = currentStyle();
    expect(initialStyle.appearance.blur.sigmaX, 8);
    expect(initialStyle.appearance.color.a, closeTo(0.3, 0.01));
    final viscositySlider = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(Slider),
    );
    tester.widget<Slider>(viscositySlider).onChanged!(1);
    await tester.pumpAndSettle();
    final thickStyle = currentStyle();
    expect(
      (thickStyle.refraction.refractionType as optical.OpticalRefraction).depth,
      greaterThan(
        (initialStyle.refraction.refractionType as optical.OpticalRefraction)
            .depth,
      ),
    );
    expect(thickStyle.appearance.blur.sigmaX, 8);
    expect(thickStyle.appearance.color.a, closeTo(0.3, 0.01));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('blend-before');
    final lens = find.descendant(
      of: find.byType(Dialog),
      matching: find.byKey(const ValueKey('blend-drag-0')),
    );
    await tester.drag(lens, const Offset(55, 20));
    await tester.pumpAndSettle();
    expectFixedDiameter();
    await binding.takeScreenshot('blend-after');
    await tester.drag(lens, const Offset(-55, -65));
    await tester.pumpAndSettle();
    expectFixedDiameter();
    await binding.takeScreenshot('blend-distant-diagonal');
    expect(tester.takeException(), isNull);
  });
}
