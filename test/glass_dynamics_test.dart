import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: Center(child: child)),
  ),
);

Matrix4 deformation(WidgetTester tester, {Finder? within}) {
  final target = find.byKey(const ValueKey('liquid-dynamics-transform'));
  return tester
      .widget<Transform>(
        within == null
            ? target.first
            : find.descendant(of: within, matching: target).first,
      )
      .transform;
}

void main() {
  testWidgets('press deforms, cancel releases and a tap invokes exactly once', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        LiquidGlassButton(
          onPressed: () => calls++,
          child: const Text('Action'),
        ),
      ),
    );
    final originalSize = tester.getSize(find.byType(LiquidGlassButton));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Action')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(deformation(tester).entry(1, 1), lessThan(0.99));
    expect(tester.getSize(find.byType(LiquidGlassButton)), originalSize);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(deformation(tester), Matrix4.identity());
    expect(calls, 0);
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(deformation(tester), Matrix4.identity());
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'disabled controls, intensity zero and reduced motion stay still',
    (tester) async {
      for (final mode in ['disabled', 'zero', 'reduced']) {
        await tester.pumpWidget(
          host(
            LiquidGlassButton(
              onPressed: mode == 'disabled' ? null : () {},
              settings: LiquidGlassSettings(
                dynamicsIntensity: mode == 'zero' ? 0 : 1,
              ),
              child: const Text('Action'),
            ),
            reduced: mode == 'reduced',
          ),
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Action')),
        );
        await tester.pump(const Duration(milliseconds: 90));
        expect(deformation(tester), Matrix4.identity());
        await gesture.up();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets('enabling reduced motion during a press cancels deformation', (
    tester,
  ) async {
    const child = LiquidGlassDynamics(
      child: SizedBox(
        width: 120,
        height: 56,
        child: ColoredBox(color: Colors.blue),
      ),
    );
    await tester.pumpWidget(host(child));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LiquidGlassDynamics)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(deformation(tester), isNot(Matrix4.identity()));
    await tester.pumpWidget(host(child, reduced: true));
    expect(deformation(tester), Matrix4.identity());
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('dynamic frames retain the child build and paint', (
    tester,
  ) async {
    var builds = 0;
    var paints = 0;
    final child = Builder(
      builder: (_) {
        builds++;
        return RepaintBoundary(
          child: CustomPaint(
            painter: _PaintCounter(() => paints++),
            child: const SizedBox(width: 120, height: 56),
          ),
        );
      },
    );
    await tester.pumpWidget(
      host(LiquidGlassDynamics(trackDrag: true, child: child)),
    );
    final target = find.byType(LiquidGlassDynamics);
    final gesture = await tester.startGesture(tester.getCenter(target));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(2, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(builds, 1);
    expect(paints, 1);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('scrolling cancels button feedback without firing an action', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 240,
          height: 220,
          child: ListView(
            children: [
              LiquidGlassButton(
                onPressed: () => calls++,
                child: const Text('Action'),
              ),
              const SizedBox(height: 800),
            ],
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Action')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disabling or removing a pressed control stops its dynamics safely',
    (tester) async {
      final key = GlobalKey();
      Widget control(bool enabled) => LiquidGlassDynamics(
        key: key,
        enabled: enabled,
        child: const SizedBox(
          width: 120,
          height: 56,
          child: ColoredBox(color: Colors.blue),
        ),
      );
      await tester.pumpWidget(host(control(true)));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(LiquidGlassDynamics)),
      );
      await tester.pump(const Duration(milliseconds: 90));
      await tester.pumpWidget(host(control(false)));
      expect(deformation(tester), Matrix4.identity());
      await gesture.cancel();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

class _PaintCounter extends CustomPainter {
  _PaintCounter(this.count);
  final VoidCallback count;
  @override
  void paint(Canvas canvas, Size size) {
    count();
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.blue);
  }

  @override
  bool shouldRepaint(_PaintCounter oldDelegate) => false;
}
