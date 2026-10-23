## 0.3.0-dev.1 (unreleased)

* Paint surface shadows outside their outlines so shared backdrop captures do
  not pick up a surface's own shadow when earlier siblings leave the viewport.
  Apply this centrally to controls, panels and custom shapes, retaining grouped blur.
* Reproduce the large-panel brightness jump on a fixed-color backdrop, then
  verify stable center RGB values before and after top-edge clipping on device.

* Isolate overlapping switch/slider thumb backdrop groups from their track.
* Use an opaque, untinted app bar while retaining normal viewport clipping.
* Add physical-device pixel regressions across scrolling/clipping in Frosted,
  Balanced and Full modes, separate from input/gesture regression tests.

* Cancel switch hold optics as soon as vertical scrolling takes over, without
  toggling the value; reset stale pointers on disabling and deactivation.
* Connect stable optical surfaces and blend passes to scroll paint invalidation
  so retained lens layers update at their new position before paint.

* Slim slider and switch tracks to roughly 28 logical pixels while retaining
  48-pixel interaction height. Use 24/28-pixel resting thumbs and 36/40-pixel held
  bubbles with stronger magnification. Only the held thumb opts into balanced
  optics from Frosted mode; solid/reduced-transparency settings remain respected.

* Expand switch and slider thumb bubbles on hold, lower their tint and blur for
  clear glass, and restore their resting material on release or cancellation.
  Keep explicit rendering modes and accessibility adaptations respected.

* Fix multi-item blending in Frosted mode with a shared smooth-union outline.
  Groups larger than six use the same contour with a shared optical surface
  rather than independent six-member passes that could not merge.
* Use glass toasts and sliders throughout the gallery and blending demo; add a
  glass switch thumb while retaining native switch input and semantics.

* Organize implementation into configuration, surfaces, motion, scrolling,
  navigation, components and rendering modules; preserve public entrypoints.
* Add an experimental package-owned backdrop shader for rounded surfaces,
  navigation optics and smooth-union droplet blending. Restore the exact stable
  3.3.1 renderer as the default behind an adapter after phone regression reports;
  native rendering requires LiquidGlassRenderer.experimentalNative.
* Separate shader loading, render objects, scene composition and uniform packing.
* Update integration checks to exercise the native renderer and its shader asset.
* Retain frosted/solid modes and high-contrast/reduced-motion adaptations.

* Reproduce GPU frame-time spikes on the connected Samsung; keep the native
  prototype opt-in, fix its layer update lifecycle and cache unchanged uniforms.
* Use analytic shape gradients and a lower-cost blur kernel in the prototype.
* Temporarily start the gallery in Frosted while retaining all quality choices.
* Add a profile-mode performance driver that saves frame timing reports.
* Fix the gallery background painter throwing on zero-size startup layouts;
  guard both background layers and test resizing from zero to a valid width.

Native-renderer flicker remains unresolved; replacing the stable renderer is
not release-ready. Device performance reports describe the temporary workaround.
This development version is not a published release.

## 0.2.1 (2026-10-22)

* Add LiquidGlassBlend with controlled separation and a freely draggable,
  bounded two-droplet playground. Nearby droplets fuse through a shared
  refractive surface while distant and diagonal drags preserve their size.
* Add optical viscosity controls that scale refraction, depth and magnification
  independently of inherited blur and tint, preserving each droplet's actions
  and accessible movement commands.
* Add LiquidGlassRendering.balanced for real refraction without chromatic
  dispersion, alongside explicit Full refraction, Frosted and Opaque choices.
* Use the blending shader's own blur path to retain merged optical rendering
  in transformed and clipped Android play areas.
* Add inline and dialog blending examples, viscosity controls, and device
  screenshot checks for separated, merged and diagonal-drag states.
* Expand the README with complete API examples, settings behavior, rendering
  requirements, accessibility, troubleshooting and migration guidance.

* Restore optical rendering by default in the gallery and place themed
  navigation icons beneath the lens so refraction and magnification are visible.
* Restore the selector's full optical bevel, resting magnification and stronger
  press/drag refraction while retaining explicit frosted/opaque overrides.

* Add opt-in scroll-responsive navigation with compact icons, hysteresis,
  stable tap/drag geometry, reverse-list handling and accessibility adaptations.
* Add configurable rim direction, refraction band width, size-aware bevels,
  ambient rim light and highlight spread, including a refined frosted rim.
* Add navigation and rim-light controls to the gallery and cover scroll-boundary
  resizing, controller replacement and directional rim pixels.

* Add LiquidGlassScrollEdge with soft/hard styles, physical-edge awareness for
  reversed lists, content-resize support and paint-only scrolling updates.
* Add scroll-edge separation and a comparison toggle to the component gallery.

* Add the public LiquidGlassToast component and show helper, with floating glass,
  entry/exit motion, native dismissal and accessibility, and gallery integration.

* Reduce morph repainting with retained panel content, shared contour paths and
  cached blur filters; reveal target actions before the spring settling tail.
* Add shared liquid dynamics to buttons, toolbars, switches and slider thumbs,
  plus spring-driven segmented selectors and a global dynamics intensity.
* Add cancellation/reduced-motion coverage, a gallery dynamics toggle, and
  device profiling scenarios for morphing over static and animated backgrounds.

* Add LiquidGlassMorph for continuous control-to-panel size, corner and material
  transitions, with reversible animation and reduced-motion support.
* Add an expandable quick-controls example to the gallery.
* Refine morphing with momentum-preserving spring motion, directional stretch,
  soft corner and light response, and overlapping content reveals.
* Replace rectangular morph scaling with a droplet contour shared by the clip,
  rim and shadow, with staggered width/height growth and calmer settling.
* Move a persistent shared title between the button and panel header without
  fading, and shorten the default morph pace.

This snapshot retains the existing liquid_glass_easy renderer and Android-only
validation. An independent renderer and broader platform validation are future
work and are not included in this version.

## 0.2.0

* Rename the package and primary import to liquid_ui_components.
* Add LiquidGlassNavigationBar and LiquidGlassNavigationItem, retaining
  deprecated aliases for the previous LiquidRetina names.
* Add configurable surfaces, action/icon buttons, wrapping toolbars, sliding
  segmented selectors, filled glass-thumb sliders and glass-backed switches.
* Add shared material settings, regular/clear presets, optical/frosted/solid
  rendering, accessibility overrides and an overscroll behavior for glass.
* Share frosted blur across sibling surfaces and isolate volume updates.
* Include an Android gallery with animated artwork, pause controls, a heart
  burst, a glass settings panel, quality selection and device performance checks.
* Document every component, configuration field, example and migration path.

## 0.1.0 (navigation-only predecessor)

* Extract Android liquid glass navigation into a standalone Flutter package.
* Preserve optical refraction, spring selection, hold/drag previews, badges,
  RTL layout, safe areas, theme inheritance and accessibility fallbacks.
