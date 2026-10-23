import 'package:flutter/material.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

import 'gallery_backdrop.dart';
import 'favorite_button.dart';
import 'blending_demo.dart';

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
  final scrollController = ScrollController();
  double blur = 8;
  double opacity = 0.3;
  bool dark = false;
  bool clear = false;
  bool reduceTransparency = false;
  bool liquidDynamics = true;
  bool scrollEdges = true;
  bool scrollNavigation = true;
  double lightDirection = 115;
  double edgeWidth = 8;
  bool playing = false;
  bool collectionSaved = false;
  bool morphExpanded = false;
  bool backgroundMotion = true;
  // Keep the demo usable while native refraction is under device validation.
  LiquidGlassRendering rendering = LiquidGlassRendering.frosted;

  @override
  void dispose() {
    volume.dispose();
    scrollController.dispose();
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
        dynamicsIntensity: liquidDynamics ? 1 : 0,
        lightDirection: lightDirection,
        refractionWidth: edgeWidth,
      ),
      child: Builder(
        builder: (context) => Scaffold(
          extendBody: true,
          appBar: AppBar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 1),
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: const Text('Liquid Glass Studio'),
            actions: [
              TextButton(
                onPressed: () {
                  final settings = LiquidGlassTheme.of(context);
                  showDialog<void>(
                    context: context,
                    builder: (context) => LiquidGlassTheme(
                      settings: settings,
                      child: Dialog(
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: 360,
                          height: 520,
                          child: GalleryBackdrop(
                            dark: dark,
                            animated: false,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const BlendingDemo(),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close demo'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Blending'),
              ),
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
              child: LiquidGlassScrollEdge(
                topExtent: 32,
                bottomExtent:
                    LiquidGlassNavigationBar.height +
                    MediaQuery.paddingOf(context).bottom +
                    24,
                opacity: scrollEdges ? 0.72 : 0,
                child: ListView(
                  controller: scrollController,
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
                          onPressed: () {
                            final previous = collectionSaved;
                            setState(() => collectionSaved = true);
                            LiquidGlassToast.show(
                              context,
                              message: 'Saved to your collection',
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  if (mounted) {
                                    setState(() => collectionSaved = previous);
                                  }
                                },
                              ),
                            );
                          },
                          child: Text(
                            collectionSaved
                                ? 'Collection saved'
                                : 'Save collection',
                          ),
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
                      alignment: AlignmentDirectional.topStart,
                      child: LiquidGlassMorph(
                        expanded: morphExpanded,
                        collapsedSize: const Size(160, 56),
                        expandedSize: const Size(320, 216),
                        sharedChild: Text(
                          'Quick controls',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        collapsedSharedAlignment:
                            AlignmentDirectional.centerStart,
                        collapsedSharedPadding:
                            const EdgeInsetsDirectional.fromSTEB(44, 0, 8, 0),
                        expandedSharedPadding:
                            const EdgeInsetsDirectional.fromSTEB(16, 30, 64, 0),
                        collapsedChild: Semantics(
                          label: 'Expand quick controls',
                          child: TextButton(
                            onPressed: () =>
                                setState(() => morphExpanded = true),
                            child: const Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Icon(Icons.tune_rounded),
                            ),
                          ),
                        ),
                        expandedChild: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Collapse controls',
                                    onPressed: () =>
                                        setState(() => morphExpanded = false),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () =>
                                            setState(() => playing = !playing),
                                        icon: Icon(
                                          playing
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                        ),
                                        label: Text(
                                          playing
                                              ? 'Pause playback'
                                              : 'Play music',
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            setState(() => dark = !dark),
                                        icon: Icon(
                                          dark
                                              ? Icons.light_mode
                                              : Icons.dark_mode,
                                        ),
                                        label: Text(
                                          dark
                                              ? 'Light appearance'
                                              : 'Dark appearance',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                            icon: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                            ),
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
                        rendering:
                            (rendering == LiquidGlassRendering.automatic ||
                                rendering == LiquidGlassRendering.balanced)
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
                            Row(
                              children: [
                                const Expanded(child: Text('Liquid dynamics')),
                                LiquidGlassSwitch(
                                  value: liquidDynamics,
                                  semanticLabel: 'Liquid dynamics',
                                  onChanged: (value) =>
                                      setState(() => liquidDynamics = value),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Scroll edge separation'),
                                ),
                                LiquidGlassSwitch(
                                  value: scrollEdges,
                                  semanticLabel: 'Scroll edge separation',
                                  onChanged: (value) =>
                                      setState(() => scrollEdges = value),
                                ),
                              ],
                            ),
                            const Text(
                              'Clear is for media backgrounds. Dim bright media behind controls.',
                            ),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Scroll-responsive navigation'),
                                ),
                                LiquidGlassSwitch(
                                  value: scrollNavigation,
                                  semanticLabel: 'Scroll-responsive navigation',
                                  onChanged: (value) =>
                                      setState(() => scrollNavigation = value),
                                ),
                              ],
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(
                                () => reduceTransparency = !reduceTransparency,
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text('Reduce transparency'),
                                  ),
                                  LiquidGlassSwitch(
                                    value: reduceTransparency,
                                    semanticLabel: 'Reduce transparency',
                                    onChanged: (value) => setState(
                                      () => reduceTransparency = value,
                                    ),
                                  ),
                                ],
                              ),
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
                                          'Frosted',
                                        LiquidGlassRendering.balanced =>
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
                            LiquidGlassSlider(
                              value: blur,
                              min: 0,
                              max: 24,
                              onChanged: clear
                                  ? null
                                  : (value) => setState(() => blur = value),
                            ),
                            Text('Tint opacity ${(opacity * 100).round()}%'),
                            LiquidGlassSlider(
                              value: opacity,
                              min: 0,
                              max: 1,
                              onChanged: clear
                                  ? null
                                  : (value) => setState(() => opacity = value),
                            ),
                            Text('Rim light ${lightDirection.round()}°'),
                            LiquidGlassSlider(
                              value: lightDirection,
                              min: 0,
                              max: 360,
                              onChanged: (value) =>
                                  setState(() => lightDirection = value),
                            ),
                            Text(
                              'Optical edge width ${edgeWidth.toStringAsFixed(1)}',
                            ),
                            LiquidGlassSlider(
                              value: edgeWidth,
                              min: 0,
                              max: 16,
                              onChanged:
                                  (rendering ==
                                              LiquidGlassRendering.automatic ||
                                          rendering ==
                                              LiquidGlassRendering.balanced) &&
                                      !reduceTransparency
                                  ? (value) => setState(() => edgeWidth = value)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const BlendingDemo(),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: LiquidGlassNavigationBar(
            scrollController: scrollController,
            shrinkOnScroll: scrollNavigation,
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
