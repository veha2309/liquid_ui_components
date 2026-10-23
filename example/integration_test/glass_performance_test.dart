import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_ui_components_example/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> measure(String name, Future<void> Function() action) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    final timings = <ui.FrameTiming>[];
    void collect(List<ui.FrameTiming> frames) => timings.addAll(frames);
    binding.addTimingsCallback(collect);
    await action();
    await Future<void>.delayed(const Duration(seconds: 1));
    binding.removeTimingsCallback(collect);
    final build =
        timings.map((f) => f.buildDuration.inMicroseconds / 1000).toList()
          ..sort();
    final raster =
        timings.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()
          ..sort();
    Map<String, Object> summary(List<double> values) => values.isEmpty
        ? {'samples': 0}
        : {
            'average_ms': values.reduce((a, b) => a + b) / values.length,
            'p90_ms': values[((values.length - 1) * 0.9).round()],
            'max_ms': values.last,
            'over_16_67_ms': values.where((v) => v > 16.67).length,
            'over_8_33_ms': values.where((v) => v > 8.33).length,
          };
    binding.reportData ??= {};
    binding.reportData![name] = {
      'frames': timings.length,
      'build': summary(build),
      'raster': summary(raster),
    };
  }

  testWidgets('measure warm glass scrolling and volume dragging', (
    tester,
  ) async {
    await tester.pumpWidget(const GlassGallery());
    await tester.pump(const Duration(milliseconds: 250));
    Future<void> morphCycles(int count) async {
      for (var i = 0; i < count; i++) {
        await tester.tapAt(tester.getCenter(find.text('Quick controls')));
        await tester.pump(const Duration(milliseconds: 650));
        await tester.tap(find.byTooltip('Collapse controls'));
        await tester.pump(const Duration(milliseconds: 650));
      }
    }

    // Separate control cost from the intentionally animated gallery backdrop.
    await tester.tap(find.byTooltip('Pause background'));
    await tester.pump(const Duration(seconds: 1));
    await morphCycles(2);
    await measure('morph_static_background', () => morphCycles(6));
    await tester.tap(find.byTooltip('Animate background'));
    await tester.pump(const Duration(milliseconds: 100));
    await measure('morph_live_background', () => morphCycles(6));
    final list = find.byType(ListView);
    // Warm shaders and the raster cache before recording either scenario.
    await tester.drag(list, const Offset(0, -250));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.drag(list, const Offset(0, 300));
    await tester.pump(const Duration(milliseconds: 250));
    await measure('scroll', () async {
      for (var i = 0; i < 4; i++) {
        await tester.timedDrag(
          list,
          const Offset(0, -350),
          const Duration(milliseconds: 600),
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.timedDrag(
          list,
          const Offset(0, 350),
          const Duration(milliseconds: 600),
        );
        await tester.pump(const Duration(milliseconds: 250));
      }
    });
    final slider = find.byType(Slider).first;
    await Scrollable.ensureVisible(tester.element(slider), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 250));
    await measure('volume', () async {
      for (var i = 0; i < 5; i++) {
        await tester.timedDrag(
          slider,
          const Offset(100, 0),
          const Duration(milliseconds: 400),
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.timedDrag(
          slider,
          const Offset(-100, 0),
          const Duration(milliseconds: 400),
        );
        await tester.pump(const Duration(milliseconds: 250));
      }
    });
  });
}
