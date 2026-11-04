import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

Widget host({
  required ValueChanged<BuildContext> show,
  MediaQueryData media = const MediaQueryData(),
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: LiquidGlassTheme(
    settings: const LiquidGlassSettings(
      rendering: LiquidGlassRendering.frosted,
      tintColor: Colors.purple,
    ),
    child: MediaQuery(
      data: media,
      child: Directionality(
        textDirection: direction,
        child: Scaffold(
          bottomNavigationBar: const SizedBox(
            key: ValueKey('navigation'),
            height: 96,
          ),
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => show(context),
                child: const Text('Show toast'),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('Undo persists and dismisses once with the action reason', (
    tester,
  ) async {
    var undone = 0;
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    await tester.pumpWidget(
      host(
        show: (context) {
          controller = LiquidGlassToast.show(
            context,
            message: 'Deleted',
            duration: const Duration(milliseconds: 100),
            action: SnackBarAction(label: 'Undo', onPressed: () => undone++),
          );
        },
      ),
    );
    await tester.tap(find.text('Show toast'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(await controller.closed, SnackBarClosedReason.action);
  });

  testWidgets(
    'custom content, fixed layout, queued messages and callbacks work',
    (tester) async {
      var visible = 0;
      await tester.pumpWidget(
        host(
          show: (context) {
            LiquidGlassToast.show(
              context,
              content: const Text('First queued'),
              behavior: SnackBarBehavior.fixed,
              duration: const Duration(seconds: 1),
              onVisible: () => visible++,
            );
            LiquidGlassToast.show(
              context,
              message: 'Second queued',
              replaceCurrent: false,
            );
          },
        ),
      );
      await tester.tap(find.text('Show toast'));
      await tester.pumpAndSettle();
      expect(visible, 1);
      expect(
        tester.widget<SnackBar>(find.byType(SnackBar)).behavior,
        SnackBarBehavior.fixed,
      );
      expect(find.text('Second queued'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Second queued'), findsOneWidget);
    },
  );

  testWidgets('long Undo action wraps at large text and can time out', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    await tester.pumpWidget(
      host(
        media: const MediaQueryData(textScaler: TextScaler.linear(2)),
        direction: TextDirection.rtl,
        show: (context) {
          controller = LiquidGlassToast.show(
            context,
            message: 'Deleted item',
            width: 280,
            persist: false,
            duration: const Duration(seconds: 1),
            action: SnackBarAction(label: 'Restore item', onPressed: () {}),
          );
        },
      ),
    );
    await tester.tap(find.text('Show toast'));
    await tester.pumpAndSettle();
    expect(find.text('Restore item'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(await controller.closed, SnackBarClosedReason.timeout);
  });

  testWidgets('toast inherits glass settings and floats above navigation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        show: (context) =>
            LiquidGlassToast.show(context, message: 'Collection saved'),
      ),
    );
    await tester.tap(find.text('Show toast'));
    await tester.pumpAndSettle();
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.behavior, SnackBarBehavior.floating);
    expect(snack.backgroundColor, Colors.transparent);
    expect(snack.elevation, 0);
    final surface = tester.widget<LiquidGlassSurface>(
      find.byType(LiquidGlassSurface),
    );
    expect(surface.settings!.tintColor, Colors.purple);
    expect(surface.settings!.rendering, LiquidGlassRendering.frosted);
    expect(
      tester.getRect(find.byType(SnackBar)).bottom,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const ValueKey('navigation'))).dy,
      ),
    );
    expect(find.bySemanticsLabel('Collection saved'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('toast times out and completes its native controller', (
    tester,
  ) async {
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    await tester.pumpWidget(
      host(
        show: (context) {
          controller = LiquidGlassToast.show(
            context,
            message: 'Saved',
            duration: const Duration(seconds: 1),
          );
        },
      ),
    );
    await tester.tap(find.text('Show toast'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    expect(await controller.closed, SnackBarClosedReason.timeout);
  });

  testWidgets('close button dismisses the toast', (tester) async {
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    await tester.pumpWidget(
      host(
        show: (context) {
          controller = LiquidGlassToast.show(context, message: 'Saved');
        },
      ),
    );
    await tester.tap(find.text('Show toast'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    expect(await controller.closed, SnackBarClosedReason.dismiss);
  });

  testWidgets('swipe dismissal uses native snack bar handling', (tester) async {
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    await tester.pumpWidget(
      host(
        show: (context) {
          controller = LiquidGlassToast.show(
            context,
            message: 'Saved',
            showCloseButton: false,
          );
        },
      ),
    );
    await tester.tap(find.text('Show toast'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close'), findsNothing);
    await tester.drag(find.byType(SnackBar), const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
    expect(await controller.closed, SnackBarClosedReason.swipe);
  });

  testWidgets('rapid messages replace pending toasts instead of backing up', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(
      host(
        show: (context) =>
            LiquidGlassToast.show(context, message: 'Saved ${++count}'),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Show toast'));
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();
    expect(find.text('Saved 1'), findsNothing);
    expect(find.text('Saved 2'), findsNothing);
    expect(find.text('Saved 3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('narrow RTL, large text and reduced motion remain accessible', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      host(
        direction: TextDirection.rtl,
        media: const MediaQueryData(
          disableAnimations: true,
          highContrast: true,
          textScaler: TextScaler.linear(2),
        ),
        show: (context) => LiquidGlassToast.show(
          context,
          message: 'Files saved. Available offline.',
        ),
      ),
    );
    await tester.tap(find.text('Show toast'));
    await tester.pump();
    expect(find.text('Files saved. Available offline.'), findsOneWidget);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).animation!.value, 1);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.getSize(find.byType(SnackBar)).width, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });
}
