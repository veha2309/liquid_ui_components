import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart' as optical;

/// Regular glass prioritizes legibility; clear glass is for media backgrounds.
enum LiquidGlassVariant { regular, clear }

/// Selects optical rendering, a portable blur, or an opaque accessible surface.
enum LiquidGlassRendering {
  automatic,
  frosted,
  solid,

  /// Optical refraction with chromatic dispersion disabled.
  balanced,
}

/// Shared optical settings. Geometry belongs to each component.
@immutable
class LiquidGlassSettings {
  const LiquidGlassSettings({
    this.variant = LiquidGlassVariant.regular,
    this.rendering = LiquidGlassRendering.automatic,
    this.tintColor,
    this.foregroundColor,
    this.opacity = 0.30,
    this.blur = 8,
    this.saturation = 1.2,
    this.refraction = 1.35,
    this.depth = 0.045,
    this.magnification = 1,
    this.chromaticAberration = 0.0005,
    this.borderWidth = 1,
    this.lightIntensity = 0.65,
    this.lightDirection = 115,
    this.refractionWidth = 8,
    this.scaleRefractionWithSize = true,
    this.edgeAmbientIntensity = 0.35,
    this.edgeLightSpread = 0.55,
    this.shadowBlur = 18,
    this.shadowOpacity = 0.09,
    this.animationDuration = const Duration(milliseconds: 200),
    this.reduceTransparency = false,
    this.dynamicsIntensity = 1,
  }) : assert(opacity >= 0 && opacity <= 1),
       assert(blur >= 0 && blur < double.infinity),
       assert(saturation >= 0 && saturation < double.infinity),
       assert(refraction >= 1 && refraction < double.infinity),
       assert(depth >= 0 && depth <= 1),
       assert(magnification > 0 && magnification < double.infinity),
       assert(chromaticAberration >= 0 && chromaticAberration <= 1),
       assert(borderWidth >= 0 && borderWidth < double.infinity),
       assert(lightIntensity >= 0 && lightIntensity < double.infinity),
       assert(
         lightDirection > -double.infinity && lightDirection < double.infinity,
       ),
       assert(refractionWidth >= 0 && refractionWidth < double.infinity),
       assert(edgeAmbientIntensity >= 0 && edgeAmbientIntensity <= 5),
       assert(edgeLightSpread >= 0 && edgeLightSpread <= 1),
       assert(shadowBlur >= 0 && shadowBlur < double.infinity),
       assert(shadowOpacity >= 0 && shadowOpacity <= 1),
       assert(dynamicsIntensity >= 0 && dynamicsIntensity <= 1);

  /// Media preset. Supply a contrasting foreground and dim bright media behind it.
  const LiquidGlassSettings.clear({
    this.tintColor,
    this.foregroundColor = Colors.white,
    this.rendering = LiquidGlassRendering.automatic,
    this.reduceTransparency = false,
    this.dynamicsIntensity = 1,
    this.lightDirection = 115,
    this.refractionWidth = 8,
    this.scaleRefractionWithSize = true,
    this.edgeAmbientIntensity = 0.35,
    this.edgeLightSpread = 0.55,
  }) : assert(dynamicsIntensity >= 0 && dynamicsIntensity <= 1),
       assert(
         lightDirection > -double.infinity && lightDirection < double.infinity,
       ),
       assert(refractionWidth >= 0 && refractionWidth < double.infinity),
       assert(edgeAmbientIntensity >= 0 && edgeAmbientIntensity <= 5),
       assert(edgeLightSpread >= 0 && edgeLightSpread <= 1),
       variant = LiquidGlassVariant.clear,
       opacity = 0.08,
       blur = 2,
       saturation = 1.1,
       refraction = 1.35,
       depth = 0.06,
       magnification = 1.015,
       chromaticAberration = 0.0008,
       borderWidth = 1,
       lightIntensity = 0.85,
       shadowBlur = 18,
       shadowOpacity = 0.12,
       animationDuration = const Duration(milliseconds: 200);

  final LiquidGlassVariant variant;
  final LiquidGlassRendering rendering;
  final Color? tintColor;
  final Color? foregroundColor;

  /// Tint opacity in light mode; regular glass adds 0.15 in dark mode.
  final double opacity;
  final double blur;
  final double saturation;
  final double refraction;
  final double depth;
  final double magnification;
  final double chromaticAberration;
  final double borderWidth;
  final double lightIntensity;

  /// Direction of the rim light in degrees: 0 right, 90 top.
  final double lightDirection;

  /// Reference refraction band width in logical pixels, before size scaling.
  final double refractionWidth;
  final bool scaleRefractionWithSize;
  final double edgeAmbientIntensity;
  final double edgeLightSpread;
  final double shadowBlur;
  final double shadowOpacity;
  final Duration animationDuration;

  /// Host bridge for a platform's Reduce Transparency preference.
  final bool reduceTransparency;

  /// Strength of decorative press/drag dynamics. Zero disables these effects.
  /// Reduced motion disables them regardless of this setting.
  final double dynamicsIntensity;

  /// Returns a complete settings object with selected values replaced.
  /// Null color arguments retain the existing color.
  LiquidGlassSettings copyWith({
    LiquidGlassVariant? variant,
    LiquidGlassRendering? rendering,
    Color? tintColor,
    Color? foregroundColor,
    double? opacity,
    double? blur,
    double? saturation,
    double? refraction,
    double? depth,
    double? magnification,
    double? chromaticAberration,
    double? borderWidth,
    double? lightIntensity,
    double? lightDirection,
    double? refractionWidth,
    bool? scaleRefractionWithSize,
    double? edgeAmbientIntensity,
    double? edgeLightSpread,
    double? shadowBlur,
    double? shadowOpacity,
    Duration? animationDuration,
    bool? reduceTransparency,
    double? dynamicsIntensity,
  }) => LiquidGlassSettings(
    variant: variant ?? this.variant,
    rendering: rendering ?? this.rendering,
    tintColor: tintColor ?? this.tintColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    opacity: opacity ?? this.opacity,
    blur: blur ?? this.blur,
    saturation: saturation ?? this.saturation,
    refraction: refraction ?? this.refraction,
    depth: depth ?? this.depth,
    magnification: magnification ?? this.magnification,
    chromaticAberration: chromaticAberration ?? this.chromaticAberration,
    borderWidth: borderWidth ?? this.borderWidth,
    lightIntensity: lightIntensity ?? this.lightIntensity,
    lightDirection: lightDirection ?? this.lightDirection,
    refractionWidth: refractionWidth ?? this.refractionWidth,
    scaleRefractionWithSize:
        scaleRefractionWithSize ?? this.scaleRefractionWithSize,
    edgeAmbientIntensity: edgeAmbientIntensity ?? this.edgeAmbientIntensity,
    edgeLightSpread: edgeLightSpread ?? this.edgeLightSpread,
    shadowBlur: shadowBlur ?? this.shadowBlur,
    shadowOpacity: shadowOpacity ?? this.shadowOpacity,
    animationDuration: animationDuration ?? this.animationDuration,
    reduceTransparency: reduceTransparency ?? this.reduceTransparency,
    dynamicsIntensity: dynamicsIntensity ?? this.dynamicsIntensity,
  );

  /// Resolve the optical bevel for a surface's actual layout size. Compact
  /// controls get a shallower/narrower rim; larger surfaces get more depth.
  /// The band never occupies more than 22% of the shortest side.
  ({double refractionWidth, double depth}) resolveEdgeOptics(Size size) {
    assert(size.isFinite && size.width >= 0 && size.height >= 0);
    if (size.isEmpty || refractionWidth == 0) {
      return (refractionWidth: 0, depth: 0);
    }
    final factor = scaleRefractionWithSize
        ? (size.shortestSide / 64).clamp(0.55, 1.35)
        : 1.0;
    return (
      refractionWidth: (refractionWidth * factor).clamp(
        0.0,
        size.shortestSide * 0.22,
      ),
      depth: (depth * factor).clamp(0.0, 1.0),
    );
  }
}

/// Provides settings to glass controls without replacing the Material theme.
class LiquidGlassTheme extends InheritedWidget {
  const LiquidGlassTheme({
    super.key,
    required this.settings,
    required super.child,
  });

  final LiquidGlassSettings settings;

  static LiquidGlassSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiquidGlassTheme>()?.settings;

  static LiquidGlassSettings of(BuildContext context) =>
      maybeOf(context) ?? const LiquidGlassSettings();

  @override
  bool updateShouldNotify(LiquidGlassTheme oldWidget) =>
      settings != oldWidget.settings;
}

/// A reusable glass backdrop with crisp content painted above the optical lens.
///
/// Place over real content in a Stack. Use for floating controls, not whole pages.
/// No fixed size is required; the child determines the surface's dimensions.
class LiquidGlassSurface extends StatelessWidget {
  // Reuse blur kernels for common presets rather than allocating one for
  // every animated geometry frame. Bound the cache for custom animated blur.
  static final _blurFilters = <double, ui.ImageFilter>{};
  static ui.ImageFilter _blurFilter(double sigma) {
    final cached = _blurFilters[sigma];
    if (cached != null) return cached;
    if (_blurFilters.length >= 16) _blurFilters.remove(_blurFilters.keys.first);
    return _blurFilters[sigma] = ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
    );
  }

  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.settings,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.shape,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final LiquidGlassSettings? settings;
  final BorderRadius borderRadius;

  /// Optional outline shared by the tint, clip, rim and shadow. Custom outlines
  /// use a rectangular optical sampling layer; the rim follows this shape.
  /// The optical renderer's refraction field remains rectangular.
  final OutlinedBorder? shape;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final config = settings ?? LiquidGlassTheme.of(context);
    assert(!config.animationDuration.isNegative);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final solid =
        config.reduceTransparency ||
        MediaQuery.highContrastOf(context) ||
        config.rendering == LiquidGlassRendering.solid;
    final opticalEnabled =
        !solid &&
        !MediaQuery.disableAnimationsOf(context) &&
        (config.rendering == LiquidGlassRendering.automatic ||
            config.rendering == LiquidGlassRendering.balanced) &&
        ui.ImageFilter.isShaderFilterSupported;
    final tint = (config.tintColor ?? theme.colorScheme.surface).withValues(
      alpha: solid
          ? 1
          : (config.opacity +
                    (dark && config.variant == LiquidGlassVariant.regular
                        ? 0.15
                        : 0))
                .clamp(0.0, 1.0),
    );
    final foreground = solid
        ? ThemeData.estimateBrightnessForColor(tint) == Brightness.dark
              ? Colors.white
              : Colors.black
        : config.foregroundColor ?? theme.colorScheme.onSurface;
    final radius = borderRadius.topLeft.x;
    final side = BorderSide(
      color: foreground.withValues(alpha: solid ? 0.4 : 0.20),
      width: config.borderWidth,
    );
    final outline = shape?.copyWith(side: solid ? side : BorderSide.none);
    final Decoration decoration = outline != null
        ? ShapeDecoration(color: opticalEnabled ? null : tint, shape: outline)
        : BoxDecoration(
            color: opticalEnabled ? null : tint,
            borderRadius: borderRadius,
            border: solid ? Border.fromBorderSide(side) : null,
          );
    Widget backdrop;
    if (opticalEnabled) {
      backdrop = LayoutBuilder(
        builder: (context, constraints) {
          final edges = config.resolveEdgeOptics(constraints.biggest);
          return optical.LiquidGlassLens(
            style: optical.LiquidGlassStyle(
              shape: optical.LiquidGlassShape.continuousRoundedRectangle(
                cornerRadius: outline == null ? radius : 0,
                borderWidth: outline == null ? config.borderWidth : 0,
                lightIntensity: outline == null ? config.lightIntensity : 0,
                lightDirection: config.lightDirection % 360,
                borderType: optical.OpticalBorder(
                  ambientIntensity: config.edgeAmbientIntensity,
                  lightSpread: config.edgeLightSpread,
                  borderSaturation: config.saturation.clamp(0.0, 3.0),
                ),
              ),
              appearance: optical.LiquidGlassAppearance(
                color: tint,
                saturation: config.saturation,
                blur: optical.LiquidGlassBlur(
                  sigmaX: config.blur,
                  sigmaY: config.blur,
                ),
              ),
              refraction: optical.LiquidGlassRefraction(
                magnification: config.magnification,
                chromaticAberration:
                    config.rendering == LiquidGlassRendering.balanced
                    ? 0
                    : config.chromaticAberration,
                refractionType: optical.OpticalRefraction(
                  refraction: config.refraction,
                  refractionWidth: edges.refractionWidth,
                  depth: edges.depth,
                ),
              ),
            ),
            child: const SizedBox.expand(),
          );
        },
      );
    } else {
      backdrop = const SizedBox.expand();
    }
    backdrop = DecoratedBox(
      decoration: decoration,
      position: opticalEnabled
          ? DecorationPosition.foreground
          : DecorationPosition.background,
      child: backdrop,
    );
    if (!solid && !opticalEnabled && config.blur > 0) {
      backdrop = BackdropFilter.grouped(
        filter: _blurFilter(config.blur),
        child: backdrop,
      );
    }
    final shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: config.shadowOpacity),
        blurRadius: config.shadowBlur,
        offset: const Offset(0, 5),
      ),
    ];
    final content = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(child: ExcludeSemantics(child: backdrop)),
        ),
        if (!solid && (!opticalEnabled || outline != null))
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _GlassRimPainter(
                    radius: borderRadius,
                    shape: outline,
                    width: config.borderWidth,
                    direction: config.lightDirection,
                    intensity: config.lightIntensity,
                    ambient: config.edgeAmbientIntensity,
                    spread: config.edgeLightSpread,
                  ),
                ),
              ),
            ),
          ),
        BackdropGroup(
          child: IconTheme.merge(
            data: IconThemeData(color: foreground),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ],
    );
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : config.animationDuration,
      decoration: outline != null
          ? ShapeDecoration(
              shape: outline.copyWith(side: BorderSide.none),
              shadows: shadows,
            )
          : BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: outline != null
          ? ClipPath(
              clipper: ShapeBorderClipper(shape: outline),
              child: content,
            )
          : ClipRRect(borderRadius: borderRadius, child: content),
    );
  }
}

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
