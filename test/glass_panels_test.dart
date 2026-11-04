import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

void main() {
  testWidgets(
    'modal settles monotonically without changing the rendering path',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => LiquidGlassPrompt.confirm(
                  context,
                  title: 'Smooth transition',
                  message: 'A stable surface throughout.',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      final finder = find.byType(LiquidGlassSurface);
      var previous = tester.getSize(finder);
      final shapeType = tester
          .widget<LiquidGlassSurface>(finder)
          .shape
          .runtimeType;
      final textSize = tester.getSize(find.text('Smooth transition'));
      for (var i = 0; i < 27; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(previous.width - 0.001));
        expect(size.height, greaterThanOrEqualTo(previous.height - 0.001));
        expect(
          tester.widget<LiquidGlassSurface>(finder).shape.runtimeType,
          shapeType,
        );
        expect(tester.getSize(find.text('Smooth transition')), textSize);
        previous = size;
      }
      final beforeSettled = previous;
      await tester.pumpAndSettle();
      expect(tester.getSize(finder), beforeSettled);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (finder.evaluate().isEmpty) break;
        final size = tester.getSize(finder);
        expect(size.width, lessThanOrEqualTo(previous.width + 0.001));
        expect(size.height, lessThanOrEqualTo(previous.height + 0.001));
        previous = size;
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  for (final reduced in [false, true]) {
    testWidgets(
      'prompt liquid reveal preserves text layout (reduced: $reduced)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    child: const Text('Open'),
                    onPressed: () => LiquidGlassPrompt.confirm(
                      context,
                      title: 'A liquid prompt',
                      message: 'The content stays sharp.',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pump();
        final glass = find.byType(LiquidGlassSurface);
        final initial = tester.getSize(glass);
        final textSize = tester.getSize(find.text('A liquid prompt'));
        await tester.pump(const Duration(milliseconds: 120));
        final growing = tester.getSize(glass);
        if (!reduced) {
          expect(growing.width, greaterThan(initial.width));
          expect(growing.height, greaterThan(initial.height));
          expect(tester.widget<LiquidGlassSurface>(glass).shape, isNotNull);
        }
        await tester.pumpAndSettle();
        final full = tester.getSize(glass);
        expect(tester.getSize(find.text('A liquid prompt')), textSize);
        if (reduced) {
          expect(initial, full);
        }
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        if (!reduced) {
          expect(tester.getSize(glass).height, lessThan(full.height));
        }
        await tester.pumpAndSettle();
        expect(find.text('A liquid prompt'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('modal panel inherits settings and returns its action result', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassTheme(
          settings: const LiquidGlassSettings(
            rendering: LiquidGlassRendering.frosted,
          ),
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await LiquidGlassPanel.show<String>(
                    context,
                    builder: (context) => LiquidGlassPanel(
                      title: 'Details',
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, 'done'),
                        child: const Text('Done'),
                      ),
                    ),
                  );
                },
                child: const Text('Open panel'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open panel'));
    await tester.pumpAndSettle();
    expect(
      LiquidGlassTheme.of(
        tester.element(find.byType(LiquidGlassPanel)),
      ).rendering,
      LiquidGlassRendering.frosted,
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result, 'done');
    expect(tester.takeException(), isNull);
  });
  testWidgets('confirmation returns a result and captures local settings', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassTheme(
          settings: const LiquidGlassSettings(
            rendering: LiquidGlassRendering.solid,
          ),
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await LiquidGlassPrompt.confirm(
                  context,
                  title: 'Create collection?',
                  message: 'Save your favorites here.',
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final surface = tester.widget<LiquidGlassSurface>(
      find.byType(LiquidGlassSurface),
    );
    // The panel inherits the settings inside the new route.
    expect(surface.settings!.rendering, LiquidGlassRendering.solid);
    final context = tester.element(find.byType(LiquidGlassPrompt));
    expect(LiquidGlassTheme.of(context).rendering, LiquidGlassRendering.solid);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('alert supports dismissal and narrow large-text layout', (
    tester,
  ) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: LiquidGlassAlert(
                  title: 'Connection unavailable',
                  message: 'Try again when your connection returns.',
                  tone: LiquidGlassAlertTone.warning,
                  onDismiss: () => dismissed = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Dismiss alert'));
    expect(dismissed, isTrue);
  });
}
