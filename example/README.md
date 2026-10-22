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
pause background activity, or Glass quality to choose Balanced, Full refraction,
or Opaque rendering.
