import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';
import 'package:liquid_ui_components_example/main.dart';
import 'package:ui_tester/testing.dart';

const galleryUiConfig = UiTestConfig(
  seed: 42,
  maxActions: 200,
  maxDuration: Duration(minutes: 3),
  maxScrolls: 12,
  actionTimeout: Duration(seconds: 6),
);

UiScenario galleryScenario() {
  var favorite = false;
  return UiScenario(
    id: 'liquid-glass-gallery',
    app: () => const UiTestScope(
      id: 'root',
      child: GlassGallery(animateBackground: false),
    ),
    // Each reset mounts a fresh gallery; it has no external services or fixtures.
    reset: () => favorite = false,
    adapters: const [GalleryControlAdapter()],
    checks: [
      (session, action) {
        final tester = session.tester;
        if (action.target == 'key:save-collection') {
          expect(find.text('Collection saved'), findsOneWidget);
        }
        if (action.target == 'key:favorite-button' && action.kind == 'tap') {
          if (action.count.isOdd) favorite = !favorite;
          final button = tester.widget<LiquidGlassIconButton>(
            find.byKey(const ValueKey('favorite-button')),
          );
          expect(
            (button.icon as Icon).icon,
            favorite ? Icons.favorite_rounded : Icons.favorite_outline,
          );
        }
        for (final slider in tester.widgetList<LiquidGlassSlider>(
          find.byType(LiquidGlassSlider),
        )) {
          expect(slider.value, inInclusiveRange(slider.min, slider.max));
        }
        if (action.target == 'key:activity-selector') {
          final selection = int.parse(action.value ?? '2').clamp(0, 2);
          expect(
            find.text(
              'Showing ${['daily', 'weekly', 'monthly'][selection]} activity',
            ),
            findsOneWidget,
          );
        }
        if (action.target == 'key:gallery-navigation') {
          expect(
            tester
                .widget<LiquidGlassNavigationBar>(
                  find.byKey(const ValueKey('gallery-navigation')),
                )
                .selectedIndex,
            int.parse(action.value ?? '2').clamp(0, 2),
          );
        }
      },
    ],
  );
}

/// Discover the public glass controls once instead of their nested Material
/// widgets. Actions still use real pointer events, never invoke callbacks.
class GalleryControlAdapter extends UiControlAdapter {
  const GalleryControlAdapter();

  @override
  UiControl? discover(Element element, String selector) {
    final widget = element.widget;
    if (widget.key is! ValueKey) return null;
    String? kind;
    var enabled = true;
    var state = '';
    if (widget is LiquidGlassButton) {
      kind = 'tap';
      enabled = widget.onPressed != null;
    } else if (widget is LiquidGlassIconButton) {
      kind = 'tap';
      enabled = widget.onPressed != null;
      state = widget.tooltip;
    } else if (widget is LiquidGlassSwitch) {
      kind = 'tap';
      enabled = widget.onChanged != null;
      state = '${widget.value}';
    } else if (widget is LiquidGlassSlider) {
      kind = 'slide';
      enabled = widget.onChanged != null;
      state = '${widget.value}';
    } else if (widget is LiquidGlassSegmentedControl<int>) {
      kind = 'tap';
      state = '${widget.selected}';
    } else if (widget is LiquidGlassNavigationBar) {
      kind = 'tap';
      state = '${widget.selectedIndex}';
    } else if (widget is ListView || widget is SingleChildScrollView) {
      kind = 'scroll';
    }
    if (kind == null) return null;
    return UiControl(
      selector: selector,
      finder: find.byElementPredicate(
        (candidate) => identical(candidate, element),
      ),
      kind: kind,
      enabled: enabled,
      state: state,
    );
  }

  @override
  Future<void> perform(
    WidgetTester tester,
    UiControl control,
    UiAction action,
  ) async {
    final widget = tester.widget(control.finder);
    if ((widget is ListView || widget is SingleChildScrollView) &&
        action.value != null) {
      // Scripted flows reveal real controls by scrolling the actual gallery.
      final scrollable = find
          .descendant(of: control.finder, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(action.value!)),
        250,
        scrollable: scrollable,
      );
    } else if (widget is ListView || widget is SingleChildScrollView) {
      await tester.drag(control.finder, const Offset(0, -250));
    } else if (widget is LiquidGlassSlider) {
      final slider = find.descendant(
        of: control.finder,
        matching: find.byType(Slider),
      );
      await tester.drag(slider, const Offset(80, 0));
    } else if (widget is LiquidGlassSegmentedControl<int> ||
        widget is LiquidGlassNavigationBar) {
      final count = widget is LiquidGlassNavigationBar
          ? widget.items.length
          : (widget as LiquidGlassSegmentedControl<int>).segments.length;
      final index = int.parse(action.value ?? '2').clamp(0, count - 1);
      final rect = tester.getRect(
        widget is LiquidGlassNavigationBar
            ? find.byKey(const ValueKey('android-glass-surface'))
            : control.finder,
      );
      await tester.tapAt(
        Offset(rect.left + rect.width * (index + 0.5) / count, rect.center.dy),
      );
    } else {
      await tester.tap(control.finder);
    }
  }
}

const gallerySmokeActions = [
  UiAction(target: 'key:save-collection', kind: 'tap'),
  UiAction(target: 'key:favorite-button', kind: 'tap', count: 5),
  UiAction(target: 'key:expand-controls', kind: 'tap'),
  UiAction(target: 'key:collapse-controls', kind: 'tap'),
  UiAction(target: 'key:activity-selector', kind: 'tap', value: '2'),
  UiAction(
    target: 'key:gallery-scroll',
    kind: 'scroll',
    value: 'volume-slider',
  ),
  UiAction(target: 'key:volume-slider', kind: 'slide'),
  UiAction(
    target: 'key:gallery-scroll',
    kind: 'scroll',
    value: 'clear-variant',
  ),
  UiAction(target: 'key:clear-variant', kind: 'tap', count: 2),
  UiAction(target: 'key:gallery-scroll', kind: 'scroll', value: 'blur-slider'),
  UiAction(target: 'key:blur-slider', kind: 'slide'),
  UiAction(target: 'key:gallery-navigation', kind: 'tap', value: '2'),
  UiAction(target: 'key:theme-toggle', kind: 'tap', count: 2),
  UiAction(target: 'key:open-blending', kind: 'tap'),
  UiAction(target: 'key:blend-add', kind: 'tap', count: 2),
  UiAction(target: 'key:blend-remove', kind: 'tap'),
  UiAction(
    target: 'key:blend-dialog-scroll',
    kind: 'scroll',
    value: 'close-blending',
  ),
  UiAction(target: 'key:close-blending', kind: 'tap'),
];
