import 'dart:math' as math;
import 'package:flutter/material.dart';

class ReactionFlyingOverlay extends StatefulWidget {
  final Widget child;

  const ReactionFlyingOverlay({
    super.key,
    required this.child,
  });

  static ReactionFlyingOverlayState of(BuildContext context) {
    final state = context.findAncestorStateOfType<ReactionFlyingOverlayState>();
    assert(state != null, 'No ReactionFlyingOverlay found in context');
    return state!;
  }

  @override
  State<ReactionFlyingOverlay> createState() => ReactionFlyingOverlayState();
}

class ReactionFlyingOverlayState extends State<ReactionFlyingOverlay>
    with TickerProviderStateMixin {
  final List<_ActiveParticle> _particles = [];
  final math.Random _random = math.Random();

  void triggerReaction(
    String emoji, {
    Offset? originOffset,
    bool isFalling = false,
    int particleCount = 10,
  }) {
    final count = particleCount + _random.nextInt(3);
    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1400 + _random.nextInt(700)),
      );

      final startXOffset = (_random.nextDouble() - 0.5) * 80;
      final endXOffset = (_random.nextDouble() - 0.5) * (isFalling ? 280 : 220);
      final targetScale = 0.85 + _random.nextDouble() * 0.75;
      final targetRotation = (_random.nextDouble() - 0.5) * 1.4;
      final travelDistance = isFalling
          ? 320.0 + _random.nextDouble() * 200.0
          : 280.0 + _random.nextDouble() * 180.0;
      final swayFrequency = 1.0 + _random.nextDouble() * 2.0;
      final swayAmplitude = 14.0 + _random.nextDouble() * 26.0;

      final particle = _ActiveParticle(
        emoji: emoji,
        controller: controller,
        origin: originOffset ?? (isFalling ? const Offset(200, 80) : const Offset(200, 500)),
        startXOffset: startXOffset,
        endXOffset: endXOffset,
        scale: targetScale,
        rotation: targetRotation,
        travelDistance: travelDistance,
        swayFrequency: swayFrequency,
        swayAmplitude: swayAmplitude,
        isFalling: isFalling,
      );

      setState(() {
        _particles.add(particle);
      });

      controller.forward().then((_) {
        if (mounted) {
          setState(() {
            _particles.remove(particle);
          });
          controller.dispose();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final p in _particles) {
      p.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              clipBehavior: Clip.none,
              children: _particles
                  .map((p) => _AnimatedParticleWidget(key: ObjectKey(p), particle: p))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveParticle {
  final String emoji;
  final AnimationController controller;
  final Offset origin;
  final double startXOffset;
  final double endXOffset;
  final double scale;
  final double rotation;
  final double travelDistance;
  final double swayFrequency;
  final double swayAmplitude;
  final bool isFalling;

  _ActiveParticle({
    required this.emoji,
    required this.controller,
    required this.origin,
    required this.startXOffset,
    required this.endXOffset,
    required this.scale,
    required this.rotation,
    required this.travelDistance,
    required this.swayFrequency,
    required this.swayAmplitude,
    this.isFalling = false,
  });
}

class _AnimatedParticleWidget extends StatelessWidget {
  final _ActiveParticle particle;

  const _AnimatedParticleWidget({super.key, required this.particle});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: particle.controller,
      builder: (context, _) {
        final progress = particle.controller.value;
        final curvedProgress = particle.isFalling
            ? Curves.easeInCubic.transform(progress)
            : Curves.easeOutCubic.transform(progress);

        final dy = particle.isFalling
            ? curvedProgress * particle.travelDistance
            : -curvedProgress * particle.travelDistance;

        final sway = math.sin(progress * math.pi * particle.swayFrequency) *
            particle.swayAmplitude;
        final dx = particle.startXOffset +
            (particle.endXOffset - particle.startXOffset) * progress +
            sway;

        // Smooth fade out towards the end
        final opacity = progress < 0.65 ? 1.0 : ((1.0 - progress) / 0.35).clamp(0.0, 1.0);

        // Pop in quickly with elastic spring, then stay full size
        final scaleProgress = progress < 0.18
            ? (progress / 0.18)
            : 1.0;
        final currentScale = particle.scale * scaleProgress;

        return Positioned(
          left: particle.origin.dx + dx - 18,
          top: particle.origin.dy + dy - 18,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: particle.rotation * progress,
              child: Transform.scale(
                scale: currentScale,
                child: Text(
                  particle.emoji,
                  style: const TextStyle(
                    fontSize: 36,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
