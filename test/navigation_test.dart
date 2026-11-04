import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

const tabs = [
  LiquidGlassNavigationItem(label: 'Home', icon: Icons.home),
  LiquidGlassNavigationItem(label: 'Chats', icon: Icons.chat),
];
void main() {
  testWidgets(
    'uses the host palette, follows theme changes and accepts overrides',
    (tester) async {
      final light = ColorScheme.fromSeed(seedColor: Colors.orange).copyWith(
        primary: Colors.orange,
        onSurfaceVariant: Colors.brown,
        surface: Colors.yellow,
      );
      final dark =
          ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ).copyWith(
            primary: Colors.tealAccent,
            onSurfaceVariant: Colors.cyan,
            surface: Colors.blueGrey,
          );
      final bar = LiquidGlassNavigationBar(
        items: tabs,
        selectedIndex: 0,
        onTap: (_) {},
      );
      Widget app(ColorScheme scheme, Widget navigation) => MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: Scaffold(bottomNavigationBar: navigation),
      );
      void expectPalette(Color primary, Color inactive, Color surface) {
        expect(tester.widget<Icon>(find.byIcon(Icons.home)).color, primary);
        expect(tester.widget<Icon>(find.byIcon(Icons.chat)).color, inactive);
        final surfaceBox = find.descendant(
          of: find.byKey(const ValueKey('android-glass-surface')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color != null,
          ),
        );
        expect(
          (tester.widget<DecoratedBox>(surfaceBox).decoration as BoxDecoration)
              .color,
          surface,
        );
      }

      await tester.pumpWidget(app(light, bar));
      expectPalette(
        light.primary,
        light.onSurfaceVariant,
        light.surface.withValues(alpha: 0.30),
      );
      // Reuse the exact same bar so this exercises inherited theme notifications.
      await tester.pumpWidget(app(dark, bar));
      await tester.pumpAndSettle();
      expectPalette(
        dark.primary,
        dark.onSurfaceVariant,
        dark.surface.withValues(alpha: 0.45),
      );
      await tester.pumpWidget(
        app(
          dark,
          LiquidGlassNavigationBar(
            items: tabs,
            selectedIndex: 0,
            onTap: (_) {},
            tintColor: Colors.pink,
            unselectedColor: Colors.amber,
            surfaceColor: Colors.indigo,
          ),
        ),
      );
      expectPalette(
        Colors.pink,
        Colors.amber,
        Colors.indigo.withValues(alpha: 0.45),
      );
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );

  test('rejects invalid tab configuration', () {
    expect(
      () =>
          LiquidGlassNavigationBar(items: [], selectedIndex: 0, onTap: (_) {}),
      throwsArgumentError,
    );
    expect(
      () => LiquidGlassNavigationBar(
        items: tabs,
        selectedIndex: 2,
        onTap: (_) {},
      ),
      throwsRangeError,
    );
  });
  testWidgets('forwards taps and follows external selected index', (
    tester,
  ) async {
    int? tapped;
    Widget app(int index) => MaterialApp(
      home: Scaffold(
        bottomNavigationBar: LiquidGlassNavigationBar(
          items: tabs,
          selectedIndex: index,
          onTap: (value) => tapped = value,
        ),
      ),
    );
    await tester.pumpWidget(app(0));
    await tester.tap(find.text('Chats'));
    expect(tapped, 1);
    // A declined tab change must not move the controlled selection.
    await tester.pumpAndSettle();
    final selector = find.byKey(const ValueKey('android-glass-selector'));
    expect(
      tester.getCenter(selector).dx,
      tester.getCenter(find.text('Home')).dx,
    );
    await tester.pumpWidget(app(1));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNWidgets(2));
    expect(find.byType(ImageFiltered), findsNothing);
    expect(
      tester.getCenter(selector).dx,
      tester.getCenter(find.text('Chats')).dx,
    );
  }, variant: TargetPlatformVariant({TargetPlatform.android}));
  testWidgets('Android glass supports badges, insets, RTL and large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 24),
            textScaler: TextScaler.linear(3),
            disableAnimations: true,
            highContrast: true,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              extendBody: true,
              bottomNavigationBar: LiquidGlassNavigationBar(
                items: const [
                  ...tabs,
                  LiquidGlassNavigationItem(
                    label: 'Collections',
                    icon: Icons.museum,
                    badge: '8',
                  ),
                  LiquidGlassNavigationItem(label: 'Tours', icon: Icons.route),
                  LiquidGlassNavigationItem(
                    label: 'Profile',
                    icon: Icons.person,
                  ),
                ],
                selectedIndex: 2,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('8'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(find.byKey(const ValueKey('android-glass-selector'))).dx,
      tester.getCenter(find.text('Collections')).dx,
    );
    expect(
      tester.getSize(find.byType(LiquidGlassNavigationBar)).height,
      LiquidGlassNavigationBar.height + 24,
    );
  }, variant: TargetPlatformVariant({TargetPlatform.android}));
  testWidgets(
    'held drag enlarges lens, previews continuously and commits once',
    (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: LiquidGlassNavigationBar(
              items: tabs,
              selectedIndex: 0,
              onTap: taps.add,
            ),
          ),
        ),
      );
      final selector = find.byKey(const ValueKey('android-glass-selector'));
      final restingSize = tester.getSize(selector);
      final home = tester.getCenter(find.text('Home'));
      final chats = tester.getCenter(find.text('Chats'));
      final gesture = await tester.startGesture(home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      expect(tester.getSize(selector).height, greaterThan(restingSize.height));
      final surfaceRect = tester.getRect(
        find.byKey(const ValueKey('android-glass-surface')),
      );
      final heldRect = tester.getRect(selector);
      expect(heldRect.top, lessThan(surfaceRect.top));
      expect(heldRect.bottom, greaterThan(surfaceRect.bottom));
      expect(heldRect.width, greaterThan(restingSize.width * 1.2));
      await gesture.moveTo(Offset((home.dx + chats.dx) / 2, home.dy));
      await tester.pump();
      expect(taps, isEmpty);
      expect(tester.getCenter(selector).dx, greaterThan(home.dx));
      expect(tester.getCenter(selector).dx, lessThan(chats.dx));
      await gesture.moveTo(chats);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, [1]);
      // This host declines the selection, so the pill returns to Home.
      expect(tester.getCenter(selector).dx, closeTo(home.dx, 0.1));
      expect(tester.getSize(selector).height, closeTo(restingSize.height, 0.1));
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );
  testWidgets('cancelled RTL drag restores selection without navigation', (
    tester,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            bottomNavigationBar: LiquidGlassNavigationBar(
              items: tabs,
              selectedIndex: 0,
              onTap: taps.add,
            ),
          ),
        ),
      ),
    );
    final home = tester.getCenter(find.text('Home'));
    final chats = tester.getCenter(find.text('Chats'));
    expect(home.dx, greaterThan(chats.dx));
    final gesture = await tester.startGesture(home);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveTo(chats);
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(taps, isEmpty);
    expect(
      tester.getCenter(find.byKey(const ValueKey('android-glass-selector'))).dx,
      closeTo(home.dx, 0.1),
    );
  }, variant: TargetPlatformVariant({TargetPlatform.android}));
  testWidgets('optical renderer shaders compile and can be instantiated', (
    tester,
  ) async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/liquid_glass.frag',
    );
    final shader = program.fragmentShader();
    // Exercise the complete float ABI, including the blend geometry tail.
    shader.setFloat(40, 0);
    shader.dispose();
  });
}
