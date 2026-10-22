import 'package:flutter/material.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

class BlendingDemo extends StatefulWidget {
  const BlendingDemo({super.key});

  @override
  State<BlendingDemo> createState() => _BlendingDemoState();
}

class _BlendingDemoState extends State<BlendingDemo> {
  bool playing = true;
  bool favorite = false;
  double viscosity = 0.5;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Liquid blending', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text(
        'Drag either glass in any direction. Bring them together to blend; pull apart to split. Tap an icon to use it.',
      ),
      const SizedBox(height: 12),
      LiquidGlassBlend.draggable(
        size: const Size(360, 240),
        radius: 42,
        smoothness: 40,
        viscosity: viscosity,
        settings: LiquidGlassTheme.of(context).copyWith(
          depth: 0.22,
          refraction: 1.5,
          magnification: 1.08,
          refractionWidth: 20,
          lightIntensity: 1.2,
        ),
        first: IconButton(
          tooltip: playing
              ? 'Pause blending playback'
              : 'Play blending playback',
          onPressed: () => setState(() => playing = !playing),
          icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
        ),
        second: IconButton(
          tooltip: 'Toggle favorite track',
          onPressed: () => setState(() => favorite = !favorite),
          icon: Icon(
            favorite ? Icons.favorite_rounded : Icons.music_note_rounded,
          ),
        ),
      ),
      Text('Viscosity ${(viscosity * 100).round()}%'),
      Slider(
        value: viscosity,
        label: '${(viscosity * 100).round()}%',
        semanticFormatterCallback: (value) =>
            'Lens viscosity ${(value * 100).round()} percent',
        onChanged: (value) => setState(() => viscosity = value),
      ),
    ],
  );
}
