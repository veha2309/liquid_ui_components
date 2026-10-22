import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_ui_components_example/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'live backdrop can pause while glass selector stays interactive',
    (tester) async {
      await tester.pumpWidget(const GlassGallery());
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byTooltip('Add to favorites'));
      await tester.pump(const Duration(milliseconds: 220));
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 60));
      await binding.takeScreenshot('glass-favorite-heart');
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Week'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Showing weekly activity'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await binding.takeScreenshot('glass-motion-selector');
      await tester.tap(find.byTooltip('Pause background'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Animate background'), findsOneWidget);
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.text('Showing monthly activity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
