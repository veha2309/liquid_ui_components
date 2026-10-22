import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart' as optical;

/// Regular glass prioritizes legibility; clear glass is for media backgrounds.
enum LiquidGlassVariant { regular, clear }

/// Selects optical rendering, a portable blur, or an opaque accessible surface.
enum LiquidGlassRendering { automatic, frosted, solid }

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
    this.shadowBlur = 18,
    this.shadowOpacity = 0.09,
    this.animationDuration = const Duration(milliseconds: 200),
    this.reduceTransparency = false,
  }) : assert(opacity >= 0 && opacity <= 1),
       assert(blur >= 0 && blur < double.infinity),
       assert(saturation >= 0 && saturation < double.infinity),
       assert(refraction >= 1 && refraction < double.infinity),
       assert(depth >= 0 && depth <= 1),
       assert(magnification > 0 && magnification < double.infinity),
       assert(chromaticAberration >= 0 && chromaticAberration <= 1),
       assert(borderWidth >= 0 && borderWidth < double.infinity),
       assert(lightIntensity >= 0 && lightIntensity < double.infinity),
       assert(shadowBlur >= 0 && shadowBlur < double.infinity),
       assert(shadowOpacity >= 0 && shadowOpacity <= 1);

  /// Media preset. Supply a contrasting foreground and dim bright media behind it.
  const LiquidGlassSettings.clear({
    this.tintColor,
    this.foregroundColor = Colors.white,
    this.rendering = LiquidGlassRendering.automatic,
    this.reduceTransparency = false,
  }) : variant = LiquidGlassVariant.clear,
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
  final double shadowBlur;
  final double shadowOpacity;
  final Duration animationDuration;

  /// Host bridge for a platform's Reduce Transparency preference.
  final bool reduceTransparency;

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
    double? shadowBlur,
    double? shadowOpacity,
    Duration? animationDuration,
    bool? reduceTransparency,
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
    shadowBlur: shadowBlur ?? this.shadowBlur,
    shadowOpacity: shadowOpacity ?? this.shadowOpacity,
    animationDuration: animationDuration ?? this.animationDuration,
    reduceTransparency: reduceTransparency ?? this.reduceTransparency,
  );
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
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.settings,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final LiquidGlassSettings? settings;
  final BorderRadius borderRadius;
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
        config.rendering == LiquidGlassRendering.automatic &&
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
    final decoration = BoxDecoration(
      color: opticalEnabled ? null : tint,
      borderRadius: borderRadius,
      border: Border.all(
        color: foreground.withValues(alpha: solid ? 0.4 : 0.20),
        width: config.borderWidth,
      ),
    );
    Widget backdrop;
    if (opticalEnabled) {
      backdrop = optical.LiquidGlassLens(
        style: optical.LiquidGlassStyle(
          shape: optical.LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: radius,
            borderWidth: config.borderWidth,
            lightIntensity: config.lightIntensity,
            lightDirection: 115,
            borderType: const optical.OpticalBorder(),
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
            chromaticAberration: config.chromaticAberration,
            refractionType: optical.OpticalRefraction(
              refraction: config.refraction,
              refractionWidth: 8,
              depth: config.depth,
            ),
          ),
        ),
        child: const SizedBox.expand(),
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
        filter: ui.ImageFilter.blur(sigmaX: config.blur, sigmaY: config.blur),
        child: backdrop,
      );
    }
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : config.animationDuration,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: config.shadowOpacity),
            blurRadius: config.shadowBlur,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(child: ExcludeSemantics(child: backdrop)),
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
        ),
      ),
    );
  }
}
