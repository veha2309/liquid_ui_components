import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The example is a separate package; exercise its actual app from this suite.
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';

void main() {
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
    await tester.tap(find.text('Reduce transparency'));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
    await capture('settings');
  });
}
