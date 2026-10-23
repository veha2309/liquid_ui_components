# Architecture — v0.3.0 development

The public API is `lib/liquid_ui_components.dart`. This file contains exports
only. The three compatibility entrypoints export that same API; applications
should not import implementation files under `src/`.

| Module | Responsibility |
| --- | --- |
| `src/configuration/` | Immutable material settings, edge resolution and inherited theme |
| `src/surfaces/` | Surface layout, clipping, shadows, fallback blur and rim painting |
| `src/rendering/` | Shader loading, instance ownership, render objects, filter layers and uniform ABI |
| `shaders/` | Native backdrop sampling, refraction, dispersion, lighting and smooth union |
| `src/motion/` | Shared touch dynamics and accessibility motion adaptations |
| `src/scrolling/` | Scroll invalidation, overscroll policy and edge separation |
| `src/navigation/` | Destination model, public navigation widget, selection and scroll state |
| `src/components/` | Buttons, toolbar, selector, switch, slider, toast, morph and blend |

Configuration has no dependency on components or rendering. Rendering depends
on configuration, never on a specific control. Surfaces compose rendering and
content. Components own interaction, semantics and layout rather than GPU code.
Navigation is its own Dart library; its private implementation uses a `part`.
The rendering library likewise uses private parts for scene composition and
uniform packing without exposing those details through the package entrypoint.

`surfaces/glass_shadow_decoration.dart` owns shared shadow painting for surfaces,
navigation and optical blends. Shadows paint after the glass captures its backdrop
and are clipped to the exterior of the same outline. This avoids sampling the
surface's own shadow, including near the rim, when the first visible member of a
shared backdrop group changes during scrolling. Geometry is cached per painter;
the fix retains grouped frosted blur without adding a filter or an offscreen layer.

## Renderer policy

`LiquidGlassSettings.renderer` defaults to `LiquidGlassRenderer.stable`, backed
by the exact previously tested `liquid_glass_easy` 3.3.1 dependency. Third-party
types are contained in `rendering/stable_glass_backdrop.dart`. The structural
refactor does not require adopting the prototype renderer.

`LiquidGlassRenderer.experimentalNative` explicitly opts into the new shader.
Device testing exposed flicker reports and GPU frame spikes; this path is not
ready to replace the default. Its filter configuration is cached when uniforms
are unchanged and its shader uses an analytic gradient and five blur samples.
These optimizations alone did not establish visual correctness or smooth 120 Hz
rendering. Public rendering-quality modes remain independent of backend choice.

## Experimental rendering lifecycle

The immutable fragment program is loaded once on supported backends. Each lens
owns a separate mutable shader instance and disposes it on removal. The render
object retains its filter layer. Uniforms are refreshed during scene composition
from the current global transform, including when ancestors reuse painted layers.
No per-lens ticker, screenshot capture, polling timer or post-frame rebuild is
used to track scrolling. Local logical geometry and global physical sampling
coordinates are converted in the uniform packer. The shader uniform order is a
private ABI shared by that file and the fragment shader.

The shader handles rounded rectangle optics and the two-circle smooth union.
Custom morph outlines still clip a rectangular optical field, as in v0.2.1.
The same CPU outline clips the tint, content and shadow. Unsupported engines
use frosted glass; explicit solid mode, reduced transparency and high contrast
avoid optical rendering. Shader loading errors retain a tinted blur and report
the failure through Flutter's error mechanism.

## Development checks

Run `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`
and `flutter test` in the repository root. Build the example with
`flutter build apk --debug` from `example/`; this also compiles the shader asset.
Device integration tests live in `example/integration_test/` and exercise
blending, scrolling, interactions and performance.

The v0.3.0 renderer is under development. Automated fallback tests and successful
shader compilation cannot establish GPU visual parity or performance. Before
release, run the integration suite and inspect refraction, merged and separated
droplets, transformed/clipped surfaces, extreme scrolling, accessibility modes
and idle/animated frame timings on a connected Impeller device. Desktop, web and
iOS remain unvalidated. No v0.3.0 publication is implied by this branch.
