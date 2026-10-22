import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

Widget app(
  Widget child, {
  LiquidGlassSettings? settings,
  MediaQueryData? media,
}) => MaterialApp(
  home: Scaffold(
    body: MediaQuery(
      data: media ?? const MediaQueryData(),
      child: LiquidGlassTheme(
        settings: settings ?? const LiquidGlassSettings(),
        child: Center(child: child),
      ),
    ),
  ),
);

Color surfaceTint(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color != null,
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

void main() {
  test('validates optical settings and segment identities', () {
    expect(() => LiquidGlassSettings(blur: -1), throwsAssertionError);
    expect(() => LiquidGlassSettings(opacity: 2), throwsAssertionError);
    expect(() => LiquidGlassSettings(depth: double.nan), throwsAssertionError);
    expect(
      () => LiquidGlassSlider(value: 5, onChanged: (_) {}),
      throwsAssertionError,
    );
    expect(
      () => LiquidGlassSegmentedControl<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Zero')),
          ButtonSegment(value: 0, label: Text('Zero')),
        ],
        selected: 0,
        onSelectionChanged: (_) {},
      ),
      throwsArgumentError,
    );
    expect(
      () => LiquidGlassSegmentedControl<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Zero')),
          ButtonSegment(value: 1, label: Text('One')),
        ],
        selected: 2,
        onSelectionChanged: (_) {},
      ),
      throwsArgumentError,
    );
  });

  testWidgets('surfaces size to content and inherit or override settings', (
    tester,
  ) async {
    const surface = LiquidGlassSurface(child: SizedBox(width: 180, height: 60));
    await tester.pumpWidget(
      app(
        surface,
        settings: const LiquidGlassSettings(
          tintColor: Colors.pink,
          opacity: 0.2,
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(LiquidGlassSurface)),
      const Size(180, 60),
    );
    expect(surfaceTint(tester), Colors.pink.withValues(alpha: 0.2));
    // Reuse the child to ensure InheritedWidget notifications reach it.
    await tester.pumpWidget(
      app(
        surface,
        settings: const LiquidGlassSettings(
          tintColor: Colors.blue,
          opacity: 0.6,
        ),
      ),
    );
    expect(surfaceTint(tester), Colors.blue.withValues(alpha: 0.6));
    await tester.pumpWidget(
      app(
        const LiquidGlassSurface(
          settings: LiquidGlassSettings(tintColor: Colors.green, opacity: 0.4),
          child: SizedBox(width: 100, height: 50),
        ),
        settings: const LiquidGlassSettings(tintColor: Colors.red),
      ),
    );
    expect(surfaceTint(tester), Colors.green.withValues(alpha: 0.4));
  });

  testWidgets(
    'high contrast and reduced transparency remove backdrop effects',
    (tester) async {
      const child = LiquidGlassButton(onPressed: null, child: Text('Action'));
      for (final config in [
        const LiquidGlassSettings(reduceTransparency: true),
        const LiquidGlassSettings(rendering: LiquidGlassRendering.solid),
      ]) {
        await tester.pumpWidget(app(child, settings: config));
        expect(find.byType(BackdropFilter), findsNothing);
        expect(surfaceTint(tester).a, 1);
      }
      await tester.pumpWidget(
        app(child, media: const MediaQueryData(highContrast: true)),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      expect(surfaceTint(tester).a, 1);
      await tester.pumpWidget(
        app(child, media: const MediaQueryData(disableAnimations: true)),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
            .duration,
        Duration.zero,
      );
    },
  );

  testWidgets('buttons support keyboard activation and disabled actions', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      app(
        LiquidGlassButton(
          autofocus: true,
          onPressed: () => presses++,
          child: const Text('Save'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(presses, 1);
    await tester.pumpWidget(
      app(const LiquidGlassButton(onPressed: null, child: Text('Save'))),
    );
    await tester.tap(find.text('Save'));
    expect(presses, 1);
  });

  testWidgets('segments request selection and retain host controlled value', (
    tester,
  ) async {
    int? requested;
    await tester.pumpWidget(
      app(
        LiquidGlassSegmentedControl<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Day')),
            ButtonSegment(value: 1, label: Text('Week')),
          ],
          selected: 0,
          onSelectionChanged: (value) => requested = value,
        ),
      ),
    );
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(requested, 1);
    expect(
      tester
          .widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>))
          .selected,
      {0},
    );
  });

  testWidgets('slider and switch forward changes without owning state', (
    tester,
  ) async {
    double? slider;
    bool? toggle;
    await tester.pumpWidget(
      app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiquidGlassSlider(
              value: 0.2,
              semanticLabel: 'Volume',
              onChanged: (v) => slider = v,
            ),
            LiquidGlassSwitch(
              value: false,
              semanticLabel: 'Audio',
              onChanged: (v) => toggle = v,
            ),
          ],
        ),
      ),
    );
    await tester.tapAt(
      tester.getCenter(find.byType(Slider)) + const Offset(100, 0),
    );
    await tester.tap(find.byType(Switch));
    expect(slider, greaterThan(0.2));
    expect(toggle, true);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 0.2);
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    expect(find.bySemanticsLabel('Audio'), findsOneWidget);
  });

  testWidgets('toolbar wraps with RTL and large text on narrow layouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(
        Directionality(
          textDirection: TextDirection.rtl,
          child: LiquidGlassToolbar(
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Save collection'),
              ),
              IconButton(
                onPressed: () {},
                tooltip: 'Share',
                icon: const Icon(Icons.share),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Edit collection'),
              ),
            ],
          ),
        ),
        media: const MediaQueryData(textScaler: TextScaler.linear(2)),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(LiquidGlassToolbar)).width,
      lessThanOrEqualTo(320),
    );
  });

  testWidgets('navigation honors shared rendering preference', (tester) async {
    await tester.pumpWidget(
      app(
        LiquidGlassNavigationBar(
          items: const [
            LiquidGlassNavigationItem(label: 'Home', icon: Icons.home),
            LiquidGlassNavigationItem(label: 'Search', icon: Icons.search),
          ],
          selectedIndex: 0,
          onTap: (_) {},
        ),
        settings: const LiquidGlassSettings(reduceTransparency: true),
      ),
    );
    expect(find.byType(LiquidGlassSurface), findsNWidgets(2));
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
