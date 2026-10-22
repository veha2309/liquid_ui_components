# Gallery performance check

Measured on the connected Samsung SM S721B (Android 16), using Flutter profile
mode and native FrameTiming callbacks after a warm-up scroll. These are single
runs, not a promise of sustained frame rates under all thermal/load conditions.

| Scroll measurement | Full-refraction baseline | Optimized Balanced |
| --- | ---: | ---: |
| Recorded frames | 257 | 310 |
| Average UI build | 2.25 ms | 0.99 ms |
| Average raster | 18.00 ms | 7.54 ms |
| 90th percentile raster | 27.24 ms | 9.85 ms |
| Raster frames above 16.67 ms | 137 | 0 |

Balanced trades optical refraction for shared frosted blur on the gallery's
surfaces. It retains translucency, tint, outlines and the backdrop artwork.
Full refraction remains available from Glass quality.

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
