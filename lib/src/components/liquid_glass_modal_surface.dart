import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import '../surfaces/liquid_glass_surface.dart';
import 'liquid_glass_morph.dart';

/// Opts a modal's surfaces into the route-driven droplet reveal.
class GlassModalPresentation extends InheritedWidget {
  const GlassModalPresentation({
    super.key,
    required super.child,
    this.bottom = false,
  });
  final bool bottom;
  @override
  bool updateShouldNotify(GlassModalPresentation oldWidget) =>
      bottom != oldWidget.bottom;
}

/// One live glass layer; only its perimeter changes, never the text scale.
class GlassModalSurface extends StatelessWidget {
  const GlassModalSurface({
    super.key,
    required this.child,
    required this.padding,
    this.settings,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final LiquidGlassSettings? settings;
  final BorderRadius borderRadius;

  static final _leading = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 360, damping: 38),
    0,
    1,
    0,
  );
  static final _body = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 290, damping: 35),
    0,
    1,
    0,
  );

  @override
  Widget build(BuildContext context) {
    final presentation = context
        .dependOnInheritedWidgetOfExactType<GlassModalPresentation>();
    final animation = ModalRoute.of(context)?.animation;
    final config = settings ?? LiquidGlassTheme.of(context);
    if (presentation == null ||
        animation == null ||
        MediaQuery.disableAnimationsOf(context) ||
        config.dynamicsIntensity == 0) {
      return LiquidGlassSurface(
        settings: settings,
        borderRadius: borderRadius,
        padding: padding,
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, content) {
        final t = animation.value;
        // Normalize the critically damped springs to exact endpoints. An
        // overshooting layout was being clipped by the route, then snapping
        // back when the endpoint forced its size to one.
        final across = (_leading.x(t * 0.55) / _leading.x(0.55)).clamp(
          0.0,
          1.0,
        );
        final down = (_body.x(t * 0.55) / _body.x(0.55)).clamp(0.0, 1.0);
        final intensity = config.dynamicsIntensity;
        // A sheet already travels with its native route. Give it a small
        // liquid settle rather than a second, competing expansion.
        final compactWidth = presentation.bottom ? 0.96 : 0.78;
        final compactHeight = presentation.bottom ? 0.94 : 0.76;
        final reveal = Curves.easeInOut.transform(
          const Interval(0.08, 0.65).transform(t),
        );
        final flow = math.sin(math.pi * down) * intensity;
        final radius = BorderRadius.lerp(
          BorderRadius.circular(36),
          borderRadius,
          down.clamp(0, 1),
        )!;
        return Align(
          alignment: presentation.bottom
              ? Alignment.bottomCenter
              : Alignment.center,
          widthFactor: 1,
          heightFactor: 1,
          child: LiquidGlassSurface(
            settings: config.copyWith(
              animationDuration: Duration.zero,
              depth: (config.depth + flow * 0.035).clamp(0, 1),
              lightIntensity: config.lightIntensity + flow * 0.12,
            ),
            borderRadius: radius,
            // Keep the same clip, rim and optical path even when settled.
            shape: LiquidGlassMorph.transitionShape(
              borderRadius: radius,
              fullness: flow * 0.045,
              direction: presentation.bottom
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
            ),
            padding: padding,
            child: _RevealBody(
              width: 1 - (1 - compactWidth) * (1 - across) * intensity,
              height: 1 - (1 - compactHeight) * (1 - down) * intensity,
              child: IgnorePointer(
                ignoring:
                    t < 0.65 || animation.status == AnimationStatus.reverse,
                child: ExcludeFocus(
                  excluding: t < 0.65,
                  child: ExcludeSemantics(
                    excluding: t < 0.65,
                    child: Opacity(opacity: reveal, child: content),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RevealBody extends SingleChildRenderObjectWidget {
  const _RevealBody({
    required this.width,
    required this.height,
    required super.child,
  });
  final double width;
  final double height;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReveal(width, height);
  @override
  void updateRenderObject(BuildContext context, _RenderReveal renderObject) =>
      renderObject.update(width, height);
}

class _RenderReveal extends RenderProxyBox {
  _RenderReveal(this.width, this.height);
  double width;
  double height;
  void update(double w, double h) {
    if (width == w && height == h) return;
    width = w;
    height = h;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child!.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(child!.size.width * width, child!.size.height * height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Offset.zero & size, (
      context,
      offset,
    ) {
      context.paintChild(
        child!,
        offset +
            Offset(
              (size.width - child!.size.width) / 2,
              (size.height - child!.size.height) / 2,
            ),
      );
    });
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
      0,
      1,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: Offset(
          (size.width - child!.size.width) / 2,
          (size.height - child!.size.height) / 2,
        ),
        position: position,
        hitTest: (result, transformed) =>
            child!.hitTest(result, position: transformed),
      );
}
