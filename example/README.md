# Liquid UI Components gallery

An Android example of `liquid_ui_components` with a detailed animated backdrop,
light/dark themes, sliding glass selector, volume control, glass settings panel,
and favorite heart animation.

```sh
flutter pub get
flutter run --profile
```

The main package's [README](../README.md) describes all public components and
configuration options. See [PERFORMANCE.md](PERFORMANCE.md) for device timing
measurements and the repeatable performance test.

The backdrop and favorite animation are example implementations in `lib/`.
They are not exported by the package. Use the motion button in the app bar to
pause background activity. **Glass quality** selects:

| Mode | Result |
| --- | --- |
| Full refraction | Background distortion and magnification, with colour dispersion. |
| Balanced | Background distortion and magnification, with colour dispersion disabled. |
| Frosted | Blur and tint without lens distortion. |
| Opaque | A solid surface without a visible backdrop. |

Optical modes require shader-filter support and fall back to frosted glass when
unavailable. High contrast and Reduce Transparency force opaque glass.

Use **Blur** to soften the background and **Tint opacity** to change the strength
of the coloured glass. Lower values make optical distortion easier to see. The
inline blend follows both settings. The large settings panel and slider track
remain frosted in either optical mode.

Tap **Blending** in the app bar to open the droplet play area. Drag either drop in
any direction; only nearby edges fuse, and distant droplets keep their diameter.
The **Viscosity** slider controls lens thickness and bending, independently of
blur and tint. Close and reopen the dialog after changing the main screen's
material settings. Tap the icons to use their demo actions.

Tap **Save collection**, then **Undo**, to restore the previous local saved state.
Tap **Quick controls** to expand the morphing panel. These examples change local
demo state; they do not persist data or control system audio.

For device verification and screenshots:

```sh
flutter drive --driver=test_driver/blend_test.dart --target=integration_test/glass_blend_test.dart -d DEVICE_ID
```

Captures are written to `build/blend-check/`. See the main README's
[blending guide](../README.md#liquid-blending-and-draggable-droplets),
[snackbar guide](../README.md#toast-and-snackbar-actions) and
[troubleshooting](../README.md#troubleshooting) for API details and fallbacks.
