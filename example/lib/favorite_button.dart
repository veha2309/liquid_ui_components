import 'package:flutter/material.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

/// Only the small heart overlay animates; the gallery doesn't rebuild.
class FavoriteGlassButton extends StatefulWidget {
  const FavoriteGlassButton({super.key});
  @override
  State<FavoriteGlassButton> createState() => _FavoriteGlassButtonState();
}

class _FavoriteGlassButtonState extends State<FavoriteGlassButton>
    with SingleTickerProviderStateMixin {
  bool _favorite = false;
  OverlayEntry? _burst;
  late final AnimationController _animation =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 850),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _removeBurst();
      });

  void _removeBurst() {
    _burst?.remove();
    _burst?.dispose();
    _burst = null;
  }

  void _toggle() {
    setState(() => _favorite = !_favorite);
    _removeBurst();
    _animation.stop();
    if (!_favorite || MediaQuery.disableAnimationsOf(context)) return;
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final button = context.findRenderObject()! as RenderBox;
    final origin = button.localToGlobal(
      button.size.center(Offset.zero),
      ancestor: overlayBox,
    );
    _burst = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final t = _animation.value;
                final rise = Curves.easeOutCubic.transform(t);
                final opacity = t < 0.12
                    ? t / 0.12
                    : ((1 - t) / 0.4).clamp(0.0, 1.0);
                final scale = t < 0.45
                    ? 0.4 + Curves.easeOutBack.transform(t / 0.45) * 0.75
                    : 1.15 - (t - 0.45) * 0.3;
                return Stack(
                  children: [
                    Positioned(
                      left: origin.dx - 38,
                      top: origin.dy - 42 - rise * 80,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 76,
                            color: Color(0xffed467d),
                            shadows: [
                              Shadow(
                                color: Color(0x555e1636),
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (var particle = 0; particle < 6; particle++)
                      Positioned(
                        left:
                            origin.dx -
                            8 +
                            (particle.isEven ? -1 : 1) *
                                (20 + particle * 6) *
                                rise,
                        top: origin.dy - 12 - rise * (45 + particle * 14),
                        child: Opacity(
                          opacity: opacity * 0.8,
                          child: Icon(
                            particle.isEven
                                ? Icons.favorite_rounded
                                : Icons.auto_awesome,
                            size: 10.0 + particle % 3 * 3,
                            color: particle.isEven
                                ? const Color(0xffff87b0)
                                : const Color(0xffffc66c),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    overlay.insert(_burst!);
    _animation.forward(from: 0);
  }

  @override
  void dispose() {
    _removeBurst();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: _favorite,
    child: LiquidGlassIconButton(
      icon: Icon(
        _favorite ? Icons.favorite_rounded : Icons.favorite_outline,
        color: _favorite ? const Color(0xffdc3e75) : null,
      ),
      tooltip: _favorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: _toggle,
    ),
  );
}
