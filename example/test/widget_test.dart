import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components_example/main.dart';

void main() {
  testWidgets('gallery opens and changes selection', (tester) async {
    await tester.pumpWidget(const GlassGallery(animateBackground: false));
    await tester.pumpAndSettle();
    expect(find.text('Liquid Glass Studio'), findsOneWidget);
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('Showing weekly activity'), findsOneWidget);
  });
}
