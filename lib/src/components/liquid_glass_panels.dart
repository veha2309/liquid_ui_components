import 'package:flutter/material.dart';

import '../surfaces/liquid_glass_surface.dart';
import 'liquid_glass_modal_surface.dart';

/// A glass card for settings, forms and contextual actions.
class LiquidGlassPanel extends StatelessWidget {
  const LiquidGlassPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.settings,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;
  final LiquidGlassSettings? settings;
  final EdgeInsetsGeometry padding;

  /// Opens a keyboard-aware, scrollable glass bottom panel.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    LiquidGlassSettings? settings,
  }) {
    final config = settings ?? LiquidGlassTheme.of(context);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      sheetAnimationStyle: AnimationStyle(
        duration:
            MediaQuery.disableAnimationsOf(context) ||
                config.dynamicsIntensity == 0
            ? Duration.zero
            : const Duration(milliseconds: 420),
        reverseDuration:
            MediaQuery.disableAnimationsOf(context) ||
                config.dynamicsIntensity == 0
            ? Duration.zero
            : const Duration(milliseconds: 300),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: LiquidGlassTheme(
            settings: config,
            child: GlassModalPresentation(
              bottom: true,
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GlassModalSurface(
    settings: settings,
    padding: padding,
    child: Builder(
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || icon != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  _PanelIcon(icon: icon!),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Semantics(
                          header: true,
                          child: Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.2,
                              letterSpacing: -0.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: DefaultTextStyle.of(
                              context,
                            ).style.color?.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ] else if (subtitle != null) ...[
            Text(subtitle!),
            const SizedBox(height: 16),
          ],
          child,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ],
      ),
    ),
  );
}

enum LiquidGlassAlertTone { info, success, warning, error }

/// An inline announcement with optional action and dismissal.
class LiquidGlassAlert extends StatelessWidget {
  const LiquidGlassAlert({
    super.key,
    required this.title,
    required this.message,
    this.tone = LiquidGlassAlertTone.info,
    this.action,
    this.onDismiss,
    this.dismissLabel = 'Dismiss alert',
    this.settings,
  });

  final String title;
  final String message;
  final LiquidGlassAlertTone tone;
  final Widget? action;
  final VoidCallback? onDismiss;
  final String dismissLabel;
  final LiquidGlassSettings? settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (tone) {
      LiquidGlassAlertTone.info => theme.colorScheme.primary,
      LiquidGlassAlertTone.success => ColorScheme.fromSeed(
        seedColor: const Color(0xff208459),
        brightness: theme.brightness,
      ).primary,
      LiquidGlassAlertTone.warning => ColorScheme.fromSeed(
        seedColor: const Color(0xffb77d15),
        brightness: theme.brightness,
      ).primary,
      LiquidGlassAlertTone.error => theme.colorScheme.error,
    };
    final icon = switch (tone) {
      LiquidGlassAlertTone.info => Icons.info_outline_rounded,
      LiquidGlassAlertTone.success => Icons.check_circle_outline_rounded,
      LiquidGlassAlertTone.warning => Icons.warning_amber_rounded,
      LiquidGlassAlertTone.error => Icons.error_outline_rounded,
    };
    return Semantics(
      liveRegion: true,
      child: LiquidGlassSurface(
        settings: settings,
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Builder(
          builder: (context) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelIcon(icon: icon, color: accent, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: DefaultTextStyle.of(
                          context,
                        ).style.color?.withValues(alpha: 0.68),
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 12),
                      action!,
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  tooltip: dismissLabel,
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A modal glass prompt. Content can include a form or explanatory text.
class LiquidGlassPrompt extends StatelessWidget {
  const LiquidGlassPrompt({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.actions = const [],
    this.settings,
  });

  final String title;
  final Widget content;
  final IconData? icon;
  final List<Widget> actions;
  final LiquidGlassSettings? settings;

  /// Keeps Flutter's focus trapping, back navigation and safe-area behavior.
  /// The local material settings are captured before entering the modal route.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    LiquidGlassSettings? settings,
    bool barrierDismissible = true,
  }) {
    final config = settings ?? LiquidGlassTheme.of(context);
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        config.dynamicsIntensity == 0;
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32),
      transitionDuration: reduced
          ? Duration.zero
          : const Duration(milliseconds: 420),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          child,
      pageBuilder: (context, animation, secondaryAnimation) => SafeArea(
        child: LiquidGlassTheme(
          settings: config,
          child: GlassModalPresentation(child: Builder(builder: builder)),
        ),
      ),
    );
  }

  /// Returns true for confirmation, false for cancel, and null for dismissal.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Continue',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    LiquidGlassSettings? settings,
  }) => show<bool>(
    context,
    settings: settings,
    builder: (context) => LiquidGlassPrompt(
      title: title,
      icon: icon,
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    constraints: const BoxConstraints(maxWidth: 360),
    child: SingleChildScrollView(
      child: GlassModalSurface(
        settings: settings,
        borderRadius: BorderRadius.circular(32),
        padding: const EdgeInsets.all(24),
        child: Builder(
          builder: (context) {
            final foreground = DefaultTextStyle.of(context).style.color!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Center(child: _PanelIcon(icon: icon!, size: 52)),
                  const SizedBox(height: 18),
                ],
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DefaultTextStyle.merge(
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: foreground.withValues(alpha: 0.7),
                  ),
                  child: content,
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  FilledButtonTheme(
                    data: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    child: TextButtonTheme(
                      data: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: foreground.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: actions.reversed.toList(),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _PanelIcon extends StatelessWidget {
  const _PanelIcon({required this.icon, this.color, this.size = 44});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? DefaultTextStyle.of(context).style.color!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.10)),
      ),
      child: Icon(icon, size: size * 0.48, color: accent),
    );
  }
}
