import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../surfaces/liquid_glass_surface.dart';

part 'morph_geometry.dart';

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
