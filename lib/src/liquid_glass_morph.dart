import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'liquid_glass_surface.dart';

/// A single glass lens that expands from a compact control into a panel.
///
/// The host owns [expanded] and supplies actions in both children. Place in an
/// Align or Stack with loose constraints to allow the surface to change size.
/// This widget participates in layout; it does not present an overlay or manage
/// route dismissal. Children retain their state, but only the settled, visible
/// target child accepts input, focus and accessibility traversal once revealed.
class LiquidGlassMorph extends StatefulWidget {
  LiquidGlassMorph({
    super.key,
    required this.expanded,
    required this.collapsedSize,
    required this.expandedSize,
    required this.collapsedChild,
    required this.expandedChild,
    this.sharedChild,
    this.collapsedSharedAlignment = AlignmentDirectional.center,
    this.expandedSharedAlignment = AlignmentDirectional.topStart,
    this.collapsedSharedPadding = EdgeInsets.zero,
    this.expandedSharedPadding = const EdgeInsets.all(16),
    this.collapsedBorderRadius = const BorderRadius.all(Radius.circular(28)),
    this.expandedBorderRadius = const BorderRadius.all(Radius.circular(32)),
    this.alignment = AlignmentDirectional.topStart,
    this.settings,
    this.expandedSettings,
    this.duration = const Duration(milliseconds: 380),
    this.curve = Curves.linear,
  }) : assert(collapsedSize.width > 0 && collapsedSize.width < double.infinity),
       assert(
         collapsedSize.height > 0 && collapsedSize.height < double.infinity,
       ),
       assert(expandedSize.width > 0 && expandedSize.width < double.infinity),
       assert(expandedSize.height > 0 && expandedSize.height < double.infinity),
       assert(!duration.isNegative);

  final bool expanded;
  final Size collapsedSize;
  final Size expandedSize;
  final Widget collapsedChild;
  final Widget expandedChild;

  /// Content rendered once above both states, such as a title that travels
  /// from the button to the panel header without fading or being duplicated.
  /// Reserve its space in both children. Pointer events pass through to the
  /// state-specific controls beneath it; its semantics remain available.
  final Widget? sharedChild;
  final AlignmentGeometry collapsedSharedAlignment;
  final AlignmentGeometry expandedSharedAlignment;
  final EdgeInsetsGeometry collapsedSharedPadding;
  final EdgeInsetsGeometry expandedSharedPadding;
  final BorderRadius collapsedBorderRadius;
  final BorderRadius expandedBorderRadius;
  final AlignmentGeometry alignment;

  /// Compact material, defaulting to the surrounding [LiquidGlassTheme].
  final LiquidGlassSettings? settings;

  /// Expanded material. Defaults to slightly deeper glass with the same blur.
  ///
  /// Optical scalar values interpolate. Rendering mode, variant and
  /// accessibility preferences use the target configuration immediately.
  final LiquidGlassSettings? expandedSettings;

  /// Perceptual spring duration; the small settling tail can last longer.
  /// Zero switches states immediately.
  final Duration duration;

  /// Optional remapping of the spring's in-range progress. Linear preserves
  /// the spring's natural velocity and is recommended for fluid motion.
  final Curve curve;

  @override
  State<LiquidGlassMorph> createState() => _LiquidGlassMorphState();
}

class _LiquidGlassMorphState extends State<LiquidGlassMorph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    duration: widget.duration,
    value: widget.expanded ? 1 : 0,
  );

  void _animate() {
    final target = widget.expanded ? 1.0 : 0.0;
    if (_controller.value == target && !_controller.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context) ||
        widget.duration == Duration.zero) {
      _controller.value = target;
    } else {
      final velocity = _controller.velocity;
      _controller.animateWith(
        SpringSimulation(
          SpringDescription.withDurationAndBounce(
            duration: widget.duration,
            bounce: 0.02,
          ),
          _controller.value,
          target,
          velocity,
          snapToEnd: true,
          tolerance: const Tolerance(distance: 0.002, velocity: 0.02),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate();
  }

  @override
  void didUpdateWidget(LiquidGlassMorph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded ||
        oldWidget.duration != widget.duration) {
      _animate();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.settings ?? LiquidGlassTheme.of(context);
    final panel =
        widget.expandedSettings ??
        compact.copyWith(
          depth: (compact.depth * 1.35).clamp(0.0, 1.0),
          shadowOpacity: (compact.shadowOpacity + 0.03).clamp(0.0, 1.0),
        );
    final alignment = widget.alignment.resolve(Directionality.of(context));
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final small = constraints.constrain(widget.collapsedSize);
        final large = constraints.constrain(widget.expandedSize);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            final t = widget.curve
                .transform(progress.clamp(0.0, 1.0))
                .clamp(0.0, 1.0);
            // Preserve the spring's slight overshoot. Velocity gently stretches
            // the leading axis while the other catches up, like a soft lens.
            final flow = math.sin(math.pi * t);
            final stretch =
                (_controller.velocity * 0.014).clamp(-0.07, 0.07) * flow;
            final overshoot = progress - progress.clamp(0.0, 1.0);
            // The surface spreads across before filling downwards. Different
            // arrival times plus the moving contour avoid rectangular scaling.
            final across = math.pow(t, 0.80).toDouble() + overshoot;
            final down = math.pow(t, 1.14).toDouble() + overshoot;
            final width =
                (small.width + (large.width - small.width) * (across + stretch))
                    .clamp(1.0, double.infinity);
            final height =
                (small.height +
                        (large.height - small.height) * (down - stretch * 0.65))
                    .clamp(1.0, double.infinity);
            final size = constraints.constrain(Size(width, height));
            final energy =
                (_controller.velocity.abs() / 10).clamp(0.0, 1.0) * flow;
            double mix(double a, double b) => a + (b - a) * t;
            final target = widget.expanded ? panel : compact;
            final material = target.copyWith(
              tintColor: Color.lerp(
                compact.tintColor ?? colors.surface,
                panel.tintColor ?? colors.surface,
                t,
              ),
              foregroundColor: Color.lerp(
                compact.foregroundColor ?? colors.onSurface,
                panel.foregroundColor ?? colors.onSurface,
                t,
              ),
              opacity: mix(compact.opacity, panel.opacity),
              blur: mix(compact.blur, panel.blur),
              saturation: mix(compact.saturation, panel.saturation),
              refraction: mix(compact.refraction, panel.refraction),
              depth: mix(compact.depth, panel.depth),
              magnification: mix(compact.magnification, panel.magnification),
              chromaticAberration: mix(
                compact.chromaticAberration,
                panel.chromaticAberration,
              ),
              borderWidth: mix(compact.borderWidth, panel.borderWidth),
              lightIntensity:
                  mix(compact.lightIntensity, panel.lightIntensity) +
                  energy * 0.12,
              lightDirection:
                  compact.lightDirection +
                  ((panel.lightDirection - compact.lightDirection + 540) % 360 -
                          180) *
                      t,
              refractionWidth: mix(
                compact.refractionWidth,
                panel.refractionWidth,
              ),
              edgeAmbientIntensity: mix(
                compact.edgeAmbientIntensity,
                panel.edgeAmbientIntensity,
              ),
              edgeLightSpread: mix(
                compact.edgeLightSpread,
                panel.edgeLightSpread,
              ),
              shadowBlur: mix(compact.shadowBlur, panel.shadowBlur),
              shadowOpacity: mix(compact.shadowOpacity, panel.shadowOpacity),
              // Geometry and shadow share this controller, without a second
              // implicit animation trailing behind the optical lens.
              animationDuration: Duration.zero,
            );
            Widget content(
              Widget child,
              Size size,
              double opacity,
              bool active,
              double scale,
              double offset,
            ) {
              return Positioned.fill(
                child: IgnorePointer(
                  ignoring: !active,
                  child: ExcludeFocus(
                    excluding: !active,
                    child: ExcludeSemantics(
                      excluding: !active,
                      child: Offstage(
                        offstage: opacity == 0,
                        child: TickerMode(
                          enabled: opacity > 0,
                          child: OverflowBox(
                            alignment: alignment,
                            minWidth: size.width,
                            maxWidth: size.width,
                            minHeight: size.height,
                            maxHeight: size.height,
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(0, offset),
                                child: Transform.scale(
                                  alignment: alignment,
                                  scale: scale,
                                  child: RepaintBoundary(child: child),
                                ),
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

            return RepaintBoundary(
              child: LiquidGlassSurface(
                settings: material,
                shape: _FluidGlassBorder(
                  borderRadius: BorderRadius.lerp(
                    widget.collapsedBorderRadius,
                    widget.expandedBorderRadius,
                    t,
                  )!,
                  fullness: flow,
                  direction: alignment,
                ),
                borderRadius:
                    BorderRadius.lerp(
                      widget.collapsedBorderRadius,
                      widget.expandedBorderRadius,
                      t,
                    )! +
                    BorderRadius.circular(energy * 8),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      content(
                        widget.collapsedChild,
                        small,
                        (1 - t / 0.65).clamp(0.0, 1.0),
                        !widget.expanded && t <= 0.15,
                        1 - 0.06 * t,
                        -4 * t,
                      ),
                      content(
                        widget.expandedChild,
                        large,
                        ((t - 0.15) / 0.85).clamp(0.0, 1.0),
                        widget.expanded && t >= 0.85,
                        0.94 + 0.06 * t,
                        10 * (1 - t),
                      ),
                      if (widget.sharedChild != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomSingleChildLayout(
                              delegate: _MorphSharedLayout(
                                progress: t,
                                small: small,
                                large: large,
                                startAlignment: widget.collapsedSharedAlignment
                                    .resolve(Directionality.of(context)),
                                endAlignment: widget.expandedSharedAlignment
                                    .resolve(Directionality.of(context)),
                                startPadding: widget.collapsedSharedPadding
                                    .resolve(Directionality.of(context)),
                                endPadding: widget.expandedSharedPadding
                                    .resolve(Directionality.of(context)),
                              ),
                              child: RepaintBoundary(child: widget.sharedChild),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

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
