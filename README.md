# liquid_retina_navigation

A Flutter bottom navigation capsule designed for Android, with liquid glass
refraction, spring animation, badges, and hold/drag selection. Extracted from
the Android navigation implementation used in Mahila Mitr.

Requires Flutter 3.44+ and Dart 3.12.2+. The optical renderer uses
`liquid_glass_easy` ^3.3.1. There is no native plugin or iOS dependency.

## Install

```yaml
dependencies:
  liquid_retina_navigation: ^0.1.0
```

To consume the Git release instead:

```yaml
dependencies:
  liquid_retina_navigation:
    git:
      url: https://github.com/veha2309/liquid_retina_navigation.git
      ref: v0.1.0
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:liquid_retina_navigation/liquid_retina_navigation.dart';

// In your stateful screen; selectedIndex and pages belong to the host.
Scaffold(
  extendBody: true,
  body: IndexedStack(index: selectedIndex, children: pages),
  bottomNavigationBar: LiquidRetinaNavigationBar(
    selectedIndex: selectedIndex,
    onTap: (index) => setState(() => selectedIndex = index),
    items: const [
      LiquidRetinaNavigationItem(label: 'Home', icon: Icons.home_outlined),
      LiquidRetinaNavigationItem(label: 'Search', icon: Icons.search),
      LiquidRetinaNavigationItem(label: 'Profile', icon: Icons.person_outline),
    ],
  ),
);
```

Use two to five destinations. Colors inherit the host Material theme; override
`tintColor`, `unselectedColor`, or `surfaceColor` when needed. Icons use the
host's font declarations; enable `uses-material-design` for Material icons.
Pass `badge` on an item to display a badge.

The host owns navigation and may decline a selection by keeping its current
`selectedIndex`. A hold of 180 ms enlarges the lens. Dragging previews adjacent
destinations; releasing requests selection. `onScrubChanged` reports fractional
logical tab positions and `null` on commit/cancellation, allowing the host to
animate page previews without changing routes.

The layout is 96 logical pixels plus the bottom safe area, with 20-pixel side
margins. Pad scrolling content by `LiquidRetinaNavigationBar.height` plus the
device bottom inset to keep its last controls clear of the capsule.

RTL and high contrast are supported. Reduced motion disables lens expansion,
spring motion, refraction and preview callbacks. High contrast and unsupported
shader renderers use a frosted fallback. For very large text, the host can
substitute a standard `NavigationBar`.

## Example and validation

`example/lib/main.dart` contains a three-tab app with light/dark themes.
To run on a device, generate its platform runner first:

```sh
cd example
flutter create --platforms=android .
flutter run
```

```sh
flutter pub get
flutter analyze
flutter test
dart pub publish --dry-run
```

Tests cover theme inheritance, overrides, invalid inputs, controlled selection,
hold/drag selection, cancellation, badges, insets, RTL, large text and shader
loading. Device rendering should also be checked on the target Android hardware.
