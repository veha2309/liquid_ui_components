part of 'liquid_glass_surface.dart';

class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({
    required this.radius,
    required this.shape,
    required this.width,
    required this.direction,
    required this.intensity,
    required this.ambient,
    required this.spread,
  });
  final BorderRadius radius;
  final OutlinedBorder? shape;
  final double width;
  final double direction;
  final double intensity;
  final double ambient;
  final double spread;

  Path _path(Rect rect) =>
      shape?.getOuterPath(rect) ?? (Path()..addRRect(radius.toRRect(rect)));

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0 || size.isEmpty) return;
    final rim = width.clamp(0.0, size.shortestSide / 4);
    final rect = Offset.zero & size;
    final radians = (direction % 360) * math.pi / 180;
    final light = Alignment(math.cos(radians), -math.sin(radians));
    final highlight = (intensity * 0.6 + ambient * 0.08).clamp(0.0, 0.9);
    final gradient = LinearGradient(
      begin: light,
      end: -light,
      colors: [
        Colors.white.withValues(alpha: highlight),
        Colors.white.withValues(alpha: (ambient * 0.12).clamp(0.0, 0.5)),
        Colors.black.withValues(
          alpha: (0.04 + ambient * 0.04).clamp(0.0, 0.24),
        ),
        Colors.white.withValues(alpha: highlight * 0.35),
      ],
      stops: [0, 0.18 + spread * 0.38, 0.76, 1],
    );
    canvas.drawPath(
      _path(rect.deflate(rim / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rim
        ..shader = gradient.createShader(rect),
    );
    // A quieter inner rim defines thickness without another blur or saveLayer.
    if (size.shortestSide > rim * 4) {
      canvas.drawPath(
        _path(rect.deflate(rim * 1.6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim * 0.45
          ..color = Colors.white.withValues(
            alpha: (ambient * 0.12).clamp(0.0, 0.3),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_GlassRimPainter oldDelegate) =>
      radius != oldDelegate.radius ||
      shape != oldDelegate.shape ||
      width != oldDelegate.width ||
      direction != oldDelegate.direction ||
      intensity != oldDelegate.intensity ||
      ambient != oldDelegate.ambient ||
      spread != oldDelegate.spread;
}
