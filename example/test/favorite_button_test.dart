import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components_example/favorite_button.dart';

void main() {
  Widget app({bool reducedMotion = false}) => MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: const Center(child: FavoriteGlassButton()),
      ),
    ),
  );

  testWidgets('favorite bursts, toggles and removes its overlay', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(5));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion changes state without a heart burst', (
    tester,
  ) async {
    await tester.pumpWidget(app(reducedMotion: true));
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });
}
