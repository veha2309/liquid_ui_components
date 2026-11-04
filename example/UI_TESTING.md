# Testing the gallery with ui_tester

The optional test package in `example/optional_ui_tests/` integrates the local `ui_tester` and `ui_tester_cli` packages as
development dependencies. They are not runtime dependencies of the gallery or
the published liquid glass package. Use Flutter 3.47.5 / Dart 3.13 or newer.

Until ui_tester is published, `pubspec.yaml` points to the existing checkout at
`../../../../ui_tester/packages/` relative to the optional test package. Adjust the two paths if
you move either checkout. Run every command below from `example/optional_ui_tests/`.

```sh
flutter pub get
dart run ui_tester_cli:ui_tester doctor --target integration_test/ui_tester_test.dart
```

Ensure Flutter, Dart and Android SDK `platform-tools` are on PATH for device runs.
No global CLI activation is required.

## Repeatable smoke flow

```sh
dart run ui_tester_cli:ui_tester test --widget --target test/ui_tester_test.dart
dart run ui_tester_cli:ui_tester test --target integration_test/ui_tester_test.dart --device DEVICE_ID
```

The same scenario also runs directly with `flutter test test/ui_tester_test.dart`.
It operates the actual gallery: save feedback, repeated favorites, expanding and
collapsing the morph, activity selection, volume and blur dragging, repeated switch
changes, navigation, themes, and adding/removing blend members inside the dialog.
Dialogs are included by a root UiTestScope. The adapter scrolls to controls before
operating them and uses pointer events rather than calling application callbacks.

Checks verify collection feedback, favorite state, selected activity and slider
bounds. Framework exceptions and interaction failures fail the run. Background
motion is disabled for repeatable readiness; glass-control animations still run.
This flow checks interactions, not shader pixel correctness or GPU performance.
Keep the existing glass brightness, scroll pixel and performance tests for those.

## Automatic exploration

```sh
dart run ui_tester_cli:ui_tester test --widget --target test/ui_tester_exploration.dart --seed 42 --max-actions 200
dart run ui_tester_cli:ui_tester test --target integration_test/ui_tester_exploration.dart --device DEVICE_ID --seed 42 --max-actions 200
```

Exploration discovers visible controls, tries interaction bursts, resets the
gallery and replays prefixes. Custom adapters expose glass buttons, sliders,
switches, navigation and selectors with stable keys. Native controls use the
package's built-in discovery. Decorative painting is not interactive coverage.

The gallery has many combinations. Exhausting the action/time budget produces
**incomplete** and a nonzero exit code, never a passing coverage claim. Increase
`--max-actions` or `--duration-ms` for longer runs. Exploration entrypoints are
explicit targets so normal test discovery runs the repeatable smoke test only.
An `unchanged_ui` observation needs review; it can be expected after an even
toggle burst or when selecting the current destination.

## Reports and replay

CLI runs create separate directories in `ui_tester_runs/`, ignored by Git,
containing JSON, HTML, JUnit and per-finding traces. Screenshots are disabled.

```sh
dart run ui_tester_cli:ui_tester report ui_tester_runs/RUN_DIRECTORY
dart run ui_tester_cli:ui_tester replay ui_tester_runs/RUN_DIRECTORY/TRACE.trace.json --widget --target test/ui_tester_test.dart
```

Use the exploration target instead when replaying an exploration finding. Use
`--device DEVICE_ID` and the matching integration target to replay on Android.
Direct Flutter runs save JSON to `ui_tester_runs/latest` on the host; the CLI is
needed to collect reports from Android. Do not treat screenshots or interaction
metrics as proof that refraction is visually correct.

## Integration verification

The widget smoke flow completed all 18 scripted actions through the CLI and
generated HTML, JSON and JUnit reports. The one-action exploration wiring check
returned `incomplete` with no findings, as expected for its deliberately tiny
budget. CLI doctor and Flutter analysis passed; the existing 86 package tests
also passed.

The Android CLI attempt did not complete while the connected phone was locked
and no scenario snapshots were received. On-device verification remains pending:
unlock the phone, leave its screen on, then rerun the device command above with
a fresh output directory. The adapter and widget results do not establish device
rendering correctness.

