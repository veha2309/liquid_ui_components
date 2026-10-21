import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

part 'src/liquid_retina_bar.dart';

/// A destination in a [LiquidRetinaNavigationBar].
@immutable
class LiquidRetinaNavigationItem {
  /// Creates an icon and label, with an optional badge.
  const LiquidRetinaNavigationItem({
    required this.label,
    required this.icon,
    this.badge,
  });

  /// Accessible destination label displayed below the icon.
  final String label;

  /// Icon from the host app's declared icon fonts.
  final IconData icon;

  /// Optional badge text.
  final String? badge;
}

/// A controlled liquid glass navigation capsule designed for Android.
///
/// The host owns routing and [selectedIndex]. Use `Scaffold(extendBody: true)`
/// to let the lens refract the content behind it. Supports two to five tabs.
class LiquidRetinaNavigationBar extends StatelessWidget {
  /// Creates a navigation capsule using the surrounding Material theme.
  LiquidRetinaNavigationBar({
    super.key,
    required List<LiquidRetinaNavigationItem> items,
    required this.selectedIndex,
    required this.onTap,
    this.onScrubChanged,
    this.tintColor,
    this.unselectedColor,
    this.surfaceColor,
  }) : items = List.unmodifiable(items) {
    if (items.length < 2 || items.length > 5) {
      throw ArgumentError.value(items.length, 'items.length', 'Use 2–5 tabs.');
    }
    if (selectedIndex < 0 || selectedIndex >= items.length) {
      throw RangeError.index(selectedIndex, items, 'selectedIndex');
    }
  }

  /// Layout height excluding the device's bottom safe area.
  static const double height = 96;

  /// Destinations in logical reading order.
  final List<LiquidRetinaNavigationItem> items;

  /// Destination selected by the host.
  final int selectedIndex;

  /// Requests selection; the host may accept or reject the destination.
  final ValueChanged<int> onTap;

  /// Fractional logical tab position after a hold and during dragging.
  /// `null` ends or cancels preview. This callback never changes routes.
  final ValueChanged<double?>? onScrubChanged;

  /// Active color, defaulting to [ColorScheme.primary].
  final Color? tintColor;

  /// Inactive color, defaulting to [ColorScheme.onSurfaceVariant].
  final Color? unselectedColor;

  /// Surface tint, defaulting to [ColorScheme.surface].
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _AndroidGlassBar(
      items: items,
      selectedIndex: selectedIndex,
      onTap: onTap,
      onScrubChanged: onScrubChanged,
      tintColor: tintColor ?? colors.primary,
      unselectedColor: unselectedColor ?? colors.onSurfaceVariant,
      surfaceColor: surfaceColor ?? colors.surface,
    );
  }
}
