import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import 'liquid_glass_surface.dart';
import 'liquid_glass_dynamics.dart';

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
    final config = settings ?? LiquidGlassTheme.of(context);
    Widget button = _GlassActionDynamics(
      enabled: onPressed != null,
      intensity: config.dynamicsIntensity,
      borderRadius: borderRadius,
      builder: (states) => LiquidGlassSurface(
        settings: settings,
        borderRadius: borderRadius,
        child: Builder(
          builder: (context) {
            final foreground = DefaultTextStyle.of(context).style.color!;
            return TextButton(
              statesController: states,
              autofocus: autofocus,
              onPressed: onPressed,
              style:
                  TextButton.styleFrom(
                    foregroundColor: foreground,
                    disabledForegroundColor: foreground.withValues(alpha: 0.38),
                    minimumSize: const Size(48, 48),
                    padding: padding,
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: Colors.transparent,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.focused)
                          ? foreground.withValues(alpha: 0.12)
                          : states.contains(WidgetState.hovered)
                          ? foreground.withValues(alpha: 0.06)
                          : Colors.transparent,
                    ),
                  ),
              child: child,
            );
          },
        ),
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
  Widget build(BuildContext context) => LiquidGlassDynamics(
    intensity:
        (settings ?? LiquidGlassTheme.of(context)).dynamicsIntensity * 0.45,
    child: LiquidGlassSurface(
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
  Widget build(BuildContext context) => LiquidGlassDynamics(
    enabled: onSelectionChanged != null,
    intensity:
        (settings ?? LiquidGlassTheme.of(context)).dynamicsIntensity * 0.6,
    child: LiquidGlassSurface(
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
                    child: _GlassSelectionSlide(
                      position: (rtl ? 1 - fraction : fraction) * 2 - 1,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : config.animationDuration,
                      intensity: config.dynamicsIntensity,
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
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
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
  Widget build(BuildContext context) => LiquidGlassDynamics(
    enabled: onChanged != null,
    intensity:
        (settings ?? LiquidGlassTheme.of(context)).dynamicsIntensity * 0.8,
    child: LiquidGlassSurface(
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
    ),
  );
}

class _GlassActionDynamics extends StatefulWidget {
  const _GlassActionDynamics({
    required this.enabled,
    required this.intensity,
    required this.borderRadius,
    required this.builder,
  });
  final bool enabled;
  final double intensity;
  final BorderRadius borderRadius;
  final Widget Function(WidgetStatesController) builder;

  @override
  State<_GlassActionDynamics> createState() => _GlassActionDynamicsState();
}

class _GlassActionDynamicsState extends State<_GlassActionDynamics> {
  final _states = WidgetStatesController();
  final _pressed = ValueNotifier(false);
  @override
  void initState() {
    super.initState();
    _states.addListener(_syncPressed);
  }

  void _syncPressed() {
    final next = _states.value.contains(WidgetState.pressed);
    if (_pressed.value == next) return;
    // Native buttons also update disabled/focus state while building. Only
    // forward press changes, deferring a build-time cancellation safely.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pressed.value = _states.value.contains(WidgetState.pressed);
        }
      });
    } else {
      _pressed.value = next;
    }
  }

  @override
  void dispose() {
    _states.removeListener(_syncPressed);
    _states.dispose();
    _pressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pressed,
    child: widget.builder(_states),
    builder: (context, child) => LiquidGlassDynamics(
      enabled: widget.enabled,
      intensity: widget.intensity,
      borderRadius: widget.borderRadius,
      pressed: _pressed.value,
      child: child!,
    ),
  );
}

class _GlassSelectionSlide extends StatefulWidget {
  const _GlassSelectionSlide({
    required this.position,
    required this.duration,
    required this.intensity,
    required this.child,
  });
  final double position;
  final Duration duration;
  final double intensity;
  final Widget child;
  @override
  State<_GlassSelectionSlide> createState() => _GlassSelectionSlideState();
}

class _GlassSelectionSlideState extends State<_GlassSelectionSlide>
    with SingleTickerProviderStateMixin {
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.position,
  );
  bool _reduceMotion = false;

  void _move() {
    if (_reduceMotion ||
        widget.duration == Duration.zero ||
        widget.intensity == 0) {
      _position.value = widget.position;
    } else if (_position.value != widget.position) {
      _position.animateWith(
        SpringSimulation(
          SpringDescription.withDurationAndBounce(
            duration: widget.duration,
            bounce: 0.03,
          ),
          _position.value,
          widget.position,
          _position.velocity,
          snapToEnd: true,
          tolerance: const Tolerance(distance: 0.001, velocity: 0.01),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _move();
  }

  @override
  void didUpdateWidget(_GlassSelectionSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position ||
        oldWidget.duration != widget.duration ||
        oldWidget.intensity != widget.intensity) {
      _move();
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _position,
    child: widget.child,
    builder: (context, child) {
      final stretch =
          (_position.velocity.abs() / 15).clamp(0.0, 1.0) * widget.intensity;
      return Align(
        alignment: Alignment(_position.value, 0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            1 + stretch * 0.10,
            1 - stretch * 0.05,
            1,
          ),
          child: child,
        ),
      );
    },
  );
}
