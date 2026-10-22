import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() {
  Widget host({
    bool expanded = false,
    bool reduceMotion = false,
    double width = 400,
    bool sharedTitle = false,
    TextDirection textDirection = TextDirection.ltr,
    Widget? panel,
    VoidCallback? onClose,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Directionality(
                  textDirection: textDirection,
                  child: LiquidGlassMorph(
                    expanded: expanded,
                    collapsedSize: const Size(100, 56),
                    expandedSize: const Size(300, 220),
                    sharedChild: sharedTitle
                        ? const Text(
                            'Title',
                            key: ValueKey('shared-title'),
                            style: TextStyle(fontSize: 10),
                          )
                        : null,
                    collapsedSharedAlignment: AlignmentDirectional.centerEnd,
                    collapsedSharedPadding: const EdgeInsetsDirectional.only(
                      end: 8,
                    ),
                    expandedSharedPadding: const EdgeInsetsDirectional.only(
                      start: 24,
                      top: 40,
                    ),
                    settings: const LiquidGlassSettings(
                      rendering: LiquidGlassRendering.frosted,
                    ),
                    collapsedChild: TextButton(
                      onPressed: () {},
                      child: const Text('Open'),
                    ),
                    expandedChild:
                        panel ??
                        Column(
                          children: [
                            TextButton(
                              onPressed: onClose ?? () {},
                              child: const Text('Close'),
                            ),
                            const Text('Panel content'),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Size lensSize(WidgetTester tester) =>
      tester.getSize(find.byType(LiquidGlassSurface));

  testWidgets('panel accepts actions before the spring settling tail ends', (
    tester,
  ) async {
    var closed = 0;
    void close() => closed++;
    await tester.pumpWidget(host(onClose: close));
    await tester.pumpWidget(host(expanded: true, onClose: close));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Close'));
    expect(closed, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('morph retains the painted panel while its outline changes', (
    tester,
  ) async {
    var paints = 0;
    final panel = CustomPaint(painter: _CountPaint(() => paints++));
    await tester.pumpWidget(host(panel: panel));
    await tester.pumpWidget(host(expanded: true, panel: panel));
    for (var i = 0; i < 35; i++) {
      await tester.pump(const Duration(milliseconds: 8));
    }
    // Changing opacity, position and contour should composite cached content.
    expect(paints, 1, reason: 'Panel painted $paints times');
    await tester.pumpAndSettle();
  });

  testWidgets(
    'shared title travels once without fading, including reversal and RTL',
    (tester) async {
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          host(sharedTitle: true, textDirection: direction),
        );
        await tester.pumpAndSettle();
        final title = find.byKey(const ValueKey('shared-title'));
        final originalElement = tester.element(title);
        final start = tester.getTopLeft(title);
        await tester.pumpWidget(
          host(sharedTitle: true, expanded: true, textDirection: direction),
        );
        await tester.pump(const Duration(milliseconds: 100));
        final middle = tester.getTopLeft(title);
        expect(title, findsOneWidget);
        expect(tester.element(title), same(originalElement));
        expect(
          find.ancestor(of: title, matching: find.byType(Opacity)),
          findsNothing,
        );
        expect(middle, isNot(start));
        await tester.pumpWidget(
          host(sharedTitle: true, textDirection: direction),
        );
        expect(tester.getTopLeft(title), middle);
        await tester.pump(const Duration(milliseconds: 1));
        final braking = tester.getTopLeft(title);
        expect((braking - middle).dx * (middle - start).dx, greaterThan(0));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(title), start);
        await tester.pumpWidget(
          host(sharedTitle: true, expanded: true, textDirection: direction),
        );
        await tester.pumpAndSettle();
        final lens = tester.getRect(find.byType(LiquidGlassSurface));
        expect(tester.getTopLeft(title).dy, closeTo(lens.top + 40, 0.01));
        if (direction == TextDirection.ltr) {
          expect(tester.getTopLeft(title).dx, closeTo(lens.left + 24, 0.01));
        } else {
          expect(
            tester.getBottomRight(title).dx,
            closeTo(lens.right - 24, 0.01),
          );
        }
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('default expansion reaches the panel promptly', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpWidget(host(expanded: true));
    await tester.pump(const Duration(milliseconds: 320));
    expect(lensSize(tester).width, greaterThan(290));
    await tester.pumpAndSettle();
  });

  testWidgets('one lens morphs geometry and material, then collapses', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(lensSize(tester), const Size(100, 56));
    await tester.pumpWidget(host(expanded: true));
    await tester.pump(const Duration(milliseconds: 210));
    final midway = lensSize(tester);
    expect(midway.width, greaterThan(100));
    expect(midway.width, lessThan(300));
    expect(find.byType(LiquidGlassSurface), findsOneWidget);
    final surface = tester.widget<LiquidGlassSurface>(
      find.byType(LiquidGlassSurface),
    );
    expect(surface.settings!.depth, greaterThan(0.045));
    expect(surface.settings!.depth, lessThan(0.045 * 1.35));
    await tester.pumpAndSettle();
    expect(lensSize(tester), const Size(300, 220));
    expect(find.text('Open'), findsNothing);
    expect(find.text('Panel content'), findsOneWidget);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(lensSize(tester), const Size(100, 56));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reverses an unfinished morph without jumping', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpWidget(host(expanded: true));
    await tester.pump(const Duration(milliseconds: 170));
    final before = lensSize(tester);
    await tester.pumpWidget(host());
    expect(lensSize(tester).width, closeTo(before.width, 0.000001));
    expect(lensSize(tester).height, closeTo(before.height, 0.000001));
    // Retargeting remains continuous while the faster spring brakes the lens.
    await tester.pump(const Duration(milliseconds: 16));
    expect((lensSize(tester).width - before.width).abs(), lessThan(25));
    await tester.pumpAndSettle();
    expect(lensSize(tester), const Size(100, 56));
  });

  testWidgets('content overlaps during the morph without an empty midpoint', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpWidget(host(expanded: true));
    await tester.pump(const Duration(milliseconds: 80));
    final layers = tester.widgetList<Opacity>(
      find.descendant(
        of: find.byType(LiquidGlassMorph),
        matching: find.byType(Opacity),
      ),
    );
    expect(layers, hasLength(2));
    expect(layers.every((layer) => layer.opacity > 0), isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion settles immediately, including mid-transition', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpWidget(host(expanded: true));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(host(expanded: true, reduceMotion: true));
    expect(lensSize(tester), const Size(300, 220));
    await tester.pump(const Duration(milliseconds: 16));
    expect(lensSize(tester), const Size(300, 220));
    await tester.pumpWidget(host(reduceMotion: true));
    expect(lensSize(tester), const Size(100, 56));
  });

  testWidgets('fits a narrow parent and starts expanded without animating', (
    tester,
  ) async {
    await tester.pumpWidget(host(expanded: true, width: 180));
    expect(lensSize(tester), const Size(180, 220));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only sufficiently revealed target content exposes actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    bool exposed(String label) {
      var found = false;
      void visit(SemanticsNode node) {
        if (node.getSemanticsData().label == label) found = true;
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(tester.semantics.find(find.byType(Scaffold)));
      return found;
    }

    await tester.pumpWidget(host());
    expect(exposed('Open'), isTrue);
    expect(exposed('Close'), isFalse);
    await tester.pumpWidget(host(expanded: true));
    await tester.pump(const Duration(milliseconds: 80));
    expect(exposed('Open'), isFalse);
    expect(exposed('Close'), isFalse);
    await tester.pumpAndSettle();
    expect(exposed('Close'), isTrue);
    expect(exposed('Open'), isFalse);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(exposed('Open'), isTrue);
    expect(exposed('Close'), isFalse);
    semantics.dispose();
  });

  testWidgets('moving contour bows between exact endpoint outlines', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpWidget(host(expanded: true));
    await tester.pump(const Duration(milliseconds: 210));
    final surface = tester.widget<LiquidGlassSurface>(
      find.byType(LiquidGlassSurface),
    );
    final rect = Offset.zero & lensSize(tester);
    final outline = surface.shape!.getOuterPath(rect);
    final box = Path()..addRRect(surface.borderRadius.toRRect(rect));
    var changed = 0;
    for (var x = 0.0; x < rect.width; x += 4) {
      for (var y = 0.0; y < rect.height; y += 4) {
        if (outline.contains(Offset(x, y)) != box.contains(Offset(x, y))) {
          changed++;
        }
      }
    }
    expect(changed, greaterThan(20));
    expect(outline.computeMetrics().length, 1);
    expect(outline.getBounds().width, closeTo(rect.width, 0.1));
    await tester.pumpAndSettle();
    final settled = tester.widget<LiquidGlassSurface>(
      find.byType(LiquidGlassSurface),
    );
    expect(
      settled.shape!
          .getOuterPath(Offset.zero & lensSize(tester))
          .contains(const Offset(30, 30)),
      isTrue,
    );
  });

  testWidgets('render fluid morph progression', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_GLASS_MORPH')) return;
    const sdk = String.fromEnvironment('FLUTTER_SDK');
    if (sdk.isNotEmpty) {
      await tester.runAsync(() async {
        for (final font in {
          'MaterialIcons': 'materialicons-regular.otf',
          'Roboto': 'roboto-regular.ttf',
        }.entries) {
          final bytes = await File(
            '$sdk/bin/cache/artifacts/material_fonts/${font.value}',
          ).readAsBytes();
          await (FontLoader(
            font.key,
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        }
      });
    }
    final boundaryKey = GlobalKey();
    final frames = <ui.Image>[];
    Widget scene(bool expanded) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: Container(
              width: 360,
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff6a88ee),
                    Color(0xffeec0ce),
                    Color(0xffdc955f),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topLeft,
                child: LiquidGlassMorph(
                  expanded: expanded,
                  collapsedSize: const Size(160, 56),
                  expandedSize: const Size(320, 216),
                  sharedChild: const Text(
                    'Quick controls',
                    maxLines: 1,
                    style: TextStyle(fontSize: 14, fontFamily: 'Roboto'),
                  ),
                  collapsedSharedAlignment: AlignmentDirectional.centerStart,
                  collapsedSharedPadding: const EdgeInsetsDirectional.fromSTEB(
                    44,
                    0,
                    8,
                    0,
                  ),
                  expandedSharedPadding: const EdgeInsetsDirectional.fromSTEB(
                    16,
                    30,
                    64,
                    0,
                  ),
                  settings: const LiquidGlassSettings(
                    rendering: LiquidGlassRendering.frosted,
                  ),
                  collapsedChild: const Padding(
                    padding: EdgeInsetsDirectional.only(start: 12),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Icon(Icons.tune),
                    ),
                  ),
                  expandedChild: const Column(
                    children: [
                      SizedBox(height: 80),
                      Icon(Icons.play_arrow),
                      SizedBox(height: 32),
                      Icon(Icons.volume_up),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> capture() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      frames.add(await boundary.toImage());
    }

    await tester.pumpWidget(scene(false));
    await tester.runAsync(capture);
    await tester.pumpWidget(scene(true));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(capture);
    }
    await tester.pumpWidget(scene(false));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(capture);
    }
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final selected = [0, 3, 6, 9, 15, 60];
      for (var i = 0; i < selected.length; i++) {
        canvas.drawImage(frames[selected[i]], Offset(i * 360.0, 0), Paint());
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(360 * selected.length, 280);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/morph').create(recursive: true);
      await File(
        'build/morph/progression.png',
      ).writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      for (var i = 0; i < frames.length; i++) {
        final png = await frames[i].toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/morph/frame_${i.toString().padLeft(3, '0')}.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        frames[i].dispose();
      }
    });
  });
}

class _CountPaint extends CustomPainter {
  _CountPaint(this.onPaint);
  final VoidCallback onPaint;
  @override
  void paint(Canvas canvas, Size size) {
    onPaint();
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.blue);
  }

  @override
  bool shouldRepaint(_CountPaint oldDelegate) => false;
}
