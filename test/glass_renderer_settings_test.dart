import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() {
  test(
    'existing settings keep stable optics; native requires explicit opt-in',
    () {
      expect(const LiquidGlassSettings().renderer, LiquidGlassRenderer.stable);
      expect(
        const LiquidGlassSettings.clear().renderer,
        LiquidGlassRenderer.stable,
      );
      final experimental = const LiquidGlassSettings().copyWith(
        renderer: LiquidGlassRenderer.experimentalNative,
      );
      expect(
        experimental.copyWith(blur: 3).renderer,
        LiquidGlassRenderer.experimentalNative,
      );
      expect(
        experimental.copyWith(renderer: LiquidGlassRenderer.stable).renderer,
        LiquidGlassRenderer.stable,
      );
    },
  );
}
