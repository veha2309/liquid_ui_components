import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() {
  testWidgets(
    'overlapping switch track and thumb use independent backdrop inputs',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BackdropGroup(
              child: Center(
                child: LiquidGlassSwitch(
                  value: false,
                  onChanged: (_) {},
                  semanticLabel: 'Toggle',
                  settings: const LiquidGlassSettings(
                    rendering: LiquidGlassRendering.frosted,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final filters = find.byType(BackdropFilter);
      expect(filters, findsNWidgets(2));
      final track = tester.renderObject<RenderBackdropFilter>(filters.at(0));
      final thumb = tester.renderObject<RenderBackdropFilter>(filters.at(1));
      expect(track.backdropKey, isNotNull);
      expect(thumb.backdropKey, isNotNull);
      expect(
        identical(track.backdropKey, thumb.backdropKey),
        isFalse,
        reason:
            'Overlapping filters must not share the batched backdrop texture.',
      );
    },
  );
  for (final switchControl in [true, false]) {
    testWidgets(
      '${switchControl ? 'switch' : 'slider'} bubble expands and clears on hold, restores on cancellation',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: switchControl
                      ? Align(
                          child: LiquidGlassSwitch(
                            value: false,
                            onChanged: (_) {},
                            semanticLabel: 'Toggle',
                          ),
                        )
                      : LiquidGlassSlider(value: 0.5, onChanged: (_) {}),
                ),
              ),
            ),
          ),
        );
        final thumb = find.byKey(
          ValueKey(switchControl ? 'glass-switch-thumb' : 'glass-slider-thumb'),
        );
        final restSize = tester.getSize(thumb);
        final restCenter = tester.getCenter(thumb);
        expect(restSize.width, switchControl ? 24 : 28);
        final rest = tester.widget<LiquidGlassSurface>(thumb).settings!;
        final gesture = await tester.startGesture(tester.getCenter(thumb));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final held = tester.widget<LiquidGlassSurface>(thumb).settings!;
        if (switchControl) expect(tester.getCenter(thumb), restCenter);
        expect(tester.getSize(thumb).width, greaterThan(restSize.width));
        expect(held.opacity, lessThan(rest.opacity));
        expect(held.blur, 0);
        expect(held.magnification, greaterThanOrEqualTo(1.18));
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(tester.getSize(thumb), restSize);
        expect(
          tester.widget<LiquidGlassSurface>(thumb).settings!.opacity,
          rest.opacity,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('reduced motion and transparency survive switch holds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Center(
              child: LiquidGlassSwitch(
                value: false,
                onChanged: (_) {},
                semanticLabel: 'Toggle',
                settings: const LiquidGlassSettings(reduceTransparency: true),
              ),
            ),
          ),
        ),
      ),
    );
    final thumb = find.byKey(const ValueKey('glass-switch-thumb'));
    final rest = tester.getSize(thumb);
    final hold = await tester.startGesture(tester.getCenter(thumb));
    await tester.pump();
    expect(tester.getSize(thumb), rest);
    expect(
      tester.widget<LiquidGlassSurface>(thumb).settings!.reduceTransparency,
      isTrue,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    await hold.up();
    await tester.pumpAndSettle();
  });
}
