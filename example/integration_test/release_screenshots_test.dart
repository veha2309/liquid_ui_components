import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_ui_components/liquid_glass.dart';
import 'package:liquid_ui_components_example/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture v0.3.0 gallery on Android', (tester) async {
    await tester.pumpWidget(const GlassGallery(animateBackground: false));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    await capture('controls-light');
    await tester.tapAt(tester.getCenter(find.text('Quick controls')));
    await capture('morph-expanded');
    await tester.tap(find.byTooltip('Collapse controls'));
    await tester.pumpAndSettle();
    final slider = find.byType(LiquidGlassSlider).first;
    await Scrollable.ensureVisible(tester.element(slider), alignment: 0.5);
    await capture('slider-and-settings');
    await tester.tap(find.byKey(const ValueKey('open-blending')));
    await capture('blending');
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('close-blending'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('close-blending')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Alerts & prompts'),
      450,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('gallery-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Alerts & prompts')),
      alignment: 0.1,
    );
    await capture('alerts-and-panels');
    await tester.tap(find.text('New collection'));
    await capture('confirmation');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Collection details'));
    await capture('bottom-panel');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Dark theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New collection'));
    await capture('confirmation-dark');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final list = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('gallery-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    list.position.jumpTo(0);
    await capture('controls-dark');
    expect(tester.takeException(), isNull);
  });
}
