# Gallery performance history

For the **v0.3.0 release measurements from 4 November 2026**, use the
[current performance guide](../doc/PERFORMANCE.md). It includes fresh Frosted
and Opaque runs after the navigation fix, frame-budget counts, source hashes
and explicit low-end device limits. The older runs below are historical and
must not be used as a controlled before/after comparison.

### Android frame timings — 29 October 2026

Measured on a Samsung SM S721B, Android 17 (API 37), Flutter 3.47.5 stable,
**profile mode**, 1080 x 2340 display observed at **120 Hz**. This is the component
gallery with **Frosted** glass and the current shared-motion optimizations, not
Arc Tracker or a comparison of optical quality modes. USB charging; battery
34.1 C near the start. Adaptive refresh was not locked.

| Scenario | Frames | UI avg (ms) | Raster avg (ms) | Raster p95 (ms) | Raster >8.33 ms | Raster >16.67 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Morph, static backdrop | 1,321 | 1.43 | 7.27 | 10.29 | 589/1321 | 8/1321 |
| Morph, animated backdrop | 1,310 | 1.55 | 7.06 | 9.70 | 598/1310 | 5/1310 |
| Scrolling | 718 | 1.53 | 10.97 | 12.78 | 708/718 | 1/718 |
| Slider dragging | 685 | 1.32 | 11.23 | 12.11 | 684/685 | 1/685 |

Raster cost is the main budget pressure in this run: UI averages are below
1.6 ms, but scrolling and slider raster averages exceed the 8.33 ms budget for
120 Hz. Raster maxima were 25.91 ms (static morph), 45.98 ms (animated morph),
16.82 ms (scroll), and 84.05 ms (slider). This run does **not** demonstrate
consistent 120 fps, nor a measured before/after improvement.

Six morph open/close cycles follow two warm-up cycles. The integration binding
uses `fullyLive` so intermediate animation frames are sampled; settle/wait
frames are included. The initial interrupted run using long test pumps was
discarded because it skipped intermediate morph frames. Build and raster are
pipelined stages: do not add their averages or interpret the exceedance counts
as OS-presented dropped frames. Results are one warm run and vary with thermal
state, backdrop, quality and refresh rate.

Full p90/p95/max, stage budget counts, total-span latency and conditions:
[recorded profile report](performance/2026-10-29-sm-s721b-profile.json).
Reproduce with the command in [performance notes](../README.md#example-app-and-development).

## Historical measurements and implementation notes

The following measurements predate the current run and are retained for context.
They use different workloads and must not be treated as a before/after comparison.

The v0.2.1 widget regression check now retains the morph's static panel paint
once across 35 sampled animation frames (previously 30 repaints). Contour paths
are shared between the rim, clip and shadow, blur filters are reused, and default
material transitions keep blur/shadow kernel sizes stable. These are CPU/paint
work reductions, not new device frame-time measurements.

The profile driver now records `morph_static_background` and
`morph_live_background` scenarios alongside scroll and volume. Run it on a target
phone to measure raster costs; the historical timings below predate v0.2.1.

Measured on the connected Samsung SM S721B (Android 16), using Flutter profile
mode and native FrameTiming callbacks after a warm-up scroll. These are single
runs, not a promise of sustained frame rates under all thermal/load conditions.

| Scroll measurement | Full-refraction baseline | Historical frosted mode (then labelled Balanced) |
| --- | ---: | ---: |
| Recorded frames | 257 | 310 |
| Average UI build | 2.25 ms | 0.99 ms |
| Average raster | 18.00 ms | 7.54 ms |
| 90th percentile raster | 27.24 ms | 9.85 ms |
| Raster frames above 16.67 ms | 137 | 0 |

The historical Balanced label selected shared frosted blur in these runs. In
v0.2.1, Balanced selects actual optical refraction with chromatic dispersion
disabled; Frosted is the separate blur-only option. These timings do not measure
the current Balanced renderer and should not be used as its performance claim.

The optimized volume interaction recorded 276 frames: average UI build 1.89 ms,
average raster 8.35 ms, and 6 raster frames above 16.67 ms. It does not maintain
an 8.33 ms (120 Hz) budget consistently. The volume benchmark now explicitly
centers the control before dragging, so its raster results should not be treated
as an exact comparison with the original run.

Changes include isolating volume updates with a ValueNotifier, sharing frosted
blur through BackdropGroup, skipping the thumb's redundant blur pass, keeping
the large panel on frosted glass, and caching background artwork separately
from live glass. Nested surfaces get separate groups so overlapping layers
cannot accidentally reuse their parent's backdrop input.

Reproduce from the example directory:

```sh
flutter drive --profile --driver=test_driver/performance_test.dart --target=integration_test/glass_performance_test.dart -d YOUR_DEVICE_ID
```

The driver saves build/performance/latest.json. Compare runs on the same device,
with the same quality, refresh rate, workload and temperature. Use
`flutter run --profile` for manual testing; debug mode adds development overhead.

With the animated backdrop enabled (25 paint updates/sec), a subsequent profile
run recorded scrolling raster average 7.37 ms (302 frames, 2 above 16.67 ms) and
volume raster average 7.93 ms (252 frames, 2 above 16.67 ms). The animation uses a
separate repaint notifier rather than rebuilding controls. The current benchmark
uses bounded waits because a running ambient animation never settles; these
results are a responsiveness check, not an exact comparison with the static run.
