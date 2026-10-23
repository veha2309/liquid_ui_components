# Samsung device investigation — 2026-10-23

Device: SM S721B / RZCY71CKL3M. Flutter profile mode, same gallery scenario.
Times below are raster/GPU-stage milliseconds, not end-to-end input latency.

| Run | Scroll mean | Scroll p90 | Volume mean | Volume p90 |
| --- | --- | --- | --- | --- |
| before | 9.12 | 12.58 | 9.63 | 13.24 |
| after_blur | 9.13 | 13.09 | 8.29 | 12.7 |
| stable | 20.9 | 26.57 | 25.59 | 30.07 |
| stable_balanced | 16.92 | 21.37 | 20.42 | 20.86 |
| frosted | 7.81 | 10.82 | 8.06 | 10.13 |

`before` is the native prototype. `after_blur` adds lifecycle caching, analytic
normals and five-sample blur. `stable` restores the exact 3.3.1 renderer in full
refraction mode. `stable_balanced` disables dispersion. `frosted` is the temporary
gallery default. Library settings retain their original quality default; native
rendering requires explicit experimental opt-in.

These are sequential single-device measurements, not controlled statistical
benchmarks; temperature, load and scheduling vary. Timed scroll and volume drags
provide hundreds of samples. The morph scenario advances its animation in coarse
steps and has only 24 samples, so those results do not establish morph-animation
smoothness. No consistent 120 Hz performance claim is made.

The prototype's reported background/edge flicker is unresolved. Stable optical
blending passed both device integration tests with debug assertions. The gallery
workaround avoids the unstable optical path; it does not fix native refraction.

Reproduce from example/ with:

```
flutter drive --profile --driver test_driver/performance.dart --target integration_test/glass_performance_test.dart -d RZCY71CKL3M
```

The driver saves build/glass_performance.json. Set GLASS_PERFORMANCE_REPORT to
choose a different output file. UI/runtime errors are not ignored by the test.

A standalone gallery launch also exposed a zero-size background-painter division
by zero. Both background layers now reject empty/non-finite sizes before
computing their scale, with a regression test. Final suite: 77 tests passed.

## Top-edge scroll investigation

An initial investigation left viewport paint bounds unclipped beneath the app
bar. The later large-panel reproduction proved capture sharing caused the reported
brightness jump; normal list clipping has been restored. The initial panel isolation workaround has since been replaced by shared shadow painting (below). Overlapping switch and slider thumbs have separate backdrop
groups from their track. This follows Flutter's requirement that overlapping
filters must not share a backdrop key.

`example/integration_test/glass_scroll_pixels_test.dart` compares immediate and
settled RGBA output at the same scroll position. It uses a paused gallery background,
excludes intentional compact-navigation animation, and tests Frosted, Balanced and
Full optics. The held drag check samples eight drag steps. Both device tests passed;
filtered output is in scroll-pixels.txt. The test is not a claim about every
continuous-scroll frame or every possible renderer configuration.

The separate repeating-grid diagnostic logs translation differences near the
physical screen boundary. Those can differ when the sampling kernel reaches
outside the rendered viewport; they are not asserted equal to a fully visible
lens. The checked invariant is that the shader does not change after the scroll
frame has settled at the same position.

## Large-panel brightness reproduction

User screenshots exposed a gap in the earlier same-position tests: a stable but
incorrect brightness change across different scroll positions. The new physical
regression uses a constant-color background, fixed Blur 11 / Tint 33%, and a
650-pixel panel. Before isolation its center changed from RGB 137/157/170 to
133/150/162 at offset 60, failing the test. After giving the large settings panel
its own BackdropGroup, all five checked offsets, including top clipping, remained
133/150/162. See panel-brightness-before.txt and panel-brightness-after.txt.
The dedicated regression is example/integration_test/glass_panel_brightness_test.dart.

## Shared shadow correction

The isolated panel workaround did not address other components. Disabling shadows
while retaining the original shared group kept the bright RGB 137/157/170 at
every offset, identifying self-shadow capture as the source of the brightness jump.
Normal BoxShadow painting fills the glass interior before its backdrop filter runs.
When an earlier grouped member leaves the viewport, the capture can start including
that fill. Exterior shadow pixels can also leak through blur near the rim.

All surfaces now use a common exterior shadow painted after the backdrop, also
used by navigation and the optical two-member blend. The settings panel no longer
has its own special BackdropGroup. This retains shared frosted blur and adds no
backdrop filter or offscreen saveLayer. The physical regression samples center
and rim across scroll positions for 48, 120 and 650 logical pixel surfaces in
Frosted, Balanced and Full modes, plus a custom outline. Captures include the full
screen so the optical shader's global coordinates remain valid; each case asserts
that sampled glass differs from the plain background before comparing offsets.
The corrected device brightness suite passed all 12 cases; output is in
`global-surface-brightness.txt`. Frosted center and rim stayed at RGB
137/157/170 with default shadows. Full/Balanced readings stayed within one channel
value of their starting readings. The gallery same-position scroll checks also
passed in all three modes (`global-scroll-pixels.txt`). These tests cover the
stable backend, not the experimental native prototype.

`global-shadow-performance.json` records the subsequent profile run: scrolling
averaged 9.34 ms raster time (p90 12.16 ms, 1/288 frames above 16.67 ms); slider
dragging averaged 10.08 ms (p90 12.62 ms, 6/249 above 16.67 ms). Earlier Frosted
measurements were 7.81/8.06 ms, but include intervening control/rendering changes
and were not a paired or thermally controlled comparison. This does not establish
zero performance cost or consistent 120 Hz rendering.