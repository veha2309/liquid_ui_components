"""Turn recorded Flutter FrameTiming summaries into the release report.

Requires matplotlib. Inputs are produced by the Android profile driver.
"""
import hashlib
import json
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/performance/v0.3.0'
OUT.mkdir(parents=True, exist_ok=True)
digest = hashlib.sha256()
for path in sorted([*ROOT.glob('lib/**/*.dart'), *ROOT.glob('shaders/*')]):
    digest.update(path.relative_to(ROOT).as_posix().encode())
    digest.update(path.read_bytes().replace(b'\r\n', b'\n'))

labels = {
    'morph_static_background': 'Morph / static backdrop',
    'morph_live_background': 'Morph / animated backdrop',
    'scroll': 'Scrolling', 'volume': 'Slider dragging',
    'prompt_live_background': 'Prompt / animated backdrop',
    'panel_live_background': 'Panel / animated backdrop',
}
reports = {}
for mode in ('frosted', 'solid'):
    scenarios = json.loads((ROOT / f'example/build/release-performance-{mode}.json').read_text())
    metadata = {
        'date': '2026-11-04', 'package_version': '0.3.0',
        'device': 'Samsung SM-S721B', 'android': '17 (API 37)',
        'flutter': '3.47.5 stable', 'dart': '3.13.4', 'build_mode': 'profile',
        'rendering': mode, 'renderer': 'stable (liquid_glass_easy 3.3.1)',
        'display': '1080 x 2340, adaptive refresh not locked; 60/120 Hz budgets reported as reference',
        'conditions': 'USB charging; 39.9 C observed before initial run, 40.1 C after initial comparison; not thermally controlled',
        'source_lib_and_shaders_sha256': digest.hexdigest(),
        'source_hash_method': 'sorted repository-relative lib/*.dart and shader paths, followed by file bytes with CRLF normalized to LF',
        'method': 'Flutter native FrameTiming, fullyLive binding, warm-up cycles, six measured open/close cycles; waiting/settle frames included',
        'limitations': [
            'One sequential warm run per mode; not a paired, randomized or thermally controlled comparison',
            'No low-end Android hardware measured; not a device compatibility certification',
            'Build and raster are pipelined; do not add them or convert stage durations into delivered FPS',
            'Budget exceedances count stage timings, not OS-presented dropped frames',
            'Full/Balanced optics and experimental native rendering not benchmarked for this release',
            'Frosted gallery includes optical hold feedback on small slider/switch thumbs',
            'Screenshot readback and GIF recording performed in separate runs',
        ],
    }
    report = {'metadata': metadata, 'scenarios': scenarios}
    (OUT / f'2026-11-04-sm-s721b-{mode}.json').write_text(json.dumps(report, indent=2) + '\n')
    reports[mode] = report

text = '''# Android frame times and compatibility — v0.3.0

Measured on **Samsung SM-S721B**, Android 17/API 37, Flutter 3.47.5 stable /
Dart 3.13.4, **profile mode**, 1080 × 2340, on 4 November 2026.
Adaptive refresh was not locked. USB charging; observed temperatures around
40 °C. These are sequential single warm runs, not a controlled comparison.

**Low-end Android compatibility is unverified.** No low-end phone was available.
The results describe this device and gallery workload only. The 60 Hz budget is
16.67 ms and the 120 Hz budget is 8.33 ms **per pipelined UI/raster stage**.
Passing an average budget alone does not establish smooth delivery; inspect
p95, maxima and exceedance counts too. No sustained 120 fps claim is made.

![Raster p95 versus display budgets](../screenshots/v0.3.0/frame-times.png)

'''
for mode, title in [('frosted', 'Frosted'), ('solid', 'Opaque')]:
    text += f'## {title}\n\n| Scenario | Frames | UI avg | UI p95 | Raster avg | Raster p95 | Raster max | Raster >16.67 ms | Raster >8.33 ms |\n'
    text += '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n'
    for key, value in reports[mode]['scenarios'].items():
        n, ui, raster = value['frames'], value['build'], value['raster']
        text += f"| {labels[key]} | {n:,} | {ui['average_ms']:.2f} | {ui['p95_ms']:.2f} | {raster['average_ms']:.2f} | {raster['p95_ms']:.2f} | {raster['max_ms']:.2f} | {raster['over_16_67_ms']}/{n} | {raster['over_8_33_ms']}/{n} |\n"
    text += f'\nAll durations are milliseconds. [Full JSON, p90/p95/max and total-span timings](performance/v0.3.0/2026-11-04-sm-s721b-{mode}.json).\n\n'
text += '''## Choosing settings for constrained devices

Start with `LiquidGlassRendering.solid` for the smallest backdrop workload.
Try Frosted on small, bounded surfaces if blur matters; reduce `blur`, avoid
overlapping filters, and pause animated backgrounds. Use `BackdropGroup` only
for nonoverlapping siblings. Reserve Full/Balanced optical refraction for compact
controls after profiling on your target GPU. There is no automatic hardware-tier
detector; select settings explicitly and provide an Opaque option.

```dart
LiquidGlassTheme(
  settings: const LiquidGlassSettings(
    rendering: LiquidGlassRendering.solid,
    dynamicsIntensity: 0.5,
  ),
  child: MyAppContent(),
)
```

Reduced motion disables decorative transitions. High contrast and the explicit
Reduce Transparency bridge force opaque surfaces. Test both steady scrolling
and held/dragged controls; a cheap idle scene can still have expensive interaction
frames. Android is the declared platform; iOS, web and desktop remain unvalidated.

## Method and limits

The integration binding runs `fullyLive`, allowing intermediate frames between
actions. Two warm-up morph/prompt/panel cycles precede six measured open/close
cycles. Scroll and slider tests warm the renderer and use repeated timed drags.
Wait/settle frames are included; numbers are scenario-level distributions, not
isolated transition-only costs. Static morph measurement pauses the backdrop;
other scenarios retain the gallery's animated backdrop. Frosted hold feedback
can use Balanced optics on the small slider/switch thumb.

Native `FrameTiming` callbacks supply build, raster and total-span durations.
UI and raster are pipelined: do not add averages, calculate displayed FPS from
their reciprocals, or call exceedance counts dropped frames. Different sample
counts can reflect display scheduling; they do not imply equal-workload FPS.
Thermals, charging, background processes, refresh adaptation and gallery layout
affect results. Full/Balanced and experimental-native quality were not measured
in these release runs. Earlier failed harness runs were discarded.

The JSON reports contain a SHA-256 of the library and shader source. Historical
investigations remain in [the versioned archive](performance/v0.3.0/README.md)
and are not evidence of an improvement over this release.

## Reproduce on your own device

From `example/` with an unlocked Android device, repeat for each mode:

```sh
flutter drive --profile --driver=test_driver/performance.dart --target=integration_test/glass_performance_test.dart --dart-define=GLASS_PERFORMANCE_QUALITY=frosted -d DEVICE_ID
flutter drive --profile --driver=test_driver/performance.dart --target=integration_test/glass_performance_test.dart --dart-define=GLASS_PERFORMANCE_QUALITY=solid -d DEVICE_ID
```

Set `GLASS_PERFORMANCE_REPORT` to separate output paths for each run; by default
the driver writes `example/build/glass_performance.json`. Record temperature,
charging, OS, SDK, renderer and refresh policy; repeat several runs on actual
low-end hardware before making a compatibility claim. Do not capture screenshots
or screen recordings during the measurement. To rebuild this document and chart
from the release report paths, run `python tool/summarize_release_performance.py`
(requires matplotlib).
'''
(ROOT / 'doc/PERFORMANCE.md').write_text(text, encoding='utf-8')

plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 10})
fig, ax = plt.subplots(figsize=(11, 5.5), facecolor='#f8fafc')
ax.set_facecolor('#f8fafc')
keys = list(labels)
y = list(range(len(keys)))
for mode, offset, color, label in [('frosted', -0.18, '#7764bd', 'Frosted'), ('solid', 0.18, '#298a7d', 'Opaque')]:
    values = [reports[mode]['scenarios'][key]['raster']['p95_ms'] for key in keys]
    bars = ax.barh([i + offset for i in y], values, height=0.32, color=color, label=label)
    ax.bar_label(bars, fmt='%.2f', padding=4, fontsize=9)
ax.axvline(8.33, color='#64748b', linestyle='--', linewidth=1, label='120 Hz budget: 8.33 ms')
ax.axvline(16.67, color='#b45309', linestyle='--', linewidth=1, label='60 Hz budget: 16.67 ms')
ax.set_yticks(y, list(labels.values()))
ax.invert_yaxis()
ax.set_xlabel('Raster p95 (ms) — lower is better')
ax.set_title('v0.3.0 · Samsung SM-S721B · profile mode', loc='left', weight='bold', pad=18)
ax.spines[['top', 'right', 'left']].set_visible(False)
ax.grid(axis='x', alpha=0.12)
ax.set_axisbelow(True)
ax.set_xlim(0, max(22, max(reports[m]['scenarios'][k]['raster']['p95_ms'] for m in reports for k in keys) + 4))
ax.legend(loc='lower center', bbox_to_anchor=(0.5, -0.35), ncol=2, frameon=False)
fig.text(0.02, 0.02, 'One warm run per mode · adaptive refresh unlocked · low-end hardware unverified', color='#475569', fontsize=9)
fig.subplots_adjust(left=0.25, right=0.96, top=0.87, bottom=0.27)
fig.savefig(ROOT / 'screenshots/v0.3.0/frame-times.png', dpi=160)
plt.close(fig)
print('Wrote versioned reports, performance guide and chart')
