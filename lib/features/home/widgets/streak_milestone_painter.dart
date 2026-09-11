import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/streak_milestones.dart';

class MilestoneParticle {
  final double angle;
  final double distanceFactor;
  final double speed;
  final double size;
  final double baseOpacity;
  final bool isStar;
  final double rotationSpeed;
  final Color color;

  const MilestoneParticle({
    required this.angle,
    required this.distanceFactor,
    required this.speed,
    required this.size,
    required this.baseOpacity,
    required this.isStar,
    required this.rotationSpeed,
    required this.color,
  });
}

class FlameEmber {
  final double startXOffset;
  final double speed;
  final double size;
  final double wobbleFrequency;
  final double phaseShift;
  final Color color;

  const FlameEmber({
    required this.startXOffset,
    required this.speed,
    required this.size,
    required this.wobbleFrequency,
    required this.phaseShift,
    required this.color,
  });
}

class StreakMilestonePainter extends CustomPainter {
  final double burstProgress; // 0.0 -> 1.0 (burst explosion)
  final double ambientProgress; // 0.0 -> 1.0 (continuous looping idle)
  final MilestoneTier tier;
  final Color primaryColor;
  final Color secondaryColor;
  final Color glowColor;

  static final Map<MilestoneTier, List<MilestoneParticle>> _cachedParticles = {};
  static final Map<MilestoneTier, List<FlameEmber>> _cachedEmbers = {};

  StreakMilestonePainter({
    required this.burstProgress,
    required this.ambientProgress,
    required this.tier,
    required this.primaryColor,
    required this.secondaryColor,
    required this.glowColor,
  });

  static List<MilestoneParticle> _getParticlesForTier(
    MilestoneTier tier,
    Color primary,
    Color secondary,
  ) {
    if (_cachedParticles.containsKey(tier)) {
      return _cachedParticles[tier]!;
    }

    final count = switch (tier) {
      MilestoneTier.tier1 => 14,
      MilestoneTier.tier2 => 24,
      MilestoneTier.tier3 => 38,
      MilestoneTier.tier4 => 54,
    };

    final rnd = math.Random(tier.index * 1337 + 42);
    final list = <MilestoneParticle>[];

    final colors = [
      primary,
      secondary,
      Colors.white,
      primary.withValues(alpha: 0.85),
      secondary.withValues(alpha: 0.85),
    ];

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + (rnd.nextDouble() - 0.5) * 0.4;
      final distanceFactor = 0.55 + rnd.nextDouble() * 0.65;
      final speed = 0.7 + rnd.nextDouble() * 0.6;
      final size = switch (tier) {
        MilestoneTier.tier1 => 3.0 + rnd.nextDouble() * 3.5,
        MilestoneTier.tier2 => 3.5 + rnd.nextDouble() * 4.5,
        MilestoneTier.tier3 => 4.0 + rnd.nextDouble() * 5.5,
        MilestoneTier.tier4 => 4.5 + rnd.nextDouble() * 6.5,
      };
      final isStar = (i % 2 == 0) || (tier == MilestoneTier.tier4 && i % 3 != 0);
      final color = colors[rnd.nextInt(colors.length)];

      list.add(
        MilestoneParticle(
          angle: angle,
          distanceFactor: distanceFactor,
          speed: speed,
          size: size,
          baseOpacity: 0.65 + rnd.nextDouble() * 0.35,
          isStar: isStar,
          rotationSpeed: (rnd.nextDouble() - 0.5) * 4.0,
          color: color,
        ),
      );
    }

    _cachedParticles[tier] = list;
    return list;
  }

  static List<FlameEmber> _getEmbersForTier(
    MilestoneTier tier,
    Color primary,
    Color secondary,
  ) {
    if (_cachedEmbers.containsKey(tier)) {
      return _cachedEmbers[tier]!;
    }

    final count = switch (tier) {
      MilestoneTier.tier1 => 10,
      MilestoneTier.tier2 => 18,
      MilestoneTier.tier3 => 28,
      MilestoneTier.tier4 => 42,
    };

    final rnd = math.Random(tier.index * 777 + 99);
    final list = <FlameEmber>[];

    final emberColors = [
      const Color(0xFFFFD54F),
      const Color(0xFFFF7043),
      const Color(0xFFFFAB40),
      primary,
      secondary,
      Colors.white,
    ];

    for (int i = 0; i < count; i++) {
      final startX = (rnd.nextDouble() - 0.5) * (36.0 + tier.index * 10.0);
      final speed = 0.8 + rnd.nextDouble() * 0.9;
      final size = 2.0 + rnd.nextDouble() * (3.5 + tier.index * 1.0);
      final wobble = 2.0 + rnd.nextDouble() * 3.0;
      final phase = rnd.nextDouble();
      final color = emberColors[rnd.nextInt(emberColors.length)];

      list.add(
        FlameEmber(
          startXOffset: startX,
          speed: speed,
          size: size,
          wobbleFrequency: wobble,
          phaseShift: phase,
          color: color,
        ),
      );
    }

    _cachedEmbers[tier] = list;
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.5;

    final particles = _getParticlesForTier(tier, primaryColor, secondaryColor);
    final embers = _getEmbersForTier(tier, primaryColor, secondaryColor);

    // 1. Draw Multi-layer Blazing Glow Aura
    _drawGlowAura(canvas, center, maxRadius);

    // 2. Draw Dynamic Dancing Fire Tongues / Flame Corona
    _drawFlameCorona(canvas, center);

    // 3. Draw Sunburst Light Rays for Tier 3 & Tier 4
    if (tier == MilestoneTier.tier3 || tier == MilestoneTier.tier4) {
      _drawSunburstRays(canvas, center, maxRadius);
    }

    // 4. Draw Rising Fiery Embers & Sparks
    _drawRisingEmbers(canvas, center, embers);

    // 5. Draw Expanding Shockwave Rings
    _drawShockwaves(canvas, center, maxRadius);

    // 6. Draw Burst Particles & Stars
    _drawParticles(canvas, center, maxRadius, particles);
  }

  void _drawGlowAura(Canvas canvas, Offset center, double maxRadius) {
    if (burstProgress <= 0.01) return;

    final auraRadius = maxRadius *
        switch (tier) {
          MilestoneTier.tier1 => 0.70,
          MilestoneTier.tier2 => 0.90,
          MilestoneTier.tier3 => 1.15,
          MilestoneTier.tier4 => 1.35,
        };

    final pulse = math.sin(ambientProgress * 2 * math.pi) * (0.08 + tier.index * 0.04);
    final effectiveRadius = (auraRadius * burstProgress * (1.0 + pulse)).clamp(1.0, 500.0);

    final auraOpacity = (0.30 * burstProgress * (1.0 + pulse) + tier.index * 0.05).clamp(0.0, 0.60);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: auraOpacity),
          secondaryColor.withValues(alpha: auraOpacity * 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: effectiveRadius),
      );

    canvas.drawCircle(center, effectiveRadius, glowPaint);
  }

  void _drawFlameCorona(Canvas canvas, Offset center) {
    if (burstProgress <= 0.20) return;

    final baseRadius = 42.0;
    final tongueCount = switch (tier) {
      MilestoneTier.tier1 => 8,
      MilestoneTier.tier2 => 14,
      MilestoneTier.tier3 => 20,
      MilestoneTier.tier4 => 28,
    };

    final flamePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final time = ambientProgress * 2 * math.pi;

    for (int i = 0; i < tongueCount; i++) {
      final angle = (i / tongueCount) * 2 * math.pi + (time * 0.2);
      // Flame height oscillation
      final osc = math.sin(time * 3.0 + i * 1.7) * 0.5 + 0.5;
      final tongueLength = (8.0 + tier.index * 5.0) + (osc * (10.0 + tier.index * 6.0));

      final startX = center.dx + math.cos(angle) * (baseRadius - 2);
      final startY = center.dy + math.sin(angle) * (baseRadius - 2);

      final endX = center.dx + math.cos(angle) * (baseRadius + tongueLength);
      final endY = center.dy + math.sin(angle) * (baseRadius + tongueLength);

      final opacity = ((0.35 + osc * 0.45) * burstProgress * (1.0 + tier.index * 0.15)).clamp(0.0, 0.95);
      final color = i % 2 == 0 ? primaryColor : secondaryColor;

      flamePaint
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = (2.5 + tier.index * 0.8) * (1.0 - osc * 0.3);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), flamePaint);
    }
  }

  void _drawRisingEmbers(
    Canvas canvas,
    Offset center,
    List<FlameEmber> embers,
  ) {
    if (burstProgress <= 0.15) return;

    final riseHeight = 90.0 + tier.index * 25.0;

    for (final e in embers) {
      // Cyclic normalized progress [0.0 -> 1.0]
      final t = (ambientProgress * e.speed + e.phaseShift) % 1.0;

      // Start below center and rise up
      final y = center.dy + 35.0 - t * riseHeight;
      final wobble = math.sin(t * math.pi * e.wobbleFrequency) * (10.0 + tier.index * 3.0);
      final x = center.dx + e.startXOffset + wobble;

      // Bell curve opacity: invisible at bottom, bright in middle, fades out at top
      final opacity = (math.sin(t * math.pi) * (0.75 + tier.index * 0.08) * burstProgress).clamp(0.0, 1.0);
      final size = (e.size * (1.0 - t * 0.45) * (0.8 + tier.index * 0.15)).clamp(1.0, 10.0);

      final emberPaint = Paint()
        ..color = e.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Glowing ember
      canvas.drawCircle(Offset(x, y), size / 2, emberPaint);

      // Core white heat spark for larger embers
      if (size > 3.5 && tier.index >= 1) {
        final corePaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), size / 4, corePaint);
      }
    }
  }

  void _drawSunburstRays(Canvas canvas, Offset center, double maxRadius) {
    final rayCount = tier == MilestoneTier.tier4 ? 18 : 12;
    final rayLength = maxRadius * (tier == MilestoneTier.tier4 ? 1.25 : 1.05) * burstProgress;
    final rotation = ambientProgress * math.pi * 0.6;

    final rayPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          secondaryColor.withValues(alpha: 0.22 * burstProgress),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: rayLength));

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi + rotation;
      final halfWidth = (math.pi / rayCount) * 0.35;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + math.cos(angle - halfWidth) * rayLength,
        center.dy + math.sin(angle - halfWidth) * rayLength,
      );
      path.lineTo(
        center.dx + math.cos(angle + halfWidth) * rayLength,
        center.dy + math.sin(angle + halfWidth) * rayLength,
      );
      path.close();

      canvas.drawPath(path, rayPaint);
    }
  }

  void _drawShockwaves(Canvas canvas, Offset center, double maxRadius) {
    if (burstProgress < 0.15 || burstProgress > 0.95) return;

    final ringProgress = ((burstProgress - 0.15) / 0.80).clamp(0.0, 1.0);
    final ringRadius = maxRadius * ringProgress * (tier == MilestoneTier.tier4 ? 1.25 : 1.0);
    final ringOpacity = ((1.0 - ringProgress) * 0.75).clamp(0.0, 0.75);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (tier == MilestoneTier.tier4 ? 3.5 : 2.2) * (1.0 - ringProgress * 0.6)
      ..color = primaryColor.withValues(alpha: ringOpacity);

    canvas.drawCircle(center, ringRadius, ringPaint);

    if (tier == MilestoneTier.tier3 || tier == MilestoneTier.tier4) {
      final secondRingProgress = ((burstProgress - 0.30) / 0.65).clamp(0.0, 1.0);
      if (secondRingProgress > 0.0) {
        final secondRadius = maxRadius * secondRingProgress * 1.15;
        final secondOpacity = ((1.0 - secondRingProgress) * 0.55).clamp(0.0, 0.55);

        final secondPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * (1.0 - secondRingProgress * 0.5)
          ..color = secondaryColor.withValues(alpha: secondOpacity);

        canvas.drawCircle(center, secondRadius, secondPaint);
      }
    }
  }

  void _drawParticles(
    Canvas canvas,
    Offset center,
    double maxRadius,
    List<MilestoneParticle> particles,
  ) {
    if (burstProgress <= 0.05) return;

    for (final p in particles) {
      final distance = maxRadius * p.distanceFactor * _easeOutBack(burstProgress * p.speed.clamp(0.0, 1.0));
      final ambientDrift = math.sin((ambientProgress + p.angle) * 2 * math.pi) * 8.0;

      final x = center.dx + math.cos(p.angle) * (distance + ambientDrift);
      final y = center.dy + math.sin(p.angle) * (distance + ambientDrift);

      final fadeIn = (burstProgress * 3.0).clamp(0.0, 1.0);
      final fadeOut = (1.0 - (burstProgress - 0.75).clamp(0.0, 0.25) * 1.2).clamp(0.3, 1.0);
      final opacity = (p.baseOpacity * fadeIn * fadeOut).clamp(0.0, 1.0);

      final particlePaint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      if (p.isStar) {
        final rotation = ambientProgress * p.rotationSpeed * math.pi;
        _drawStar(canvas, Offset(x, y), p.size, rotation, particlePaint);
      } else {
        canvas.drawCircle(Offset(x, y), p.size / 2, particlePaint);
      }
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint paint,
  ) {
    final path = Path();
    final points = 4;
    final innerRadius = radius * 0.38;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * math.pi / points) + rotation;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _easeOutBack(double x) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final t = (x - 1.0).clamp(-1.0, 0.0);
    return 1 + c3 * math.pow(t, 3) + c1 * math.pow(t, 2);
  }

  @override
  bool shouldRepaint(covariant StreakMilestonePainter oldDelegate) {
    return oldDelegate.burstProgress != burstProgress ||
        oldDelegate.ambientProgress != ambientProgress ||
        oldDelegate.tier != tier ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.glowColor != glowColor;
  }
}
