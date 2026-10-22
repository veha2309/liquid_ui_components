# liquid_ui_components

Configurable liquid glass controls for Flutter: optical surfaces, buttons,
segmented selectors, sliders, switches, toolbars and bottom navigation.

[pub.dev](https://pub.dev/packages/liquid_ui_components) ·
[Source](https://github.com/veha2309/liquid_ui_components) ·
[Issues](https://github.com/veha2309/liquid_ui_components/issues) ·
[Interactive example](example/lib/main.dart)

<img src="screenshots/gallery.png" width="300" alt="Glass controls, sliding selector and volume slider over an animated background"> <img src="screenshots/favorite-heart.png" width="300" alt="Favorite button with a floating heart burst">

## Contents

- [Features and requirements](#features-and-requirements)
- [Installation](#installation)
- [Runnable quick start](#runnable-quick-start)
- [Components and usage](#components-and-usage)
- [Shared theme and configuration](#shared-theme-and-configuration)
- [Rendering, accessibility and scrolling](#rendering-accessibility-and-scrolling)
- [Performance](#performance)
- [Example app and development](#example-app-and-development)
- [Migration](#migration)

## Features and requirements

- Optical refraction, magnification, chromatic aberration, edge lighting and blur.
- Regular and clear presets; optical, frosted and opaque rendering choices.
- Global glass settings, per-component overrides and Material theme inheritance.
- Content-sized surfaces, accessible action buttons and wrapping toolbars.
- Controlled segmented selectors with a sliding glass pill and no Material press ripple.
- Filled sliders with an expanding glass thumb, optional glyph and RTL support.
- Controlled switches with standard Flutter input and toggle semantics.
- Bottom navigation with spring selection, badges, hold/drag previews and safe areas.
- Reduced-motion and high-contrast adaptations, plus a Reduce Transparency bridge.
- Shared frosted blur passes for nonoverlapping surfaces.

Requires **Flutter 3.44+** and **Dart 3.12.2+**. The optical renderer is
[`liquid_glass_easy`](https://pub.dev/packages/liquid_glass_easy) (`^3.3.1`).
This is a Flutter-rendered interpretation of liquid glass, not UIKit's native
material. No native iOS framework or platform plugin is required.

Android is the declared and device-tested platform. The rendering code is pure
Flutter and has a frosted fallback, but iOS, desktop and web have not been
validated by this package. The example includes an Android runner.

## Installation

```sh
flutter pub add liquid_ui_components
```

Or add this to your application's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  liquid_ui_components: ^0.2.0

flutter:
  uses-material-design: true
```

Import the public entrypoint:

```dart
import 'package:liquid_ui_components/liquid_ui_components.dart';
```

Material icons require `uses-material-design: true`. No shader asset registration,
manual shader preloading or platform permissions are needed in the host app.

## Runnable quick start

Replace your application's `lib/main.dart` with this example. The background is
real content behind the controls, so blur and transparency are visible.

```dart
import 'package:flutter/material.dart';
import 'package:liquid_ui_components/liquid_ui_components.dart';

void main() => runApp(const GlassDemo());

class GlassDemo extends StatefulWidget {
  const GlassDemo({super.key});

  @override
  State<GlassDemo> createState() => _GlassDemoState();
}

class _GlassDemoState extends State<GlassDemo> {
  double volume = 0.6;
  bool enabled = true;

  @override
  Widget build(BuildContext context) => MaterialApp(
    scrollBehavior: const LiquidGlassScrollBehavior(),
    theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    home: LiquidGlassTheme(
      settings: const LiquidGlassSettings(
        rendering: LiquidGlassRendering.frosted,
        blur: 8,
        opacity: 0.3,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffb7d4ff), Color(0xfff4bfdc)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LiquidGlassButton(
                        onPressed: () {},
                        child: const Text('Continue'),
                      ),
                      const SizedBox(height: 24),
                      LiquidGlassSlider(
                        value: volume,
                        semanticLabel: 'Volume',
                        thumbIcon: Icons.volume_up_rounded,
                        onChanged: (value) => setState(() => volume = value),
                      ),
                      const SizedBox(height: 24),
                      LiquidGlassSwitch(
                        value: enabled,
                        semanticLabel: 'Audio enabled',
                        onChanged: (value) => setState(() => enabled = value),
                      ),
                    ],
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
```

The quick start uses frosted glass for predictable performance. Switch to
`LiquidGlassRendering.automatic` to enable optical refraction on a supported
shader renderer. The sample background is intentionally simple; detailed
artwork behind the glass makes the effect more noticeable.

## Components and usage

All widgets accept Flutter's usual optional `key`. Except for navigation's
`glassSettings`, their local material override is named `settings`.

| Public API | Purpose |
| --- | --- |
| `LiquidGlassSurface` | Reusable glass backdrop with crisp foreground content |
| `LiquidGlassButton` | Text or custom-content action |
| `LiquidGlassIconButton` | Compact accessible icon action |
| `LiquidGlassToolbar` | Shared surface containing wrapping actions |
| `LiquidGlassSegmentedControl<T>` | Controlled, single-selection sliding glass selector |
| `LiquidGlassSlider` | Controlled range with a filled capsule and glass thumb |
| `LiquidGlassSwitch` | Controlled glass-backed toggle |
| `LiquidGlassNavigationBar` | Bottom navigation with a moving lens and hold/drag previews |
| `LiquidGlassNavigationItem` | Navigation destination data |
| `LiquidGlassTheme` | Inherited settings for a subtree |
| `LiquidGlassSettings` | Immutable material configuration |
| `LiquidGlassScrollBehavior` | Scroll behavior without a stretching edge decoration |

### Surface

```dart
LiquidGlassSurface(
  borderRadius: BorderRadius.circular(28),
  padding: const EdgeInsets.all(20),
  child: const Text('Floating controls'),
);
```

| Parameter | Default | Behavior |
| --- | --- | --- |
| `child` | Required | Determines the surface's dimensions; content stays above the optics |
| `settings` | Inherited | Replaces inherited settings for this surface |
| `borderRadius` | Circular 28 | Clip, outline and shadow geometry |
| `padding` | Zero | Space between the edge and content; accepts directional insets |

Put surfaces above actual content using a `Stack`. For a fixed-size surface,
wrap it in `SizedBox`. Prefer uniform circular corner radii for optical rendering;
the optical renderer uses the top-left radius for its lens. Use `frosted` when
you need asymmetric or elliptical radii. Rounded surfaces clip their children.

### Button and icon button

```dart
LiquidGlassButton(
  onPressed: save,
  tooltip: 'Save changes',
  child: const Text('Save'),
);

LiquidGlassIconButton(
  icon: const Icon(Icons.favorite_outline),
  tooltip: 'Add to favorites',
  onPressed: addFavorite,
);
```

| Button parameter | Default | Behavior |
| --- | --- | --- |
| `onPressed` | Required, nullable | Action callback; `null` disables the button |
| `child` | Required | Text or custom content |
| `settings` | Inherited | Local glass material |
| `padding` | Horizontal 20, vertical 12 | Content inset |
| `borderRadius` | Circular 28 | Button and surface shape |
| `tooltip` | `null` | Optional hint |
| `autofocus` | `false` | Requests initial keyboard focus |

`LiquidGlassIconButton` takes `icon`, required `tooltip`, nullable `onPressed`
and optional `settings`. It uses 12-pixel padding and a minimum 48 × 48 target.
Use the tooltip to describe the action, not the appearance of the icon.
Buttons preserve Flutter's focus, disabled state and activation behavior.

### Toolbar

```dart
LiquidGlassToolbar(
  spacing: 8,
  alignment: WrapAlignment.center,
  children: [
    IconButton(onPressed: play, tooltip: 'Play', icon: const Icon(Icons.play_arrow)),
    const Text('Now playing'),
    IconButton(onPressed: stop, tooltip: 'Stop', icon: const Icon(Icons.stop)),
  ],
);
```

| Parameter | Default | Behavior |
| --- | --- | --- |
| `children` | Required | Actions/content inside one shared glass surface |
| `settings` | Inherited | Local material |
| `padding` | All 8 | Outer content inset |
| `spacing` | 8 | Horizontal and wrapped-row spacing; nonnegative |
| `alignment` | `WrapAlignment.center` | Alignment of each wrapped row |

Use plain `IconButton`/`TextButton` children to share one material layer.
Actions wrap on narrow layouts and at large text scales.

### Segmented selector

```dart
LiquidGlassSegmentedControl<int>(
  selected: period,
  onSelectionChanged: (value) => setState(() => period = value),
  segments: const [
    ButtonSegment(value: 0, label: Text('Day')),
    ButtonSegment(value: 1, label: Text('Week')),
    ButtonSegment(value: 2, label: Text('Month')),
  ],
);
```

| Parameter | Default | Behavior |
| --- | --- | --- |
| `segments` | Required | At least two `ButtonSegment<T>` entries with unique values |
| `selected` | Required | One of the supplied values; owned by the host |
| `onSelectionChanged` | Required, nullable | Requests a selection; `null` disables interaction |
| `settings` | Inherited | Material and transition duration |
| `showSelectedIcon` | `false` | Enables Flutter's selected indicator icon |

Use `ButtonSegment.enabled` to disable an individual choice. The glass pill
moves to the controlled selection, follows RTL, and skips motion when requested.
The Material press ripple and pressed tint are suppressed; keyboard focus keeps
an outline. The host must update `selected` to accept a requested selection.
For long labels, wrap the control in a horizontal `SingleChildScrollView`.

### Slider and volume control

```dart
LiquidGlassSlider(
  value: volume,
  min: 0,
  max: 1,
  height: 64,
  activeColor: Colors.deepPurple,
  thumbIcon: Icons.volume_up_rounded,
  semanticLabel: 'Playback volume',
  label: '${(volume * 100).round()}%',
  onChanged: (value) => setState(() => volume = value),
  onChangeStart: (_) => beginPreview(),
  onChangeEnd: (value) => commitVolume(value),
);
```

| Parameter | Default | Behavior |
| --- | --- | --- |
| `value` | Required | Controlled finite value between `min` and `max` |
| `onChanged` | Required, nullable | Requests a value change; `null` disables input |
| `min` / `max` | 0 / 1 | Finite bounds; `min` must be less than `max` |
| `divisions` | `null` | Continuous when null; positive integer for discrete steps |
| `label` | `null` | Flutter slider value-indicator label |
| `semanticLabel` | `null` | Screen-reader description |
| `onChangeStart` / `onChangeEnd` | `null` | Start/end callbacks for committing or previewing changes |
| `settings` | Inherited | Material and press transition duration |
| `height` | 64 | Logical pixels; finite and at least 56 |
| `activeColor` | Theme primary | Filled track color |
| `thumbIcon` | `null` | Optional glyph; a grip is shown when omitted |

The filled capsule uses frosted glass in automatic mode, reserving refraction
for the smaller thumb. The thumb uses zero blur, a clear tint, fixed 1× backdrop
magnification and a deeper bevel on press; it expands without adding a Material
touch halo. A keyboard-focus highlight remains available. Reduced motion skips
expansion. A frosted/solid override applies to the thumb as well.

The thumb and Flutter's hit testing share the same track geometry, including
RTL and endpoints. The widget owns gesture animation, not the selected value.
It controls an application value; it does not change the device's system volume.
For frequent changes, use `ValueNotifier`/`ValueListenableBuilder` to rebuild only
the slider and its label, as demonstrated by the gallery.

### Switch

```dart
LiquidGlassSwitch(
  value: notificationsEnabled,
  semanticLabel: 'Notifications',
  onChanged: (value) => setState(() => notificationsEnabled = value),
);
```

Parameters: required `value`, required nullable `onChanged`, required
`semanticLabel`, optional `settings`, and `autofocus` (default `false`).
`null` disables interaction. Flutter's standard switch supplies focus, gestures,
keyboard input and toggle semantics on a glass surface. This component does not
reproduce UIKit's deforming switch thumb.

### Bottom navigation

```dart
Scaffold(
  extendBody: true,
  body: IndexedStack(index: selectedTab, children: pages),
  bottomNavigationBar: LiquidGlassNavigationBar(
    selectedIndex: selectedTab,
    onTap: (value) => setState(() => selectedTab = value),
    items: const [
      LiquidGlassNavigationItem(label: 'Home', icon: Icons.home_outlined),
      LiquidGlassNavigationItem(label: 'Search', icon: Icons.search),
      LiquidGlassNavigationItem(label: 'Messages', icon: Icons.chat_outlined, badge: '3'),
    ],
  ),
);
```

| Navigation parameter | Default | Behavior |
| --- | --- | --- |
| `items` | Required | Two to five destinations in logical reading order |
| `selectedIndex` | Required | Valid zero-based index, owned by the host |
| `onTap` | Required | Requests navigation; update `selectedIndex` to accept |
| `onScrubChanged` | `null` | Fractional logical position during hold/drag preview; `null` ends preview |
| `tintColor` | Theme primary | Active destination and original lens tint |
| `unselectedColor` | Theme onSurfaceVariant | Inactive destinations |
| `surfaceColor` | Theme surface | Original renderer's surface tint and configured selector's opaque fallback |
| `glassSettings` | Inherited, if present | Shared material settings for configured rendering |

Each `LiquidGlassNavigationItem` has required `label` and `icon`, plus optional
`badge` text. Labels are accessible; icons use the host's icon fonts.

The bar supports tap selection, a 180 ms hold, expanding spring motion, drag
selection, cancellation and host-controlled navigation. The host may decline a
selection by leaving `selectedIndex` unchanged. `onScrubChanged` never changes
routes; use it to drive an optional host-owned preview.

`LiquidGlassNavigationBar.height` is 96 logical pixels, excluding the bottom
safe area. Side margins are 20 pixels. Pad scrolling content by this height plus
`MediaQuery.paddingOf(context).bottom` so the last controls are accessible.
Use `extendBody: true` to show real content beneath the bar.

Without a `LiquidGlassTheme` or local `glassSettings`, the bar preserves its
original navigation material and three color overrides. Configured rendering
uses settings' `tintColor` for the base glass. Its selector keeps a clear tint,
zero blur and lift-responsive optical depth/magnification. Destination colors
still use `tintColor`/`unselectedColor`. Reduced motion disables hold previews,
lens expansion, refraction and spring navigation. Labels are bounded to a text
scale of 1.4; consider Flutter's standard `NavigationBar` for larger accessibility
text requirements.

## Shared theme and configuration

```dart
LiquidGlassTheme(
  settings: const LiquidGlassSettings(
    rendering: LiquidGlassRendering.frosted,
    tintColor: Colors.white,
    foregroundColor: Colors.black87,
    opacity: 0.3,
    blur: 8,
    borderWidth: 1,
  ),
  child: const MyScreen(),
);
```

Place the theme **under** `MaterialApp`, where a Material theme and MediaQuery
are available. Components follow light/dark `ThemeData`. Glass settings don't
replace typography, navigation state or the Material theme.

Precedence: local `settings` (navigation: `glassSettings`) → nearest
`LiquidGlassTheme` → default settings. A local object replaces the inherited
object as a whole. To change just one value, use:

```dart
final panelSettings = LiquidGlassTheme.of(context).copyWith(
  rendering: LiquidGlassRendering.frosted,
  blur: 12,
);
```

`LiquidGlassTheme.maybeOf(context)` returns null if no glass theme exists;
`of(context)` returns default settings in that case. `copyWith` supports every
field below. Null color arguments retain the existing color; create fresh
settings to reset colors to inherited Material defaults.

| `LiquidGlassSettings` field | Default | Configuration |
| --- | --- | --- |
| `variant` | `regular` | Adds 0.15 tint opacity in dark mode; `clear` omits this adjustment |
| `rendering` | `automatic` | Optical when supported, or choose `frosted`/`solid` |
| `tintColor` | Theme surface | Tint RGB; use `opacity` to control transparency |
| `foregroundColor` | Theme onSurface | Text/icon color; accessibility's opaque path picks contrast automatically |
| `opacity` | 0.30 | Tint opacity in [0, 1], clamped after dark adjustment |
| `blur` | 8 | Finite, nonnegative backdrop sigma in logical pixels |
| `saturation` | 1.2 | Finite, nonnegative optical saturation |
| `refraction` | 1.35 | Finite optical refraction strength, at least 1 |
| `depth` | 0.045 | Optical bevel depth in [0, 1] |
| `magnification` | 1 | Finite optical backdrop magnification, greater than 0 |
| `chromaticAberration` | 0.0005 | Optical color separation in [0, 1] |
| `borderWidth` | 1 | Finite, nonnegative outline width |
| `lightIntensity` | 0.65 | Finite, nonnegative optical edge lighting |
| `shadowBlur` | 18 | Finite, nonnegative shadow radius |
| `shadowOpacity` | 0.09 | Shadow alpha in [0, 1] |
| `animationDuration` | 200 ms | Nonnegative elevation/selector/slider transitions; navigation keeps its own spring |
| `reduceTransparency` | `false` | Host preference forcing opaque surfaces |

Numeric constraints are checked by assertions in development builds. Supply
valid finite inputs in production too. Optical-only settings do not change
frosted or solid rendering.

### Clear preset

```dart
const mediaGlass = LiquidGlassSettings.clear(
  tintColor: Colors.black,
  foregroundColor: Colors.white,
);
```

The clear constructor sets variant `clear`, opacity 0.08, blur 2, saturation
1.1, refraction 1.35, depth 0.06, magnification 1.015, chromatic aberration
0.0008, border width 1, light intensity 0.85, shadow blur 18, shadow opacity
0.12 and animation duration 200 ms. It accepts `tintColor`, `foregroundColor`
(default white), `rendering` (default automatic) and `reduceTransparency`.
Use `copyWith` to tune other values.

Setting only `variant: LiquidGlassVariant.clear` does not load all preset values.
Clear glass is intended for visually rich backgrounds; dim bright media behind
white controls and verify foreground contrast.

## Rendering, accessibility and scrolling

| Mode/condition | Result |
| --- | --- |
| `automatic` + shader support | Live optical lens |
| `automatic` without shader support | Clipped frosted blur and tint |
| `frosted` | Blur, tint, outline and shadow; no optical refraction |
| `solid` or `reduceTransparency: true` | Opaque tint; no backdrop filter |
| High contrast | Shared surfaces become opaque with automatically contrasting content |
| Reduced motion | Shared surfaces use frosted rendering; selector/slider transitions stop |

High contrast and reduced transparency take precedence over local color/material
choices. The opaque shared-surface path chooses a black or white foreground
from tint brightness, overriding `foregroundColor`. Flutter doesn't expose a
universal Reduce Transparency preference: bridge your application's platform or
user setting into `reduceTransparency`.

For stable scroll limits:

```dart
MaterialApp(
  scrollBehavior: const LiquidGlassScrollBehavior(),
  home: const MyScreen(),
);
```

Or apply the behavior around one scroll view using `ScrollConfiguration`.
It preserves platform scroll physics and input devices, while removing the
overscroll decoration that can stretch screen-space optics independently of
layout. Keep glass outside scale transforms when possible.

The original, unconfigured navigation renderer has its own accessibility
fallbacks; supply a glass theme/settings to use the shared surface behavior.
No glass renderer can guarantee contrast over every arbitrary background.

## Performance

Start with `frosted` for large surfaces. Use optical refraction selectively on
compact controls, especially when many surfaces are visible at once.

```dart
BackdropGroup(
  child: Column(
    children: [
      LiquidGlassSurface(
        settings: const LiquidGlassSettings(rendering: LiquidGlassRendering.frosted),
        child: const Padding(padding: EdgeInsets.all(16), child: Text('First panel')),
      ),
      const SizedBox(height: 16),
      LiquidGlassSurface(
        settings: const LiquidGlassSettings(rendering: LiquidGlassRendering.frosted),
        child: const Padding(padding: EdgeInsets.all(16), child: Text('Second panel')),
      ),
    ],
  ),
);
```

Nonoverlapping sibling frosted surfaces can share a `BackdropGroup` blur pass.
Each surface separates its nested content's backdrop group to avoid accidentally
sharing an overlapping child's input with its own. Do not group surfaces that
overlap each other. Keep static artwork in a separate `RepaintBoundary`, not a
flattened image of the complete glass scene.

The gallery starts in **Balanced** (frosted) mode. **Glass quality** also offers
**Full refraction** and **Opaque**. Its large settings panel and slider track
use frosted glass to reduce GPU cost; full refraction applies to compact lenses.
Animated background detail paints at 25 updates per second without rebuilding
controls. Pause it with the app-bar motion button; it pauses when inactive or
muted by `TickerMode` and respects reduced motion.

See [device measurements](example/PERFORMANCE.md). These are sample profile runs,
not frame-rate guarantees. Test on hardware with `flutter run --profile` or
`--release`; debug mode adds development overhead.

## Example app and development

```sh
git clone https://github.com/veha2309/liquid_ui_components.git
cd liquid_ui_components
flutter pub get
cd example
flutter pub get
flutter run --profile
```

The example includes light/dark themes, a detailed animated background, working
controls, a glass settings panel, a background pause button, quality selection,
and a favorite button with a floating heart burst. Background art, the pause UI
and the heart burst are **example-only implementations**, not additional public
package widgets. Copy/adapt [the example files](example/lib) if you want them in
your application. Favoriting updates demo state; it does not persist a backend
record. The app's volume control changes demo state, not system audio.

The Android runner is included. To generate other example runners for your own
validation, use `flutter create --platforms=web,ios,windows .` inside `example`
on a suitable host, then test the chosen platform's renderer.

From the repository root:

```sh
flutter analyze
flutter test
cd example
flutter test
cd ..
dart doc --output build/api-docs
dart pub publish --dry-run
```

Device checks from `example` (substitute a connected device ID):

```sh
flutter drive --profile --driver=test_driver/scroll_test.dart --target=integration_test/glass_scroll_test.dart -d DEVICE_ID
flutter drive --profile --driver=test_driver/scroll_test.dart --target=integration_test/glass_motion_test.dart -d DEVICE_ID
flutter drive --profile --driver=test_driver/performance_test.dart --target=integration_test/glass_performance_test.dart -d DEVICE_ID
```

The performance driver writes `example/build/performance/latest.json`.
The screenshot driver writes `example/build/scroll-check/`.

## Migration

This package expands the earlier navigation-only project. Pub.dev package names
are separate identities: change your dependency to `liquid_ui_components` and
run `flutter pub get`; renaming cannot redirect an existing dependency in place.

```dart
// Before:
// import 'package:liquid_retina_navigation/liquid_retina_navigation.dart';
// or: import 'package:liquid_glass_navigation/liquid_glass_navigation.dart';

// After:
import 'package:liquid_ui_components/liquid_ui_components.dart';
```

| Previous name | Preferred name |
| --- | --- |
| `LiquidRetinaNavigationBar` | `LiquidGlassNavigationBar` |
| `LiquidRetinaNavigationItem` | `LiquidGlassNavigationItem` |

Deprecated type aliases retain the previous class names under the new package.
Compatibility entrypoints `liquid_glass.dart`, `liquid_glass_navigation.dart` and
`liquid_retina_navigation.dart` also export the new API. Prefer the canonical
entrypoint for new code. Existing navigation callbacks, controlled selection,
color overrides and layout dimensions are preserved.

## Design references and license

Inspired by [Apple's materials guidance](https://developer.apple.com/design/human-interface-guidelines/materials)
and the [UI Layouts liquid glass reference](https://www.ui-layouts.com/components/liquid-glass).
Use glass sparingly for functional controls and verify legibility over real
content. Web reference features such as expandable/draggable cards aren't part
of this API.

Released under the [MIT license](LICENSE). The optical renderer has its own
[license](https://pub.dev/packages/liquid_glass_easy/license).
