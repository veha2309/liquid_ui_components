import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Real painted detail behind the controls gives blur and refraction something
/// to sample. Only the artwork is cached; the glass still reads the live scene.
class GalleryBackdrop extends StatefulWidget {
  const GalleryBackdrop({
    super.key,
    required this.dark,
    required this.child,
    this.animated = true,
  });

  final bool dark;
  final Widget child;
  final bool animated;

  @override
  State<GalleryBackdrop> createState() => _GalleryBackdropState();
}

class _GalleryBackdropState extends State<GalleryBackdrop>
    with WidgetsBindingObserver {
  final _phase = ValueNotifier(0.0);
  final _elapsed = Stopwatch();
  Timer? _timer;
  bool _motionAllowed = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionAllowed =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _syncMotion();
  }

  @override
  void didUpdateWidget(GalleryBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    if (!widget.animated || !_motionAllowed || !_foreground) {
      _timer?.cancel();
      _timer = null;
      _elapsed.stop();
      return;
    }
    if (_timer != null) return;
    _elapsed.start();
    // A slow ambience needs only 25 updates/sec, not a full-rate UI ticker.
    // Only this painter is invalidated; controls and static art stay cached.
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      _phase.value = (_elapsed.elapsedMilliseconds % 24000) / 24000;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(painter: _BackdropPainter(dark: widget.dark)),
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ActivityPainter(dark: widget.dark, phase: _phase),
              ),
            ),
          ),
        ),
      ),
      widget.child,
    ],
  );
}

class _ActivityPainter extends CustomPainter {
  _ActivityPainter({required this.dark, required this.phase})
    : super(repaint: phase);

  final bool dark;
  final ValueNotifier<double> phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isFinite || size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final scale = size.width / 390;
    canvas.scale(scale);
    final height = size.height / scale;
    final time = phase.value * math.pi * 2;
    const palette = [
      Color(0xff779dff),
      Color(0xffffb15e),
      Color(0xffff8dbb),
      Color(0xff43cbb7),
    ];
    // Drifting translucent tiles give the glass large moving color boundaries.
    for (var tile = 0; tile < 6; tile++) {
      final x = 35 + (tile * 79 % 330) + math.sin(time + tile * 1.4) * 32;
      final y = 165 + tile * (height - 165) / 6 + math.cos(time + tile) * 34;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(time + tile) * 0.35);
      final rect = Rect.fromCenter(center: Offset.zero, width: 78, height: 54);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        Paint()..color = palette[tile % 4].withValues(alpha: dark ? 0.36 : 0.5),
      );
      canvas.drawLine(
        const Offset(-23, -8),
        const Offset(23, -8),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        const Offset(-23, 4),
        const Offset(8, 4),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 2,
      );
      canvas.restore();
    }
    // Bubbles and short light trails cross controls at different speeds.
    for (var particle = 0; particle < 20; particle++) {
      final x = (particle * 71 + phase.value * 90) % 430 - 20;
      final y =
          height +
          30 -
          ((particle * 137 + phase.value * (height + 80)) % (height + 80));
      if (y < 140) continue;
      final radius = 3.0 + particle % 4 * 3;
      final color = palette[particle % 4].withValues(alpha: dark ? 0.5 : 0.6);
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = color);
      canvas.drawCircle(
        Offset(x, y),
        radius + 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.4),
      );
      if (particle.isEven) {
        canvas.drawLine(
          Offset(x + radius + 9, y),
          Offset(x + radius + 31, y),
          Paint()
            ..strokeWidth = 2
            ..color = color,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ActivityPainter oldDelegate) =>
      oldDelegate.dark != dark || oldDelegate.phase != phase;
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isFinite || size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final scale = size.width / 390;
    canvas.scale(scale);
    final height = size.height / scale;
    final bounds = Rect.fromLTWH(0, 0, 390, height);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xff12233f), Color(0xff302449), Color(0xff103b42)]
              : const [Color(0xffdce8ff), Color(0xfff1d5ef), Color(0xffc6eee5)],
        ).createShader(bounds),
    );

    void glow(Offset center, double radius, Color color) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: dark ? 0.65 : 0.8),
              color.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    glow(const Offset(360, 160), 200, const Color(0xffad86ff));
    glow(Offset(15, height * 0.53), 210, const Color(0xffff8fbd));
    glow(Offset(370, height * 0.82), 220, const Color(0xff49cbbb));

    // Color tiles of different sizes place sharp hue changes under each row.
    for (var row = 0; row < (height / 170).ceil() + 1; row++) {
      final y = 175.0 + row * 170;
      final x = row.isEven ? 240.0 : -35.0;
      final rect = Rect.fromLTWH(x, y, 190, 118);
      final colors = row.isEven
          ? const [Color(0xfff9b15a), Color(0xffef8fae)]
          : const [Color(0xff72a6ed), Color(0xff8bd5cc)];
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(row.isEven ? -0.22 : 0.18);
      final localRect = Rect.fromCenter(
        center: Offset.zero,
        width: rect.width,
        height: rect.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(localRect, const Radius.circular(26)),
        Paint()
          ..shader = LinearGradient(
            colors: colors
                .map((color) => color.withValues(alpha: dark ? 0.34 : 0.55))
                .toList(),
          ).createShader(localRect),
      );
      for (var stripe = 0; stripe < 5; stripe++) {
        canvas.drawLine(
          Offset(-68 + stripe * 24, -42),
          Offset(-68 + stripe * 24, 42),
          Paint()
            ..color = Colors.white.withValues(alpha: dark ? 0.14 : 0.35)
            ..strokeWidth = 2,
        );
      }
      canvas.restore();
    }

    final ink = dark ? const Color(0xffc5e1ff) : const Color(0xff465b89);
    // The small dots and grid make even low blur settings visible.
    final gridPaint = Paint()
      ..color = ink.withValues(alpha: dark ? 0.10 : 0.08)
      ..strokeWidth = 0.6;
    for (var x = 14.0; x < 390; x += 24) {
      canvas.drawLine(Offset(x, 140), Offset(x, height), gridPaint);
      for (var y = 152.0; y < height; y += 24) {
        canvas.drawCircle(
          Offset(x, y),
          1.1,
          Paint()..color = ink.withValues(alpha: 0.20),
        );
      }
    }
    for (var y = 152.0; y < height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(390, y), gridPaint);
    }

    // Contours, rings and alternating bars give the bevel long edges to bend.
    for (var line = 0; line < 7; line++) {
      final path = Path();
      for (var x = -20.0; x <= 410; x += 4) {
        final y = height * 0.58 + line * 9 + math.sin(x / 65) * 32;
        if (x == -20) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = ink.withValues(alpha: 0.18),
      );
    }
    final ringCenter = Offset(325, height * 0.88);
    for (var radius = 36.0; radius <= 108; radius += 18) {
      canvas.drawCircle(
        ringCenter,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ink.withValues(alpha: 0.20),
      );
    }
    for (var bar = 0; bar < 12; bar++) {
      canvas.drawRect(
        Rect.fromLTWH(26 + bar * 7, height - 74, bar.isEven ? 3 : 1, 28),
        Paint()..color = ink.withValues(alpha: 0.24),
      );
    }
    final label = TextPainter(
      text: TextSpan(
        text: 'GLASS / MATERIAL STUDY',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
          color: ink.withValues(alpha: 0.35),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(26, height - 32));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => oldDelegate.dark != dark;
}
