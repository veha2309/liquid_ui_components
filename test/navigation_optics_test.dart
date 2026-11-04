import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() {
  for (final mode in [
    LiquidGlassRendering.frosted,
    LiquidGlassRendering.solid,
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$mode keeps selected icons and badges above the selector in $brightness',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: StatefulBuilder(
                builder: (context, setState) => Scaffold(
                  bottomNavigationBar: LiquidGlassNavigationBar(
                    items: const [
                      LiquidGlassNavigationItem(
                        label: 'Home',
                        icon: Icons.home,
                        badge: '3',
                      ),
                      LiquidGlassNavigationItem(
                        label: 'Chats',
                        icon: Icons.chat,
                      ),
                    ],
                    selectedIndex: 0,
                    onTap: (_) {},
                    glassSettings: LiquidGlassSettings(rendering: mode),
                  ),
                ),
              ),
            ),
          );
          void expectForeground() {
            final selector = find.byKey(
              const ValueKey('android-glass-selector'),
            );
            final scene = tester.widget<Stack>(
              find.ancestor(of: selector, matching: find.byType(Stack)).first,
            );
            for (final icon in [Icons.home, Icons.chat]) {
              expect(find.byIcon(icon), findsOneWidget);
              expect(
                find.descendant(
                  of: find.byWidget(scene.children.last),
                  matching: find.byIcon(icon),
                ),
                findsOneWidget,
              );
            }
            expect(find.text('3'), findsOneWidget);
          }

          expectForeground();
          final gesture = await tester.startGesture(
            tester.getCenter(find.byIcon(Icons.home)),
          );
          await tester.pump(const Duration(milliseconds: 220));
          expectForeground();
          await gesture.moveTo(tester.getCenter(find.byIcon(Icons.chat)));
          await tester.pump();
          expectForeground();
          await gesture.up();
          await tester.pumpAndSettle();
          expectForeground();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
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
      ui.ImageFilter.isShaderFilterSupported ? findsOneWidget : findsNothing,
    );
    expect(
      find.descendant(
        of: find.byWidget(scene.children[3]),
        matching: find.byIcon(Icons.home),
      ),
      ui.ImageFilter.isShaderFilterSupported ? findsNothing : findsOneWidget,
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
