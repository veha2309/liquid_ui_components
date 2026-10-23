part of 'liquid_glass_morph.dart';

class _MorphSharedLayout extends SingleChildLayoutDelegate {
  const _MorphSharedLayout({
    required this.progress,
    required this.small,
    required this.large,
    required this.startAlignment,
    required this.endAlignment,
    required this.startPadding,
    required this.endPadding,
  });

  final double progress;
  final Size small;
  final Size large;
  final Alignment startAlignment;
  final Alignment endAlignment;
  final EdgeInsets startPadding;
  final EdgeInsets endPadding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          math.max(
            0.0,
            math.min(
              small.width - startPadding.horizontal,
              large.width - endPadding.horizontal,
            ),
          ),
          math.max(
            0.0,
            math.min(
              small.height - startPadding.vertical,
              large.height - endPadding.vertical,
            ),
          ),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final start = startAlignment
        .inscribe(childSize, startPadding.deflateRect(Offset.zero & small))
        .topLeft;
    final end = endAlignment
        .inscribe(childSize, endPadding.deflateRect(Offset.zero & large))
        .topLeft;
    return Offset.lerp(start, end, progress)!;
  }

  @override
  bool shouldRelayout(_MorphSharedLayout oldDelegate) =>
      progress != oldDelegate.progress ||
      small != oldDelegate.small ||
      large != oldDelegate.large ||
      startAlignment != oldDelegate.startAlignment ||
      endAlignment != oldDelegate.endAlignment ||
      startPadding != oldDelegate.startPadding ||
      endPadding != oldDelegate.endPadding;
}

/// A continuous perimeter that swells from the source capsule into a rounded
/// droplet before the edges spread into the destination panel. All surface
/// layers use the same path; the children themselves remain undistorted.
class _FluidGlassBorder extends OutlinedBorder {
  _FluidGlassBorder({
    required this.borderRadius,
    required this.fullness,
    required this.direction,
    super.side,
    Map<Rect, Path>? paths,
  }) : _paths = paths ?? {};

  final BorderRadius borderRadius;
  final double fullness;
  final Alignment direction;
  final Map<Rect, Path> _paths;
  static final _unitCircle = List<Offset>.generate(64, (i) {
    final angle = i * 2 * math.pi / 64;
    return Offset(math.cos(angle), math.sin(angle));
  }, growable: false);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  _FluidGlassBorder copyWith({BorderSide? side}) => _FluidGlassBorder(
    borderRadius: borderRadius,
    fullness: fullness,
    direction: direction,
    side: side ?? this.side,
    paths: _paths,
  );

  @override
  ShapeBorder scale(double t) => _FluidGlassBorder(
    borderRadius: borderRadius * t,
    fullness: fullness,
    direction: direction,
    side: side.scale(t),
  );

  Path _path(Rect rect) => _paths.putIfAbsent(rect, () => _buildPath(rect));

  Path _buildPath(Rect rect) {
    if (rect.isEmpty) return Path();
    final rounded = borderRadius.toRRect(rect).scaleRadii();
    if (fullness < 0.00001) return Path()..addRRect(rounded);
    final hw = rect.width / 2;
    final hh = rect.height / 2;
    // The edge furthest from the source stays round longer, making a moving
    // liquid front rather than four corners changing radius simultaneously.
    final heading = Offset(-direction.x, -direction.y);
    final headingUnit = heading.distance > 0
        ? heading / heading.distance
        : const Offset(1, 0);
    const count = 64;
    final points = List<Offset>.generate(count, (i) {
      final dx = _unitCircle[i].dx;
      final dy = _unitCircle[i].dy;
      final ax = dx.abs();
      final ay = dy.abs();
      final radius = dx < 0
          ? (dy < 0 ? rounded.tlRadius : rounded.blRadius)
          : (dy < 0 ? rounded.trRadius : rounded.brRadius);
      var distance = math.min(
        hw / math.max(ax, 1e-10),
        hh / math.max(ay, 1e-10),
      );
      if (radius.x > 0 &&
          radius.y > 0 &&
          ax * distance > hw - radius.x &&
          ay * distance > hh - radius.y) {
        final cx = hw - radius.x;
        final cy = hh - radius.y;
        final rx2 = radius.x * radius.x;
        final ry2 = radius.y * radius.y;
        final a = ax * ax / rx2 + ay * ay / ry2;
        final b = -2 * (ax * cx / rx2 + ay * cy / ry2);
        final c = cx * cx / rx2 + cy * cy / ry2 - 1;
        distance = (-b + math.sqrt(math.max(0.0, b * b - 4 * a * c))) / (2 * a);
      }
      final ellipse = 1 / math.sqrt(dx * dx / (hw * hw) + dy * dy / (hh * hh));
      final blend =
          fullness *
          (0.78 + 0.20 * (dx * headingUnit.dx + dy * headingUnit.dy));
      // A moving waist separates the source and leading lobe mid-flight.
      // Fade it at both endpoints so the settled geometry stays exact.
      final along = dx * headingUnit.dx + dy * headingUnit.dy;
      final waist = math.exp(-math.pow((along - 0.12) / 0.30, 2));
      final neck = 1 - 0.13 * fullness * waist * 4 * dx * dx * dy * dy;
      final r = (distance + (ellipse - distance) * blend) * neck;
      return rect.center + Offset(dx * r, dy * r);
    });
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    // Periodic cubic tangents keep the silhouette smooth, including at the seam.
    for (var i = 0; i < count; i++) {
      final previous = points[(i - 1 + count) % count];
      final current = points[i];
      final next = points[(i + 1) % count];
      final after = points[(i + 2) % count];
      final c1 = current + (next - previous) / 6;
      final c2 = next - (after - current) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, next.dx, next.dy);
    }
    return path..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    final path = _path(rect.deflate(side.width / 2));
    canvas.drawPath(path, side.toPaint());
  }
}
