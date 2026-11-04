import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

const items = [
  LiquidGlassNavigationItem(label: 'Home', icon: Icons.home),
  LiquidGlassNavigationItem(label: 'Chats', icon: Icons.chat, badge: '3'),
  LiquidGlassNavigationItem(label: 'Search', icon: Icons.search),
];

Widget host(
  ScrollController controller, {
  ScrollController? barController,
  bool enabled = true,
  bool reverse = false,
  bool extendBody = true,
  TextDirection direction = TextDirection.ltr,
  MediaQueryData media = const MediaQueryData(),
  ValueChanged<int>? onTap,
}) => MaterialApp(
  home: MediaQuery(
    data: media,
    child: Directionality(
      textDirection: direction,
      child: Scaffold(
        extendBody: extendBody,
        body: ListView(
          controller: controller,
          reverse: reverse,
          children: const [SizedBox(height: 2400)],
        ),
        bottomNavigationBar: LiquidGlassNavigationBar(
          items: items,
          selectedIndex: 0,
          onTap: onTap ?? (_) {},
          scrollController: barController ?? controller,
          shrinkOnScroll: enabled,
          glassSettings: const LiquidGlassSettings(
            rendering: LiquidGlassRendering.frosted,
          ),
        ),
      ),
    ),
  ),
);

double height(WidgetTester tester) =>
    tester.getSize(find.byType(LiquidGlassNavigationBar)).height;
Finder get surface => find.byKey(const ValueKey('android-glass-surface'));

void main() {
  testWidgets(
    'scroll hysteresis compacts down and expands up with safe targets',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller));
      await tester.pumpAndSettle();
      final fullWidth = tester.getSize(surface).width;
      expect(height(tester), LiquidGlassNavigationBar.height);
      controller.jumpTo(20);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.height);
      controller.jumpTo(80);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.compactHeight);
      expect(tester.getSize(surface).width, lessThan(fullWidth));
      final chats = find.bySemanticsLabel('Chats, 3');
      expect(chats, findsOneWidget);
      expect(tester.getSize(chats).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(chats).width, greaterThanOrEqualTo(48));
      controller.jumpTo(77);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.compactHeight);
      controller.jumpTo(70);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.height);
      semantics.dispose();
    },
  );

  testWidgets(
    'compact taps expand without changing the controlled destination',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final taps = <int>[];
      await tester.pumpWidget(host(controller, onTap: taps.add));
      await tester.pumpAndSettle();
      controller.jumpTo(100);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Chats, 3'));
      await tester.pumpAndSettle();
      expect(taps, [1]);
      expect(height(tester), LiquidGlassNavigationBar.height);
      expect(
        tester
            .widget<Semantics>(find.bySemanticsLabel('Home'))
            .properties
            .selected,
        isTrue,
      );
      semantics.dispose();
    },
  );

  testWidgets('bar geometry freezes while a compact RTL gesture is held', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final taps = <int>[];
    await tester.pumpWidget(
      host(controller, direction: TextDirection.rtl, onTap: taps.add),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(100);
    await tester.pumpAndSettle();
    final start = tester.getRect(surface);
    final gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Home')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.getRect(surface), start);
    await gesture.moveTo(tester.getCenter(find.bySemanticsLabel('Search')));
    await tester.pump();
    expect(tester.getRect(surface), start);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, [2]);
    expect(height(tester), LiquidGlassNavigationBar.height);
    semantics.dispose();
  });

  testWidgets('accessibility preferences retain expanded navigation', (
    tester,
  ) async {
    for (final media in [
      const MediaQueryData(disableAnimations: true),
      const MediaQueryData(accessibleNavigation: true),
      const MediaQueryData(textScaler: TextScaler.linear(2)),
    ]) {
      final controller = ScrollController();
      await tester.pumpWidget(host(controller, media: media));
      await tester.pumpAndSettle();
      controller.jumpTo(100);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.height);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
  });

  testWidgets('turning the feature off expands an already compact bar', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(controller));
    await tester.pumpAndSettle();
    controller.jumpTo(100);
    await tester.pumpAndSettle();
    expect(height(tester), LiquidGlassNavigationBar.compactHeight);
    await tester.pumpWidget(host(controller, enabled: false));
    await tester.pumpAndSettle();
    expect(height(tester), LiquidGlassNavigationBar.height);
  });

  testWidgets(
    'reversed scrolling follows physical direction and expands at the top',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller, reverse: true));
      await tester.pumpAndSettle();
      controller.jumpTo(200);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.height);
      controller.jumpTo(100);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.compactHeight);
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.height);
    },
  );

  testWidgets('controller replacement and unattached controllers are safe', (
    tester,
  ) async {
    final first = ScrollController();
    final second = ScrollController();
    final unattached = ScrollController();
    addTearDown(second.dispose);
    addTearDown(unattached.dispose);
    await tester.pumpWidget(host(first));
    await tester.pumpAndSettle();
    first.jumpTo(100);
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(second));
    await tester.pumpAndSettle();
    first.dispose();
    expect(height(tester), LiquidGlassNavigationBar.height);
    second.jumpTo(200);
    await tester.pumpAndSettle();
    expect(height(tester), LiquidGlassNavigationBar.compactHeight);
    await tester.pumpWidget(host(second, barController: unattached));
    await tester.pumpAndSettle();
    expect(height(tester), LiquidGlassNavigationBar.height);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'viewport resizing at the scroll end does not oscillate the bar',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(controller, extendBody: false));
      await tester.pumpAndSettle();
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.compactHeight);
      expect(tester.hasRunningAnimations, isFalse);
      controller.jumpTo(controller.offset - 24);
      await tester.pumpAndSettle();
      expect(height(tester), LiquidGlassNavigationBar.height);
    },
  );
}
