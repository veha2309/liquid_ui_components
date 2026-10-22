import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() {
  testWidgets('themed navigation paints icons beneath the optical selector', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LiquidGlassNavigationBar(
            items: const [
              LiquidGlassNavigationItem(label: 'Home', icon: Icons.home),
              LiquidGlassNavigationItem(label: 'Chats', icon: Icons.chat),
            ],
            selectedIndex: 0,
            onTap: (_) {},
            glassSettings: const LiquidGlassSettings(),
          ),
        ),
      ),
    );
    final selector = find.byKey(const ValueKey('android-glass-selector'));
    final scene = tester.widget<Stack>(
      find.ancestor(of: selector, matching: find.byType(Stack)).first,
    );
    // One actual icon per destination, in the backdrop source before the lens.
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(
      find.descendant(
        of: find.byWidget(scene.children[1]),
        matching: find.byIcon(Icons.home),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byWidget(scene.children[3]),
        matching: find.byIcon(Icons.home),
      ),
      findsNothing,
    );
    expect(find.text('Home'), findsOneWidget);

    LiquidGlassSettings lens() => tester
        .widget<LiquidGlassSurface>(
          find.descendant(
            of: selector,
            matching: find.byType(LiquidGlassSurface),
          ),
        )
        .settings!;
    final resting = lens();
    expect(resting.rendering, LiquidGlassRendering.automatic);
    expect(resting.magnification, greaterThan(1));
    expect(resting.scaleRefractionWithSize, isFalse);
    final press = await tester.startGesture(tester.getCenter(selector));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(lens().magnification, greaterThan(resting.magnification + .1));
    expect(lens().depth, greaterThan(resting.depth));
    expect(
      lens().chromaticAberration,
      greaterThan(resting.chromaticAberration),
    );
    await press.cancel();
    await tester.pumpAndSettle();
    expect(lens().magnification, resting.magnification);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'navigation respects explicit rendering and transparency choices',
    (tester) async {
      for (final mode in LiquidGlassRendering.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: LiquidGlassNavigationBar(
                items: const [
                  LiquidGlassNavigationItem(label: 'Home', icon: Icons.home),
                  LiquidGlassNavigationItem(label: 'Chats', icon: Icons.chat),
                ],
                selectedIndex: 0,
                onTap: (_) {},
                glassSettings: LiquidGlassSettings(
                  rendering: mode,
                  reduceTransparency: true,
                ),
              ),
            ),
          ),
        );
        final surfaces = tester.widgetList<LiquidGlassSurface>(
          find.byType(LiquidGlassSurface),
        );
        expect(surfaces.length, 2);
        for (final surface in surfaces) {
          expect(surface.settings!.rendering, mode);
          expect(surface.settings!.reduceTransparency, isTrue);
        }
        expect(find.byType(BackdropFilter), findsNothing);
      }
    },
  );
}
