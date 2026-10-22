import 'package:flutter/material.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

import 'gallery_backdrop.dart';
import 'favorite_button.dart';

void main() => runApp(const GlassGallery());

class GlassGallery extends StatefulWidget {
  const GlassGallery({super.key, this.animateBackground = true});
  final bool animateBackground;
  @override
  State<GlassGallery> createState() => _GlassGalleryState();
}

class _GlassGalleryState extends State<GlassGallery> {
  int index = 0;
  int segment = 0;
  final volume = ValueNotifier(0.6);
  double blur = 8;
  double opacity = 0.3;
  bool dark = false;
  bool clear = false;
  bool reduceTransparency = false;
  bool playing = false;
  bool backgroundMotion = true;
  LiquidGlassRendering rendering = LiquidGlassRendering.frosted;

  @override
  void dispose() {
    volume.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    scrollBehavior: const LiquidGlassScrollBehavior(),
    theme: ThemeData(colorSchemeSeed: const Color(0xff6247aa)),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xff6247aa),
      brightness: Brightness.dark,
    ),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: LiquidGlassTheme(
      settings: LiquidGlassSettings(
        variant: clear ? LiquidGlassVariant.clear : LiquidGlassVariant.regular,
        opacity: clear ? 0.08 : opacity,
        blur: clear ? 2 : blur,
        rendering: rendering,
        reduceTransparency: reduceTransparency,
      ),
      child: Builder(
        builder: (context) => Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: const Text('Liquid Glass Studio'),
            actions: [
              IconButton(
                tooltip: backgroundMotion
                    ? 'Pause background'
                    : 'Animate background',
                onPressed: () =>
                    setState(() => backgroundMotion = !backgroundMotion),
                icon: Icon(
                  backgroundMotion
                      ? Icons.motion_photos_on_outlined
                      : Icons.motion_photos_paused_outlined,
                ),
              ),
              IconButton(
                tooltip: dark ? 'Light theme' : 'Dark theme',
                onPressed: () => setState(() => dark = !dark),
                icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
              ),
            ],
          ),
          body: GalleryBackdrop(
            dark: dark,
            animated: widget.animateBackground && backgroundMotion,
            child: BackdropGroup(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  LiquidGlassNavigationBar.height +
                      MediaQuery.paddingOf(context).bottom +
                      24,
                ),
                children: [
                  Text(
                    [
                      'Floating controls',
                      'Playback controls',
                      'Material settings',
                    ][index],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Live glass over a colorful backdrop. Try the controls, then tune the material below.',
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LiquidGlassButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saved to your collection'),
                              ),
                            ),
                        child: const Text('Save collection'),
                      ),
                      const FavoriteGlassButton(),
                      const LiquidGlassButton(
                        onPressed: null,
                        child: Text('Unavailable'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: LiquidGlassSegmentedControl<int>(
                        selected: segment,
                        onSelectionChanged: (value) =>
                            setState(() => segment = value),
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Day')),
                          ButtonSegment(value: 1, label: Text('Week')),
                          ButtonSegment(value: 2, label: Text('Month')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${['daily', 'weekly', 'monthly'][segment]} activity',
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LiquidGlassToolbar(
                      children: [
                        IconButton(
                          tooltip: playing ? 'Pause' : 'Play',
                          onPressed: () => setState(() => playing = !playing),
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        ),
                        Text(playing ? 'Now playing' : 'Ready to play'),
                        IconButton(
                          tooltip: 'Stop',
                          onPressed: () => setState(() => playing = false),
                          icon: const Icon(Icons.stop),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<double>(
                    valueListenable: volume,
                    builder: (context, currentVolume, _) => Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Volume',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Text(
                              '${(currentVolume * 100).round()}%',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LiquidGlassSlider(
                          value: currentVolume,
                          thumbIcon: currentVolume == 0
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          semanticLabel: 'Playback volume',
                          onChanged: (value) => volume.value = value,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LiquidGlassSurface(
                    key: const ValueKey('glass-settings-panel'),
                    // A large panel keeps the material but skips a full-panel
                    // refraction pass. Small controls still use optical lenses.
                    settings: LiquidGlassTheme.of(context).copyWith(
                      rendering: rendering == LiquidGlassRendering.automatic
                          ? LiquidGlassRendering.frosted
                          : rendering,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configure the material',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(child: Text('Clear variant')),
                              LiquidGlassSwitch(
                                value: clear,
                                semanticLabel: 'Clear variant',
                                onChanged: (value) =>
                                    setState(() => clear = value),
                              ),
                            ],
                          ),
                          const Text(
                            'Clear is for media backgrounds. Dim bright media behind controls.',
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Reduce transparency'),
                            value: reduceTransparency,
                            onChanged: (value) =>
                                setState(() => reduceTransparency = value),
                          ),
                          DropdownButtonFormField<LiquidGlassRendering>(
                            initialValue: rendering,
                            decoration: const InputDecoration(
                              labelText: 'Glass quality',
                            ),
                            items: LiquidGlassRendering.values
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(switch (value) {
                                      LiquidGlassRendering.automatic =>
                                        'Full refraction',
                                      LiquidGlassRendering.frosted =>
                                        'Balanced',
                                      LiquidGlassRendering.solid => 'Opaque',
                                    }),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => rendering = value!),
                          ),
                          const SizedBox(height: 16),
                          Text('Blur ${blur.round()}'),
                          Slider(
                            value: blur,
                            min: 0,
                            max: 24,
                            onChanged: clear
                                ? null
                                : (value) => setState(() => blur = value),
                          ),
                          Text('Tint opacity ${(opacity * 100).round()}%'),
                          Slider(
                            value: opacity,
                            min: 0,
                            max: 1,
                            onChanged: clear
                                ? null
                                : (value) => setState(() => opacity = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: LiquidGlassNavigationBar(
            selectedIndex: index,
            onTap: (value) => setState(() => index = value),
            items: const [
              LiquidGlassNavigationItem(
                label: 'Controls',
                icon: Icons.widgets_outlined,
              ),
              LiquidGlassNavigationItem(
                label: 'Playback',
                icon: Icons.music_note_outlined,
              ),
              LiquidGlassNavigationItem(label: 'Settings', icon: Icons.tune),
            ],
          ),
        ),
      ),
    ),
  );
}
