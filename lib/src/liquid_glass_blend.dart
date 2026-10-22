import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart' as optical;
import 'liquid_glass_surface.dart';

/// Two circular controls that fuse into one refractive liquid surface.
///
/// [separation] is the distance between lens centers, in logical pixels.
/// Animate it with a spring for continuous fusion and separation. On Impeller,
/// the merged field bends the live backdrop around both lobes and their neck.
/// Other engines use a matching frosted silhouette. Children keep their own
/// actions and semantics; glass is decorative and does not handle gestures.
class LiquidGlassBlend extends StatelessWidget {
  const LiquidGlassBlend({
    super.key,
    required this.first,
    required this.second,
    required this.separation,
    this.radius = 48,
    this.smoothness = 40,
    this.viscosity = 0.5,
    this.settings,
  }) : playgroundSize = null,
       _firstCenter = null,
       _secondCenter = null,
       _canvasSize = null,
       assert(radius > 0 && radius < double.infinity),
       assert(viscosity >= 0 && viscosity <= 1),
       assert(separation >= 0 && separation < double.infinity),
       assert(smoothness > 0 && smoothness < double.infinity);

  /// A bounded play area where users drag either lens in two dimensions.
  /// Positions are owned internally and retained when the parent rebuilds.
  LiquidGlassBlend.draggable({
    super.key,
    required this.first,
    required this.second,
    this.radius = 48,
    this.smoothness = 40,
    this.viscosity = 0.5,
    this.settings,
    Size size = const Size(320, 240),
  }) : playgroundSize = size,
       _firstCenter = null,
       _secondCenter = null,
       _canvasSize = null,
       separation = 0,
       assert(size.width > 0 && size.width < double.infinity),
       assert(size.height > 0 && size.height < double.infinity),
       assert(radius > 0 && radius < double.infinity),
       assert(viscosity >= 0 && viscosity <= 1),
       assert(smoothness > 0 && smoothness < double.infinity);

  final Widget first;
  final Widget second;
  final double separation;
  final double radius;

  /// Maximum fusion softness at contact. Its influence fades to zero once
  /// the edge gap reaches min(16 logical pixels, 35% of the radius).
  final double smoothness;

  /// Artistic optical thickness, from flat glass (0) to a deeper liquid lens
  /// (1). Scales refraction, magnification and depth; 0.5 preserves [settings].
  /// Does not change opacity, blur, diameter or the distance at which drops fuse.
  /// This is a visual control, rather than a physical viscosity measurement.
  final double viscosity;
  final LiquidGlassSettings? settings;
  final Size? playgroundSize;
  final Offset? _firstCenter;
  final Offset? _secondCenter;
  final Size? _canvasSize;

  LiquidGlassBlend._positioned({
    required this.first,
    required this.second,
    required Offset firstCenter,
    required Offset secondCenter,
    required Size size,
    required this.radius,
    required this.smoothness,
    required this.viscosity,
    this.settings,
  }) : _firstCenter = firstCenter,
       _secondCenter = secondCenter,
       _canvasSize = size,
       separation = (secondCenter - firstCenter).distance,
       playgroundSize = null;

  @override
  Widget build(BuildContext context) {
    if (playgroundSize != null) return _DraggableBlend(blend: this);
    final config = settings ?? LiquidGlassTheme.of(context);
    final gap = math.max(0.0, separation - radius * 2);
    final proximity = (1 - gap / math.min(16.0, radius * 0.35)).clamp(0.0, 1.0);
    final blendWidth = math.max(
      0.001,
      smoothness * proximity * proximity * (3 - 2 * proximity),
    );
    final theme = Theme.of(context);
    final solid =
        config.reduceTransparency ||
        MediaQuery.highContrastOf(context) ||
        config.rendering == LiquidGlassRendering.solid;
    final opticalEnabled =
        !solid &&
        (config.rendering == LiquidGlassRendering.automatic ||
            config.rendering == LiquidGlassRendering.balanced) &&
        ui.ImageFilter.isShaderFilterSupported;
    final tint = (config.tintColor ?? theme.colorScheme.surface).withValues(
      alpha: config.opacity,
    );
    final foreground = config.foregroundColor ?? theme.colorScheme.onSurface;
    final edges = config.resolveEdgeOptics(Size.square(radius * 2));
    final lensStrength = viscosity * 2;
    final style = optical.LiquidGlassStyle(
      shape: optical.LiquidGlassShape.roundedRectangle(
        cornerRadius: radius,
        borderWidth: config.borderWidth,
        lightIntensity: config.lightIntensity,
        lightDirection: config.lightDirection % 360,
        borderType: optical.OpticalBorder(
          ambientIntensity: config.edgeAmbientIntensity,
          lightSpread: config.edgeLightSpread,
        ),
      ),
      appearance: optical.LiquidGlassAppearance(
        color: tint,
        saturation: config.saturation,
        blur: optical.LiquidGlassBlur(sigmaX: config.blur, sigmaY: config.blur),
      ),
      refraction: optical.LiquidGlassRefraction(
        magnification: math.max(
          0.01,
          1 + (config.magnification - 1) * lensStrength,
        ),
        chromaticAberration: config.rendering == LiquidGlassRendering.balanced
            ? 0
            : config.chromaticAberration,
        refractionType: optical.OpticalRefraction(
          refraction: 1 + (config.refraction - 1) * lensStrength,
          refractionWidth: edges.refractionWidth,
          depth: (edges.depth * lensStrength).clamp(0.0, 1.0),
        ),
      ),
    );
    Widget member(Widget child) => opticalEnabled
        ? optical.LiquidGlassLens(
            style: style,
            child: Center(child: child),
          )
        : Center(child: child);
    final members = SizedBox(
      width: _canvasSize?.width ?? separation + radius * 2,
      height: _canvasSize?.height ?? radius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (_firstCenter?.dx ?? radius) - radius,
            top: (_firstCenter?.dy ?? radius) - radius,
            width: radius * 2,
            height: radius * 2,
            child: member(first),
          ),
          Positioned(
            left: (_secondCenter?.dx ?? separation + radius) - radius,
            top: (_secondCenter?.dy ?? radius) - radius,
            width: radius * 2,
            height: radius * 2,
            child: member(second),
          ),
        ],
      ),
    );
    final surface = opticalEnabled
        ? optical.LiquidGlassBlender(
            style: style,
            smoothness: blendWidth,
            // The composed engine-blur path loses the merged field on the
            // Android device under transformed/clipped play areas. Keep blur
            // in the metaball shader so its sampling coordinates stay global.
            useEngineBlur: false,
            child: members,
          )
        : LiquidGlassSurface(
            settings: config.copyWith(animationDuration: Duration.zero),
            shape: _firstCenter == null
                ? _BlendedLenses(
                    distance: separation,
                    radius: radius,
                    smoothness: blendWidth,
                  )
                : _PositionedBlendBorder(
                    first: _firstCenter,
                    second: _secondCenter!,
                    radius: radius,
                    smoothness: blendWidth,
                  ),
            child: members,
          );
    return IconTheme.merge(
      data: IconThemeData(color: foreground),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: surface,
      ),
    );
  }
}

class _DraggableBlend extends StatefulWidget {
  const _DraggableBlend({required this.blend});
  final LiquidGlassBlend blend;

  @override
  State<_DraggableBlend> createState() => _DraggableBlendState();
}

class _DraggableBlendState extends State<_DraggableBlend> {
  final _arena = GlobalKey();
  final _positions = [const Offset(0.15, 0.42), const Offset(0.85, 0.58)];
  final _lastPointer = <int, Offset>{};

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.blend.playgroundSize!.width,
    height: widget.blend.playgroundSize!.height,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final r = math.min(widget.blend.radius, size.shortestSide / 2);
        final travel = Size(
          math.max(0, size.width - r * 2),
          math.max(0, size.height - r * 2),
        );
        Offset center(int i) => Offset(
          r + _positions[i].dx * travel.width,
          r + _positions[i].dy * travel.height,
        );
        void move(int i, Offset delta) => setState(() {
          final p = center(i) + delta;
          _positions[i] = Offset(
            travel.width == 0
                ? 0.5
                : ((p.dx - r) / travel.width).clamp(0.0, 1.0),
            travel.height == 0
                ? 0.5
                : ((p.dy - r) / travel.height).clamp(0.0, 1.0),
          );
        });
        final a = center(0);
        final b = center(1);
        Widget handle(int i, Widget child) => Semantics(
          label: 'Movable glass ${i + 1}',
          hint: 'Drag to blend with the other glass',
          customSemanticsActions: {
            CustomSemanticsAction(label: 'Move left'): () =>
                move(i, const Offset(-20, 0)),
            CustomSemanticsAction(label: 'Move right'): () =>
                move(i, const Offset(20, 0)),
            CustomSemanticsAction(label: 'Move up'): () =>
                move(i, const Offset(0, -20)),
            CustomSemanticsAction(label: 'Move down'): () =>
                move(i, const Offset(0, 20)),
          },
          child: GestureDetector(
            key: ValueKey('blend-drag-$i'),
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) => _lastPointer[i] = details.globalPosition,
            onPanStart: (details) =>
                _lastPointer.putIfAbsent(i, () => details.globalPosition),
            onPanUpdate: (details) {
              final box =
                  _arena.currentContext!.findRenderObject()! as RenderBox;
              final previous = _lastPointer[i] ?? details.globalPosition;
              move(
                i,
                box.globalToLocal(details.globalPosition) -
                    box.globalToLocal(previous),
              );
              _lastPointer[i] = details.globalPosition;
            },
            onPanEnd: (_) => _lastPointer.remove(i),
            onPanCancel: () => _lastPointer.remove(i),
            child: SizedBox.square(
              dimension: r * 2,
              child: Center(child: child),
            ),
          ),
        );
        return ClipRect(
          child: Stack(
            key: _arena,
            clipBehavior: Clip.none,
            children: [
              LiquidGlassBlend._positioned(
                firstCenter: a,
                secondCenter: b,
                size: size,
                radius: r,
                smoothness: widget.blend.smoothness,
                viscosity: widget.blend.viscosity,
                settings: widget.blend.settings,
                first: handle(0, widget.blend.first),
                second: handle(1, widget.blend.second),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Rotate only the fallback path, never the optical member boxes. Rotating
/// a circular member's square box inflates its screen-space bounds and makes
/// the shader interpret diagonal placement as a larger droplet.
class _PositionedBlendBorder extends OutlinedBorder {
  const _PositionedBlendBorder({
    required this.first,
    required this.second,
    required this.radius,
    required this.smoothness,
    super.side,
  });
  final Offset first;
  final Offset second;
  final double radius;
  final double smoothness;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);
  @override
  _PositionedBlendBorder copyWith({BorderSide? side}) => _PositionedBlendBorder(
    first: first,
    second: second,
    radius: radius,
    smoothness: smoothness,
    side: side ?? this.side,
  );
  @override
  ShapeBorder scale(double t) => _PositionedBlendBorder(
    first: first * t,
    second: second * t,
    radius: radius * t,
    smoothness: smoothness * t,
    side: side.scale(t),
  );
  Path _path(Rect rect, double inset) {
    final delta = second - first;
    final r = math.max(0.0, radius - inset);
    final local = _BlendedLenses(
      distance: delta.distance,
      radius: r,
      smoothness: smoothness,
    ).getOuterPath(Rect.fromLTWH(0, 0, delta.distance + r * 2, r * 2));
    final transform =
        Matrix4.translationValues(rect.left + first.dx, rect.top + first.dy, 0)
          ..rotateZ(math.atan2(delta.dy, delta.dx))
          ..translateByDouble(-r, -r, 0, 1);
    return local.transform(transform.storage);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect, 0);
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect, side.width);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style != BorderStyle.none && side.width > 0) {
      canvas.drawPath(_path(rect, side.width / 2), side.toPaint());
    }
  }
}

class _BlendedLenses extends OutlinedBorder {
  _BlendedLenses({
    required this.distance,
    required this.radius,
    required this.smoothness,
    super.side,
  });
  final double distance;
  final double radius;
  final double smoothness;
  final _paths = <Rect, Path>{};

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  _BlendedLenses copyWith({BorderSide? side}) => _BlendedLenses(
    distance: distance,
    radius: radius,
    smoothness: smoothness,
    side: side ?? this.side,
  );

  @override
  ShapeBorder scale(double t) => _BlendedLenses(
    distance: distance * t,
    radius: radius * t,
    smoothness: smoothness * t,
    side: side.scale(t),
  );

  Path _outline(Rect rect) =>
      _paths.putIfAbsent(rect, () => _buildOutline(rect));

  Path _buildOutline(Rect rect) {
    final r = math.min(radius, rect.height / 2);
    if (r <= 0 || rect.isEmpty) return Path();
    final left = rect.left + r;
    final right = rect.right - r;
    final cy = rect.center.dy;
    final smoothing = smoothness;
    // A smooth union defines one continuous liquid field. Unlike a separate
    // bridge patch, its neck cannot cross itself or leave an isolated island.
    double field(double x, double y) {
      final a = math.sqrt((x - left) * (x - left) + y * y) - r;
      final b = math.sqrt((x - right) * (x - right) + y * y) - r;
      final h = math.max(smoothing - (a - b).abs(), 0) / smoothing;
      return math.min(a, b) - h * h * smoothing * 0.25;
    }

    final path = Path();
    final top = <Offset>[];
    final bottom = <Offset>[];
    void finish() {
      if (top.length > 1) {
        path.moveTo(top.first.dx, top.first.dy);
        for (final point in top.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        for (final point in bottom.reversed) {
          path.lineTo(point.dx, point.dy);
        }
        path.close();
      }
      top.clear();
      bottom.clear();
    }

    // Solve the upper and lower field boundaries; symmetry makes the vertical
    // root monotonic. Separate runs naturally become two drops after rupture.
    const samples = 192;
    for (var i = 0; i <= samples; i++) {
      final x = rect.left + rect.width * i / samples;
      if (field(x, 0) > 0) {
        finish();
        continue;
      }
      var low = 0.0;
      var high = r * 1.3;
      for (var j = 0; j < 16; j++) {
        final mid = (low + high) / 2;
        if (field(x, mid) < 0) {
          low = mid;
        } else {
          high = mid;
        }
      }
      final y = (low + high) / 2;
      top.add(Offset(x, cy - y));
      bottom.add(Offset(x, cy + y));
    }
    finish();
    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _outline(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _outline(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style != BorderStyle.none && side.width > 0) {
      canvas.drawPath(_outline(rect.deflate(side.width / 2)), side.toPaint());
    }
  }
}
