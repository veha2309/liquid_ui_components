import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// Internal checks belong in integration tests, never in the example UI.
// ignore: implementation_imports
import 'package:liquid_ui_components/src/rendering/glass_backdrop.dart';
// ignore: implementation_imports
import 'package:liquid_ui_components/src/rendering/stable_glass_backdrop.dart';
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
    final blender = tester.widget<GlassBackdrop>(find.byType(GlassBackdrop));
    expect(blender.settings.rendering, LiquidGlassRendering.balanced);
    expect(blender.settings.depth, greaterThan(0));
    expect(blender.settings.blur, 2);
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
      'packages/liquid_ui_components/shaders/liquid_glass.frag',
    );
    await tester.pumpWidget(const GlassGallery(animateBackground: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blending'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    void expectFixedDiameter() {
      final pass = tester.widget<StableBlendPass>(find.byType(StableBlendPass));
      expect(pass.bounds.length, 4);
      for (final bounds in pass.bounds) {
        expect(bounds.size, const Size(68, 68));
      }
    }

    expectFixedDiameter();
    LiquidGlassSettings currentStyle() =>
        tester.widget<StableBlendPass>(find.byType(StableBlendPass)).settings;
    final initialStyle = currentStyle();
    expect(initialStyle.blur, 8);
    expect(initialStyle.opacity, closeTo(0.3, 0.01));
    final viscositySlider = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(Slider),
    );
    tester.widget<Slider>(viscositySlider).onChanged!(1);
    await tester.pumpAndSettle();
    final thickStyle = currentStyle();
    expect(thickStyle.depth, greaterThan(initialStyle.depth));
    expect(thickStyle.blur, 8);
    expect(thickStyle.opacity, closeTo(0.3, 0.01));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('blend-before');
    final lens = find.byTooltip('Blend action 1');
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
