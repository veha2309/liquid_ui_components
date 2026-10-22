import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

// The example is a separate package; exercise its actual app from this suite.
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';

void main() {
  testWidgets('Balanced is distinct from the blur-only Frosted option', (
    tester,
  ) async {
    await tester.pumpWidget(const GlassGallery(animateBackground: false));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Glass quality'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final menu = find.byType(DropdownButtonFormField<LiquidGlassRendering>);
    await Scrollable.ensureVisible(tester.element(menu), alignment: 0.5);
    await tester.pumpAndSettle();
    // Choose through the UI so the gallery's mode mapping is exercised.
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balanced').last);
    await tester.pumpAndSettle();
    expect(
      LiquidGlassTheme.of(
        tester.element(find.byType(LiquidGlassNavigationBar)),
      ).rendering,
      LiquidGlassRendering.balanced,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('blending demo opens directly from the app bar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const GlassGallery(animateBackground: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blending'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Liquid blending'),
      ),
      findsOneWidget,
    );
    final lens = find.descendant(
      of: find.byType(Dialog),
      matching: find.byKey(const ValueKey('blend-drag-0')),
    );
    await tester.drag(lens, const Offset(30, 30));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Close demo'));
    await tester.tap(find.text('Close demo'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.text('Save collection'));
    await tester.pumpAndSettle();
    expect(find.text('Collection saved'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Save collection'), findsOneWidget);
    expect(find.text('Saved to your collection'), findsNothing);
  });

  testWidgets('gallery works at phone size in light and dark themes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (const bool.fromEnvironment('CAPTURE_GLASS_GALLERY')) {
      await tester.runAsync(() async {
        final sdkRoot = Platform.environment['FLUTTER_ROOT']!;
        for (final font in {
          'Roboto': 'roboto-regular.ttf',
          'MaterialIcons': 'materialicons-regular.otf',
        }.entries) {
          final bytes = await File(
            '$sdkRoot/bin/cache/artifacts/material_fonts/${font.value}',
          ).readAsBytes();
          await (FontLoader(
            font.key,
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        }
      });
    }
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: const GlassGallery(animateBackground: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final navigation = tester.element(find.byType(LiquidGlassNavigationBar));
    expect(
      LiquidGlassTheme.of(navigation).rendering,
      LiquidGlassRendering.automatic,
    );

    Future<void> capture(String name) async {
      if (!const bool.fromEnvironment('CAPTURE_GLASS_GALLERY')) return;
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/gallery').create(recursive: true);
        await File(
          'build/gallery/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('light');
    if (const bool.fromEnvironment('CAPTURE_GLASS_GALLERY')) {
      final press = await tester.startGesture(
        tester.getCenter(find.text('Save collection')),
      );
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await capture('press-${i.toString().padLeft(2, '0')}');
      }
      await press.cancel();
      for (var i = 0; i < 18; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await capture('release-${i.toString().padLeft(2, '0')}');
      }
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Save collection'));
    await tester.pumpAndSettle();
    expect(find.text('Saved to your collection'), findsOneWidget);
    await capture('toast');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Saved to your collection'), findsNothing);
    await tester.tapAt(tester.getCenter(find.text('Quick controls')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Quick controls'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Quick controls'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(find.text('Play music'), findsOneWidget);
    await tester.tap(find.text('Play music'));
    await tester.pumpAndSettle();
    expect(find.text('Pause playback'), findsOneWidget);
    await tester.tap(find.byTooltip('Collapse controls'));
    await tester.pumpAndSettle();
    expect(find.text('Quick controls'), findsOneWidget);
    expect(find.text('Pause playback'), findsNothing);
    await tester.tap(find.byTooltip('Stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('Showing weekly activity'), findsOneWidget);
    await tester.tap(find.byTooltip('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Now playing'), findsOneWidget);
    await tester.tap(find.byTooltip('Dark theme'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture('dark');
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('android-glass-surface')))
          .height,
      48,
    );
    await capture('compact-navigation');
    // Icons are optical backdrop content; the bar owns pointer handling.
    await tester.tapAt(tester.getCenter(find.byIcon(Icons.widgets_outlined)));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('android-glass-surface')))
          .height,
      62,
    );
    await capture('expanded-navigation');
    await tester.tap(find.text('Reduce transparency'));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
    await capture('settings');
  });
}
