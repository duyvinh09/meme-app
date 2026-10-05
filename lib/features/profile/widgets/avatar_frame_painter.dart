import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/avatar_frames.dart';

class AvatarFramePainter extends CustomPainter {
  final AvatarFrameItem frame;
  final double size;
  final bool showGlow;

  AvatarFramePainter({
    required this.frame,
    required this.size,
    this.showGlow = true,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size / 2;

    switch (frame.id) {
      case 'flame':
        _paintFlameDetails(canvas, center, radius);
        break;
      case 'sparkle':
        _paintSparkleDetails(canvas, center, radius);
        break;
      case 'aurora':
        _paintAuroraDetails(canvas, center, radius);
        break;
      case 'cosmic':
        _paintCosmicDetails(canvas, center, radius);
        break;
      case 'solar':
        _paintSolarDetails(canvas, center, radius);
        break;
      case 'mythic':
        _paintMythicDetails(canvas, center, radius);
        break;
      case 'phoenix':
        _paintPhoenixDetails(canvas, center, radius);
        break;
      case 'dragon':
        _paintDragonDetails(canvas, center, radius);
        break;
      case 'eternal':
        _paintEternalDetails(canvas, center, radius);
        break;
      default:
        break;
    }
  }

  // 10 Days: Flame — Three flame tongues rooted on the circular frame arc
  void _paintFlameDetails(Canvas canvas, Offset center, double radius) {
    final shaderRect = Rect.fromCircle(center: center, radius: radius * 1.55);
    final flamePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFEC00), Color(0xFFFF6A00), Color(0xFFFF1A44)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(shaderRect);

    // Three tongues, each base-rooted on the circle arc at the top
    // [angleOffset from -π/2, heightFactor, halfAngle in radians]
    const tongues = [
      [-0.34, 0.40, 0.19], // left
      [ 0.00, 0.52, 0.23], // center (tallest)
      [ 0.34, 0.38, 0.18], // right
    ];
    for (final t in tongues) {
      canvas.drawPath(
        _buildFlameOnArc(center, radius, -math.pi / 2 + t[0], t[2], t[1]),
        flamePaint,
      );
    }

    // Ember sparks scattered near the top-side arcs
    final sparkColors = [const Color(0xFFFFD700), const Color(0xFFFF6A00), const Color(0xFFFFEC00), const Color(0xFFFF416C)];
    final sparkAngles = [-math.pi * 0.75, -math.pi * 0.62, -math.pi * 0.38, -math.pi * 0.25];
    final sparkSizes = [0.055, 0.042, 0.060, 0.038];
    for (int i = 0; i < sparkAngles.length; i++) {
      final px = center.dx + math.cos(sparkAngles[i]) * (radius + radius * 0.10);
      final py = center.dy + math.sin(sparkAngles[i]) * (radius + radius * 0.10);
      canvas.drawCircle(Offset(px, py), radius * sparkSizes[i], Paint()..color = sparkColors[i]);
    }
  }

  /// Builds a flame tongue rooted on the circular frame border.
  /// Control points go OUTWARD (wider than the base) at mid-height → creates
  /// the organic rounded-belly / teardrop flame shape, NOT a sharp spike.
  Path _buildFlameOnArc(Offset center, double radius, double centerAngle, double halfAngle, double heightFactor) {
    // Base points at 80% of half-angle (narrower opening, same ratio as original)
    final leftBaseAngle  = centerAngle - halfAngle * 0.8;
    final rightBaseAngle = centerAngle + halfAngle * 0.8;
    final tipR = radius + radius * heightFactor;

    final leftBase  = Offset(center.dx + math.cos(leftBaseAngle)  * radius, center.dy + math.sin(leftBaseAngle)  * radius);
    final rightBase = Offset(center.dx + math.cos(rightBaseAngle) * radius, center.dy + math.sin(rightBaseAngle) * radius);
    final tip       = Offset(center.dx + math.cos(centerAngle)    * tipR,   center.dy + math.sin(centerAngle)    * tipR);

    // Control points go OUTWARD (1.15x half-angle) at 45% flame height
    // This replicates the outward belly-bulge of the original _buildFlameTongue.
    final ctrlR          = radius + radius * heightFactor * 0.45;
    final leftCtrlAngle  = centerAngle - halfAngle * 1.15; // wider than base → bulges out
    final rightCtrlAngle = centerAngle + halfAngle * 1.15;
    final leftCtrl  = Offset(center.dx + math.cos(leftCtrlAngle)  * ctrlR, center.dy + math.sin(leftCtrlAngle)  * ctrlR);
    final rightCtrl = Offset(center.dx + math.cos(rightCtrlAngle) * ctrlR, center.dy + math.sin(rightCtrlAngle) * ctrlR);

    return Path()
      ..moveTo(leftBase.dx, leftBase.dy)
      ..quadraticBezierTo(leftCtrl.dx,  leftCtrl.dy,  tip.dx, tip.dy)
      ..quadraticBezierTo(rightCtrl.dx, rightCtrl.dy, rightBase.dx, rightBase.dy)
      ..close();
  }

  // 30 Days: Sparkle — 4 large stars at diagonals + 4 dot accents at cardinal + 2 flare crosses
  void _paintSparkleDetails(Canvas canvas, Offset center, double radius) {
    // 4 bright 4-point stars hugging the frame border at diagonal positions
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2) - math.pi / 4;
      final dist = radius + 3;
      final sx = center.dx + math.cos(angle) * dist;
      final sy = center.dy + math.sin(angle) * dist;
      _draw4PointStar(canvas, Offset(sx, sy), radius * 0.18,
          Paint()..color = const Color(0xFF00F5A0));
    }

    // 4 small glowing dots at cardinal positions
    final dotPaint = Paint()..color = const Color(0xFF38EF7D).withValues(alpha: 0.85);
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final sx = center.dx + math.cos(angle) * (radius + 3);
      final sy = center.dy + math.sin(angle) * (radius + 3);
      canvas.drawCircle(Offset(sx, sy), radius * 0.055, dotPaint);
    }

    // 2 flare cross accents inside the frame near top-right and bottom-left
    _drawFlareCross(canvas, Offset(center.dx + radius * 0.68, center.dy - radius * 0.68), radius * 0.13, const Color(0xFF00F5A0));
    _drawFlareCross(canvas, Offset(center.dx - radius * 0.68, center.dy + radius * 0.68), radius * 0.10, const Color(0xFF38EF7D));
  }

  // 60 Days: Aurora — gem stars at diagonals + aurora curtain arc + colored accent dots
  void _paintAuroraDetails(Canvas canvas, Offset center, double radius) {
    // 4 aurora gem stars hugging the border at diagonal positions
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2) + (math.pi / 4);
      final dist = radius + 3;
      final sx = center.dx + math.cos(angle) * dist;
      final sy = center.dy + math.sin(angle) * dist;
      _draw4PointStar(canvas, Offset(sx, sy), radius * 0.15,
          Paint()..color = const Color(0xFF92EFFD));
    }

    // 4 small colored accent dots at cardinal positions
    final auroraColors = [
      const Color(0xFF4E65FF),
      const Color(0xFF38EF7D),
      const Color(0xFF92EFFD),
      const Color(0xFF8A2387),
    ];
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final sx = center.dx + math.cos(angle) * (radius + 3);
      final sy = center.dy + math.sin(angle) * (radius + 3);
      canvas.drawCircle(Offset(sx, sy), radius * 0.055,
          Paint()..color = auroraColors[i].withValues(alpha: 0.85));
    }

    // Aurora curtain arc sweeping top half — stays within frame
    final curtainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0x004E65FF),
          Color(0xFF4E65FF),
          Color(0xFF92EFFD),
          Color(0xFF38EF7D),
          Color(0x0038EF7D),
        ],
        stops: [0.1, 0.25, 0.5, 0.75, 0.9],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 2));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi * 1.05,
      math.pi * 1.1,
      false,
      curtainPaint,
    );
  }

  // 100 Days: Cosmic — Dual tilted orbit rings (compact) + planets + celestial stars
  void _paintCosmicDetails(Canvas canvas, Offset center, double radius) {
    // Orbit rings sized to stay within the avatar frame area
    _drawOrbitRing(canvas, center, radius, -math.pi / 6, 1.65, 1.30, 1.5, const Color(0xFF00DFD8));
    _drawOrbitRing(canvas, center, radius, math.pi / 3.6, 1.55, 1.20, 1.2, const Color(0xFFFF0080));

    // Planets on ring 1
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 6);
    _drawPlanet(canvas, Offset(radius * 0.82, 0), radius * 0.11, const Color(0xFFFF0080), Colors.white);
    _drawPlanet(canvas, Offset(-radius * 0.82, 0), radius * 0.08, const Color(0xFF00DFD8), Colors.white);
    canvas.restore();

    // 4 celestial cross stars tight on the border
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2) + math.pi / 4;
      final sx = center.dx + math.cos(angle) * (radius + 3);
      final sy = center.dy + math.sin(angle) * (radius + 3);
      _draw4PointStar(canvas, Offset(sx, sy), radius * 0.17,
          Paint()..color = const Color(0xFFFF0080));
    }

    // 4 small nebula dots at cardinal positions on the border
    final dotPaint = Paint()..color = const Color(0xFF00DFD8).withValues(alpha: 0.70);
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final sx = center.dx + math.cos(angle) * (radius + 3);
      final sy = center.dy + math.sin(angle) * (radius + 3);
      canvas.drawCircle(Offset(sx, sy), radius * 0.045, dotPaint);
    }
  }

  void _drawOrbitRing(Canvas canvas, Offset center, double radius, double tilt, double wFactor, double hFactor, double strokeW, Color color) {
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..color = color.withValues(alpha: 0.80);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * wFactor, height: radius * hFactor),
      orbitPaint,
    );
    canvas.restore();
  }

  void _drawPlanet(Canvas canvas, Offset pos, double r, Color body, Color shine) {
    canvas.drawCircle(pos, r, Paint()..color = body);
    canvas.drawCircle(
      Offset(pos.dx - r * 0.3, pos.dy - r * 0.3),
      r * 0.38,
      Paint()..color = shine.withValues(alpha: 0.45),
    );
  }

  // 200 Days: Solar — 16-ray corona + tri-diamond solar jewel
  void _paintSolarDetails(Canvas canvas, Offset center, double radius) {
    const rayCount = 16;
    final shaderRect = Rect.fromCircle(center: center, radius: radius * 1.6);
    final rayPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE600), Color(0xFFFF8C00), Color(0xFFFF0844)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(shaderRect);

    for (int i = 0; i < rayCount; i++) {
      final angle = i * (2 * math.pi / rayCount) - math.pi / 2;
      final isMain = i % 2 == 0;
      final outerDist = radius + (isMain ? radius * 0.30 : radius * 0.16);
      final halfAngle = isMain ? 0.11 : 0.07;

      final p1 = Offset(center.dx + math.cos(angle - halfAngle) * (radius - 1), center.dy + math.sin(angle - halfAngle) * (radius - 1));
      final p2 = Offset(center.dx + math.cos(angle) * outerDist, center.dy + math.sin(angle) * outerDist);
      final p3 = Offset(center.dx + math.cos(angle + halfAngle) * (radius - 1), center.dy + math.sin(angle + halfAngle) * (radius - 1));

      canvas.drawPath(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close(), rayPaint);
    }

    final topY = center.dy - radius - radius * 0.16;
    final jewel1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFE600)],
      ).createShader(Rect.fromCircle(center: Offset(0, 0), radius: radius * 0.22));
    _drawDiamond(canvas, Offset(center.dx, topY), radius * 0.22, jewel1);
    _drawDiamond(canvas, Offset(center.dx - radius * 0.20, topY + radius * 0.14), radius * 0.12, Paint()..color = const Color(0xFFFF8C00));
    _drawDiamond(canvas, Offset(center.dx + radius * 0.20, topY + radius * 0.14), radius * 0.12, Paint()..color = const Color(0xFFFF8C00));
  }

  // 300 Days: Mythic — Hex crystal gems + prismatic outline + shard spikes between
  void _paintMythicDetails(Canvas canvas, Offset center, double radius) {
    const gemCount = 6;
    final gemColors = [
      const Color(0xFFFA709A),
      const Color(0xFFFEE140),
      const Color(0xFF30CFD0),
      const Color(0xFF667EEA),
      const Color(0xFF764BA2),
      const Color(0xFFFC5C7D),
    ];

    final hexOutlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFA709A), Color(0xFFFEE140), Color(0xFF30CFD0),
          Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFFA709A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 6));

    final hexPath = Path();
    for (int i = 0; i < gemCount; i++) {
      final angle = i * (2 * math.pi / gemCount) - (math.pi / 2);
      final hx = center.dx + math.cos(angle) * (radius + 6);
      final hy = center.dy + math.sin(angle) * (radius + 6);
      i == 0 ? hexPath.moveTo(hx, hy) : hexPath.lineTo(hx, hy);
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexOutlinePaint);

    for (int i = 0; i < gemCount; i++) {
      final angle = i * (2 * math.pi / gemCount) - (math.pi / 2);
      final gx = center.dx + math.cos(angle) * (radius + 6);
      final gy = center.dy + math.sin(angle) * (radius + 6);
      _drawDiamond(canvas, Offset(gx, gy), radius * 0.22, Paint()..color = gemColors[i]);
      canvas.drawCircle(
        Offset(gx - radius * 0.04, gy - radius * 0.04),
        radius * 0.065,
        Paint()..color = Colors.white.withValues(alpha: 0.70),
      );
    }

    final shardPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF30CFD0).withValues(alpha: 0.65);
    for (int i = 0; i < gemCount; i++) {
      final angle = i * (2 * math.pi / gemCount) - (math.pi / 2) + (math.pi / gemCount);
      final sx = center.dx + math.cos(angle) * (radius + 3);
      final sy = center.dy + math.sin(angle) * (radius + 3);
      _drawShardSpike(canvas, Offset(sx, sy), radius * 0.11, angle, shardPaint);
    }
  }

  void _drawShardSpike(Canvas canvas, Offset base, double length, double angle, Paint paint) {
    final tip = Offset(base.dx + math.cos(angle) * length, base.dy + math.sin(angle) * length);
    final leftBase = Offset(base.dx + math.cos(angle + math.pi / 2) * length * 0.22, base.dy + math.sin(angle + math.pi / 2) * length * 0.22);
    final rightBase = Offset(base.dx + math.cos(angle - math.pi / 2) * length * 0.22, base.dy + math.sin(angle - math.pi / 2) * length * 0.22);
    canvas.drawPath(Path()..moveTo(leftBase.dx, leftBase.dy)..lineTo(tip.dx, tip.dy)..lineTo(rightBase.dx, rightBase.dy)..close(), paint);
  }

  // 400 Days: Phoenix — Massive fan of flame that fills the entire top arc
  void _paintPhoenixDetails(Canvas canvas, Offset center, double radius) {
    final shaderRect = Rect.fromCircle(center: center, radius: radius * 1.6);

    // Broad warm glow under everything — covers a wide arc at the top
    canvas.drawPath(
      _buildFlameOnArc(center, radius, -math.pi / 2, 0.85, 0.22),
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFF4500).withValues(alpha: 0.28),
    );

    // Main fire gradient: gold → orange → crimson → purple
    final flamePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFEC00), Color(0xFFFF5500), Color(0xFFFF0055), Color(0xFF8800CC)],
        stops: [0.0, 0.38, 0.70, 1.0],
      ).createShader(shaderRect);

    // 5 tongues — each wide and tall, forming a wall of fire across the top arc
    // [angleOffset from -π/2, heightFactor, halfAngle]
    const tongues = [
      [-0.72, 0.42, 0.22], // far left
      [-0.40, 0.60, 0.26], // mid-left
      [ 0.00, 0.80, 0.30], // center — tallest & widest (the Phoenix heart)
      [ 0.40, 0.58, 0.25], // mid-right
      [ 0.72, 0.40, 0.21], // far right
    ];
    for (final t in tongues) {
      canvas.drawPath(
        _buildFlameOnArc(center, radius, -math.pi / 2 + t[0], t[2], t[1]),
        flamePaint,
      );
    }

    // Bright white-golden core at the center tongue (hottest point)
    canvas.drawPath(
      _buildFlameOnArc(center, radius, -math.pi / 2, 0.12, 0.45),
      Paint()
        ..style = PaintingStyle.fill
        ..shader = const RadialGradient(
          center: Alignment(0, -0.6),
          radius: 0.5,
          colors: [Colors.white, Color(0x00FFEC00)],
        ).createShader(shaderRect),
    );

    // Ember sparks flanking the base of the fire on the top arc
    final emberData = [
      [-math.pi * 0.18, radius * 0.055, const Color(0xFFFFD700)],
      [-math.pi * 0.82, radius * 0.055, const Color(0xFFFF6A00)],
      [-math.pi * 0.10, radius * 0.038, const Color(0xFFFFEC00)],
      [-math.pi * 0.90, radius * 0.038, const Color(0xFFFF3300)],
    ];
    for (final e in emberData) {
      final angle = e[0] as double;
      final size  = e[1] as double;
      final color = e[2] as Color;
      canvas.drawCircle(
        Offset(center.dx + math.cos(angle) * (radius + 2), center.dy + math.sin(angle) * (radius + 2)),
        size, Paint()..color = color,
      );
    }
  }

  // 500 Days: Dragon — Serpentine horns + scale ring + 4 jade orbs
  void _paintDragonDetails(Canvas canvas, Offset center, double radius) {
    final goldPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE259), Color(0xFFFFA751), Color(0xFFFFD700)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.6));

    final scalePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.45);
    const scaleCount = 20;
    for (int i = 0; i < scaleCount; i++) {
      final angle = i * (2 * math.pi / scaleCount);
      final sx = center.dx + math.cos(angle) * (radius + 2);
      final sy = center.dy + math.sin(angle) * (radius + 2);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(sx, sy), width: radius * 0.22, height: radius * 0.22),
        angle - math.pi / 2,
        math.pi,
        false,
        scalePaint,
      );
    }

    // Left serpentine horn — shorter, stays close to frame top
    final leftHorn = Path()
      ..moveTo(center.dx - radius * 0.28, center.dy - radius * 0.86)
      ..cubicTo(
        center.dx - radius * 0.62, center.dy - radius * 1.12,
        center.dx - radius * 0.95, center.dy - radius * 1.20,
        center.dx - radius * 1.10, center.dy - radius * 1.04,
      )
      ..cubicTo(
        center.dx - radius * 0.90, center.dy - radius * 0.95,
        center.dx - radius * 0.68, center.dy - radius * 0.95,
        center.dx - radius * 0.55, center.dy - radius * 0.66,
      )
      ..close();
    canvas.drawPath(leftHorn, goldPaint);

    // Right serpentine horn — mirror
    final rightHorn = Path()
      ..moveTo(center.dx + radius * 0.28, center.dy - radius * 0.86)
      ..cubicTo(
        center.dx + radius * 0.62, center.dy - radius * 1.12,
        center.dx + radius * 0.95, center.dy - radius * 1.20,
        center.dx + radius * 1.10, center.dy - radius * 1.04,
      )
      ..cubicTo(
        center.dx + radius * 0.90, center.dy - radius * 0.95,
        center.dx + radius * 0.68, center.dy - radius * 0.95,
        center.dx + radius * 0.55, center.dy - radius * 0.66,
      )
      ..close();
    canvas.drawPath(rightHorn, goldPaint);

    // Horn tip glints
    canvas.drawCircle(Offset(center.dx - radius * 1.10, center.dy - radius * 1.04), radius * 0.065, Paint()..color = Colors.white.withValues(alpha: 0.60));
    canvas.drawCircle(Offset(center.dx + radius * 1.10, center.dy - radius * 1.04), radius * 0.065, Paint()..color = Colors.white.withValues(alpha: 0.60));

    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final dist = radius + 5;
      final jx = center.dx + math.cos(angle) * dist;
      final jy = center.dy + math.sin(angle) * dist;
      canvas.drawCircle(Offset(jx, jy), radius * 0.165, Paint()..color = const Color(0xFFFFD700));
      canvas.drawCircle(Offset(jx, jy), radius * 0.115,
        Paint()..shader = RadialGradient(
          colors: const [Color(0xFF00F260), Color(0xFF0575E6)],
        ).createShader(Rect.fromCircle(center: Offset(jx, jy), radius: radius * 0.115)));
      canvas.drawCircle(Offset(jx - radius * 0.04, jy - radius * 0.04), radius * 0.042, Paint()..color = Colors.white.withValues(alpha: 0.80));
    }
  }

  // 600 Days: Eternal — Full divine 24-ray sunburst + arc-based 5-peak crown + jewels
  void _paintEternalDetails(Canvas canvas, Offset center, double radius) {
    // === DIVINE SUNBURST — 24 colored spike-rays all around the circle ===
    const rayCount = 24;
    for (int i = 0; i < rayCount; i++) {
      final angle  = i * (2 * math.pi / rayCount);
      final isMain = i % 2 == 0;
      final height = isMain ? radius * 0.28 : radius * 0.14;
      const halfA  = 0.09;
      final color  = _haloColor(i, rayCount);

      final p1 = Offset(center.dx + math.cos(angle - halfA) * radius, center.dy + math.sin(angle - halfA) * radius);
      final p2 = Offset(center.dx + math.cos(angle)          * (radius + height), center.dy + math.sin(angle) * (radius + height));
      final p3 = Offset(center.dx + math.cos(angle + halfA) * radius, center.dy + math.sin(angle + halfA) * radius);
      canvas.drawPath(
        Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close(),
        Paint()..color = color.withValues(alpha: isMain ? 0.92 : 0.60),
      );
    }

    // === 5-PEAK CROWN — base follows the circular arc, peaks radiate outward ===
    // Each entry: [angleOffset from −π/2, heightFactor above circle radius]
    const crownPts = [
      [-0.44, 0.00], // outer-left base (on circle)
      [-0.38, 0.34], // outer-left peak
      [-0.27, 0.16], // left inner dip
      [-0.16, 0.48], // left-center peak
      [-0.07, 0.24], // center-left dip
      [ 0.00, 0.64], // CENTER PEAK (tallest)
      [ 0.07, 0.24], // center-right dip
      [ 0.16, 0.48], // right-center peak
      [ 0.27, 0.16], // right inner dip
      [ 0.38, 0.34], // outer-right peak
      [ 0.44, 0.00], // outer-right base (on circle)
    ];

    final crownTopY = center.dy - radius - radius * 0.64; // approx top of center peak
    final crownPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFFFFFFF), Color(0xFFFFE600), Color(0xFFFFA000)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(center.dx - radius * 0.5, crownTopY, radius, radius * 0.68));

    final crownPath = Path();
    for (int i = 0; i < crownPts.length; i++) {
      final a  = -math.pi / 2 + crownPts[i][0];
      final r  = radius + radius * crownPts[i][1];
      final pt = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      i == 0 ? crownPath.moveTo(pt.dx, pt.dy) : crownPath.lineTo(pt.dx, pt.dy);
    }
    // Arc base: sweep counter-clockwise from outer-right back to outer-left along the circle
    crownPath.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + 0.44, // startAngle = outer-right base
      -0.88,               // sweepAngle (negative = CCW → back to outer-left)
      false,
    );
    crownPath.close();
    canvas.drawPath(crownPath, crownPaint);

    // Crown edge stroke
    canvas.drawPath(crownPath, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.80));

    // === JEWELS on all 5 crown peaks ===
    final peakOffsets = [-0.38, -0.16, 0.00,  0.16,  0.38];
    final peakHeights = [ 0.34,  0.48, 0.64,  0.48,  0.34];
    final peakColors  = [
      const Color(0xFFFFE600), const Color(0xFFFF00FF), const Color(0xFF00FFFF),
      const Color(0xFFFF00FF), const Color(0xFFFFE600),
    ];
    final peakSizes   = [radius * 0.08, radius * 0.10, radius * 0.14, radius * 0.10, radius * 0.08];
    for (int i = 0; i < peakOffsets.length; i++) {
      final a    = -math.pi / 2 + peakOffsets[i];
      final r    = radius + radius * peakHeights[i];
      final gPos = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      _drawDiamond(canvas, gPos, peakSizes[i], Paint()..color = peakColors[i]);
      canvas.drawCircle(gPos, peakSizes[i] * 0.35, Paint()..color = Colors.white.withValues(alpha: 0.90));
    }

    // === 3 colored star accents at right / bottom / left (top is reserved for crown) ===
    final sideAngles = [0.0, math.pi / 2, math.pi];
    final sideColors = [const Color(0xFFFFE600), const Color(0xFFFF00FF), const Color(0xFF00FFFF)];
    for (int i = 0; i < 3; i++) {
      final sx = center.dx + math.cos(sideAngles[i]) * (radius + 3);
      final sy = center.dy + math.sin(sideAngles[i]) * (radius + 3);
      _draw4PointStar(canvas, Offset(sx, sy), radius * 0.14, Paint()..color = sideColors[i]);
    }
  }

  Color _haloColor(int index, int total) {
    final t = index / total;
    if (t < 0.25) return const Color(0xFF00FFFF);
    if (t < 0.50) return const Color(0xFFFF00FF);
    if (t < 0.75) return const Color(0xFFFFE600);
    return const Color(0xFF0072FF);
  }

  void _draw4PointStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx + size * 0.22, center.dy - size * 0.22, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx + size * 0.22, center.dy + size * 0.22, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx - size * 0.22, center.dy + size * 0.22, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx - size * 0.22, center.dy - size * 0.22, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.72, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.72, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawFlareCross(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - size, center.dy), Offset(center.dx + size, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - size), Offset(center.dx, center.dy + size), paint);
    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final d = size * 0.65;
    canvas.drawLine(Offset(center.dx - d, center.dy - d), Offset(center.dx + d, center.dy + d), paint2);
    canvas.drawLine(Offset(center.dx + d, center.dy - d), Offset(center.dx - d, center.dy + d), paint2);
  }

  @override
  bool shouldRepaint(covariant AvatarFramePainter oldDelegate) {
    return oldDelegate.frame.id != frame.id ||
        oldDelegate.size != size ||
        oldDelegate.showGlow != showGlow;
  }
}
