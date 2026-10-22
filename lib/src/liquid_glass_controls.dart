import 'package:flutter/material.dart';

import 'liquid_glass_surface.dart';

export 'liquid_glass_slider.dart';

/// A keyboard-accessible glass action with Material focus and press feedback.
class LiquidGlassButton extends StatelessWidget {
  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.settings,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.tooltip,
    this.autofocus = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final LiquidGlassSettings? settings;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final String? tooltip;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    Widget button = LiquidGlassSurface(
      settings: settings,
      borderRadius: borderRadius,
      child: Builder(
        builder: (context) {
          final foreground = DefaultTextStyle.of(context).style.color!;
          return TextButton(
            autofocus: autofocus,
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: foreground,
              disabledForegroundColor: foreground.withValues(alpha: 0.38),
              minimumSize: const Size(48, 48),
              padding: padding,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
            ),
            child: child,
          );
        },
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// A circular action; a tooltip is required for its accessible name.
class LiquidGlassIconButton extends StatelessWidget {
  const LiquidGlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.settings,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final LiquidGlassSettings? settings;

  @override
  Widget build(BuildContext context) => LiquidGlassButton(
    settings: settings,
    onPressed: onPressed,
    tooltip: tooltip,
    padding: const EdgeInsets.all(12),
    child: Semantics(label: tooltip, excludeSemantics: true, child: icon),
  );
}

/// A single shared surface for a group of floating actions.
///
/// Prefer plain IconButtons inside this toolbar to avoid stacking glass layers.
/// Actions wrap on narrow screens and with large text.
class LiquidGlassToolbar extends StatelessWidget {
  const LiquidGlassToolbar({
    super.key,
    required this.children,
    this.settings,
    this.padding = const EdgeInsets.all(8),
    this.spacing = 8,
    this.alignment = WrapAlignment.center,
  }) : assert(spacing >= 0 && spacing < double.infinity);

  final List<Widget> children;
  final LiquidGlassSettings? settings;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) => LiquidGlassSurface(
    settings: settings,
    padding: padding,
    child: Material(
      type: MaterialType.transparency,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    ),
  );
}

/// Controlled single-selection glass segments, with native keyboard semantics.
class LiquidGlassSegmentedControl<T> extends StatelessWidget {
  LiquidGlassSegmentedControl({
    super.key,
    required List<ButtonSegment<T>> segments,
    required this.selected,
    required this.onSelectionChanged,
    this.settings,
    this.showSelectedIcon = false,
  }) : segments = List.unmodifiable(segments) {
    if (segments.length < 2) {
      throw ArgumentError.value(
        segments,
        'segments',
        'Use at least two segments.',
      );
    }
    final values = segments.map((segment) => segment.value).toSet();
    if (values.length != segments.length || !values.contains(selected)) {
      throw ArgumentError(
        'Segment values must be unique and include selected.',
      );
    }
  }

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onSelectionChanged;
  final LiquidGlassSettings? settings;
  final bool showSelectedIcon;

  @override
  Widget build(BuildContext context) => LiquidGlassSurface(
    settings: settings,
    borderRadius: BorderRadius.circular(28),
    padding: const EdgeInsets.all(4),
    child: Builder(
      builder: (context) {
        final foreground = DefaultTextStyle.of(context).style.color!;
        final config = settings ?? LiquidGlassTheme.of(context);
        final index = segments.indexWhere(
          (segment) => segment.value == selected,
        );
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final fraction = index / (segments.length - 1);
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: AnimatedAlign(
                    alignment: Alignment(
                      (rtl ? 1 - fraction : fraction) * 2 - 1,
                      0,
                    ),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : config.animationDuration,
                    curve: Curves.easeOutCubic,
                    child: FractionallySizedBox(
                      widthFactor: 1 / segments.length,
                      heightFactor: 1,
                      child: LiquidGlassSurface(
                        key: const ValueKey('glass-segment-selector'),
                        settings: config.copyWith(
                          variant: LiquidGlassVariant.clear,
                          opacity: 0.16,
                          blur: 0,
                          shadowBlur: 6,
                          shadowOpacity: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.26),
                                foreground.withValues(alpha: 0.10),
                              ],
                            ),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SegmentedButton<T>(
              segments: segments,
              selected: {selected},
              onSelectionChanged: onSelectionChanged == null
                  ? null
                  : (values) => onSelectionChanged!(values.single),
              showSelectedIcon: showSelectedIcon,
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                side: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? BorderSide(color: foreground, width: 2)
                      : BorderSide.none,
                ),
                splashFactory: NoSplash.splashFactory,
                animationDuration: Duration.zero,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => foreground.withValues(
                    alpha: states.contains(WidgetState.disabled) ? 0.38 : 1,
                  ),
                ),
                backgroundColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                textStyle: WidgetStateProperty.resolveWith(
                  (states) => TextStyle(
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// A controlled glass-backed switch with native toggle semantics.
class LiquidGlassSwitch extends StatelessWidget {
  const LiquidGlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.settings,
    this.autofocus = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;
  final LiquidGlassSettings? settings;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => LiquidGlassSurface(
    settings: settings,
    child: Semantics(
      label: semanticLabel,
      child: Switch(
        value: value,
        onChanged: onChanged,
        autofocus: autofocus,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
  );
}
