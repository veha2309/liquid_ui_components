import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

class BlendingDemo extends StatefulWidget {
  const BlendingDemo({super.key});

  @override
  State<BlendingDemo> createState() => _BlendingDemoState();
}

class _BlendingDemoState extends State<BlendingDemo> {
  double viscosity = 0.5;
  int memberCount = 4;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Liquid blending', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text(
        'Drag any glass item in any direction. Bring them together to blend; pull apart to split. Tap an icon to use it.',
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: Text('$memberCount blend members')),
          IconButton(
            tooltip: 'Remove blend member',
            onPressed: memberCount > 0
                ? () => setState(() => memberCount--)
                : null,
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            tooltip: 'Add blend member',
            onPressed: () => setState(() => memberCount++),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = math.max(1, (width / 76).floor());
          return LiquidGlassBlend.builder(
            itemCount: memberCount,
            size: Size(
              width,
              math.max(
                240.0,
                math.max(1, (memberCount / columns).ceil()) * 90.0,
              ),
            ),
            settings: LiquidGlassTheme.of(context).copyWith(
              depth: 0.22 * (0.5 + viscosity),
              magnification: 1 + 0.08 * viscosity,
            ),
            itemBuilder: (context, index) => LiquidGlassBlendItem(
              key: ValueKey('demo-member-$index'),
              bounds: Rect.fromLTWH(
                (index % columns) * 72.0,
                (index ~/ columns) * 72.0,
                68,
                68,
              ),
              borderRadius: index.isEven ? 34 : 18,
              child: IconButton(
                tooltip: 'Blend action ${index + 1}',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  LiquidGlassToast(message: 'Action ${index + 1}'),
                ),
                icon: Icon(
                  [
                    Icons.home,
                    Icons.favorite,
                    Icons.music_note,
                    Icons.settings,
                  ][index % 4],
                ),
              ),
            ),
          );
        },
      ),
      Text('Viscosity ${(viscosity * 100).round()}%'),
      LiquidGlassSlider(
        value: viscosity,
        label: '${(viscosity * 100).round()}%',
        semanticLabel: 'Lens viscosity',
        onChanged: (value) => setState(() => viscosity = value),
      ),
    ],
  );
}
