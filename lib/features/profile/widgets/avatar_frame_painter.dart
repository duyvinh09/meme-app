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
      case 'flame':
        _paintFlameDetails(canvas, center, radius);
        break;
      default:
        break;
    }
  }

  // 10 Days: Flame - Fire tongues and top flame crest
  void _paintFlameDetails(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD200), Color(0xFFFF416C)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.3));

    // Top central flame crest
    final crestHeight = radius * 0.32;
    final crestWidth = radius * 0.28;
    final topY = center.dy - radius;

    final flamePath = Path()
      ..moveTo(center.dx, topY - crestHeight)
      ..quadraticBezierTo(
        center.dx + crestWidth * 0.7,
        topY - crestHeight * 0.4,
        center.dx + crestWidth * 0.5,
        topY,
      )
      ..lineTo(center.dx - crestWidth * 0.5, topY)
      ..quadraticBezierTo(
        center.dx - crestWidth * 0.7,
        topY - crestHeight * 0.4,
        center.dx,
        topY - crestHeight,
      );

    canvas.drawPath(flamePath, paint);

    // Mini flame sparks on sides
    for (int i = 0; i < 2; i++) {
      final angle = i == 0 ? -math.pi * 0.35 : -math.pi * 0.65;
      final px = center.dx + math.cos(angle) * (radius + 2);
      final py = center.dy + math.sin(angle) * (radius + 2);

      final sparkPaint = Paint()
        ..color = const Color(0xFFFFD200)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), radius * 0.06, sparkPaint);
    }
  }

  // 30 Days: Sparkle - 4-point Diamond Stars at 4 quadrants
  void _paintSparkleDetails(Canvas canvas, Offset center, double radius) {
    final starPaint = Paint()
      ..color = const Color(0xFF00F5A0)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final dist = radius + 3;
      final sx = center.dx + math.cos(angle) * dist;
      final sy = center.dy + math.sin(angle) * dist;

      _draw4PointStar(canvas, Offset(sx, sy), radius * 0.16, starPaint);
    }
  }

  // 60 Days: Aurora - Northern light wave rings & starlight accents
  void _paintAuroraDetails(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF92EFFD).withValues(alpha: 0.65);

    canvas.drawCircle(center, radius + 4, ringPaint);

    final gemPaint = Paint()..color = const Color(0xFF00E5FF);
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2) + (math.pi / 4);
      final dist = radius + 4;
      final sx = center.dx + math.cos(angle) * dist;
      final sy = center.dy + math.sin(angle) * dist;
      _draw4PointStar(canvas, Offset(sx, sy), radius * 0.14, gemPaint);
    }
  }

  // 100 Days: Cosmic Nebula - Tilted Orbit Ring with planets & 4 Celestial Cross markers
  void _paintCosmicDetails(Canvas canvas, Offset center, double radius) {
    // Outer dashed orbit ring
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF00DFD8).withValues(alpha: 0.85);

    // Tilted planetary orbit ellipse
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 6); // 30 deg tilt

    final orbitRect = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 2.5,
      height: radius * 2.1,
    );
    canvas.drawOval(orbitRect, orbitPaint);

    // Orbiting Satellite Planets
    final planetPaint1 = Paint()
      ..color = const Color(0xFFFF0080)
      ..style = PaintingStyle.fill;
    final planetPaint2 = Paint()
      ..color = const Color(0xFF00DFD8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(radius * 1.25, 0), radius * 0.12, planetPaint1);
    canvas.drawCircle(Offset(-radius * 1.25, 0), radius * 0.09, planetPaint2);

    canvas.restore();

    // 4 Celestial Cross stars at 0, 90, 180, 270 deg
    final starPaint = Paint()..color = const Color(0xFFFF0080);
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final sx = center.dx + math.cos(angle) * (radius + 2);
      final sy = center.dy + math.sin(angle) * (radius + 2);
      _draw4PointStar(canvas, Offset(sx, sy), radius * 0.18, starPaint);
    }
  }

  // 200 Days: Solar Flare - 12-point Sunburst Corona rays around perimeter
  void _paintSolarDetails(Canvas canvas, Offset center, double radius) {
    final rayCount = 12;
    final rayPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE600), Color(0xFFFF0844)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));

    for (int i = 0; i < rayCount; i++) {
      final angle = i * (2 * math.pi / rayCount);
      final innerDist = radius - 1;
      final outerDist = radius + (i % 2 == 0 ? radius * 0.26 : radius * 0.15);

      final p1 = Offset(
        center.dx + math.cos(angle - 0.12) * innerDist,
        center.dy + math.sin(angle - 0.12) * innerDist,
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * outerDist,
        center.dy + math.sin(angle) * outerDist,
      );
      final p3 = Offset(
        center.dx + math.cos(angle + 0.12) * innerDist,
        center.dy + math.sin(angle + 0.12) * innerDist,
      );

      final rayPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();

      canvas.drawPath(rayPath, rayPaint);
    }

    // Top Sun Core Jewel
    final topY = center.dy - radius - radius * 0.12;
    final jewelPaint = Paint()..color = const Color(0xFFFFE600);
    _drawDiamond(canvas, Offset(center.dx, topY), radius * 0.18, jewelPaint);
  }

  // 300 Days: Mythic Prism - Hexagonal Gem Facets & Crystal Shards
  void _paintMythicDetails(Canvas canvas, Offset center, double radius) {
    final gemCount = 6;
    final gemColors = [
      const Color(0xFFFA709A),
      const Color(0xFFFEE140),
      const Color(0xFF30CFD0),
      const Color(0xFF667EEA),
      const Color(0xFF764BA2),
      const Color(0xFFFA709A),
    ];

    // Hexagonal crystal studs around outer rim
    for (int i = 0; i < gemCount; i++) {
      final angle = i * (2 * math.pi / gemCount) - (math.pi / 2);
      final gx = center.dx + math.cos(angle) * (radius + 4);
      final gy = center.dy + math.sin(angle) * (radius + 4);

      final gemPaint = Paint()..color = gemColors[i];
      _drawDiamond(canvas, Offset(gx, gy), radius * 0.20, gemPaint);

      // White inner sparkle
      final shinePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(gx, gy), radius * 0.05, shinePaint);
    }

    // Outer geometric prism ring
    final hexPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF30CFD0).withValues(alpha: 0.7);

    final hexPath = Path();
    for (int i = 0; i < gemCount; i++) {
      final angle = i * (2 * math.pi / gemCount) - (math.pi / 2);
      final hx = center.dx + math.cos(angle) * (radius + 4);
      final hy = center.dy + math.sin(angle) * (radius + 4);
      if (i == 0) {
        hexPath.moveTo(hx, hy);
      } else {
        hexPath.lineTo(hx, hy);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexPaint);
  }

  // 400 Days: Phoenix Blaze - Dual Phoenix Wings + Top Flame Crest + Tail Feather
  void _paintPhoenixDetails(Canvas canvas, Offset center, double radius) {
    final wingPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFF3300),
          Color(0xFFFF0055),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));

    // Left Phoenix Wing
    final leftWing = Path()
      ..moveTo(center.dx - radius + 2, center.dy - radius * 0.4)
      ..quadraticBezierTo(
        center.dx - radius * 1.45,
        center.dy - radius * 0.8,
        center.dx - radius * 1.25,
        center.dy - radius * 0.1,
      )
      ..quadraticBezierTo(
        center.dx - radius * 1.35,
        center.dy + radius * 0.3,
        center.dx - radius + 4,
        center.dy + radius * 0.4,
      )
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    // Right Phoenix Wing
    final rightWing = Path()
      ..moveTo(center.dx + radius - 2, center.dy - radius * 0.4)
      ..quadraticBezierTo(
        center.dx + radius * 1.45,
        center.dy - radius * 0.8,
        center.dx + radius * 1.25,
        center.dy - radius * 0.1,
      )
      ..quadraticBezierTo(
        center.dx + radius * 1.35,
        center.dy + radius * 0.3,
        center.dx + radius - 4,
        center.dy + radius * 0.4,
      )
      ..close();
    canvas.drawPath(rightWing, wingPaint);

    // Top Majestic Phoenix Head & Fire Crest
    final topCrest = Path()
      ..moveTo(center.dx, center.dy - radius * 1.40)
      ..quadraticBezierTo(
        center.dx + radius * 0.35,
        center.dy - radius * 1.05,
        center.dx + radius * 0.25,
        center.dy - radius * 0.85,
      )
      ..lineTo(center.dx - radius * 0.25, center.dy - radius * 0.85)
      ..quadraticBezierTo(
        center.dx - radius * 0.35,
        center.dy - radius * 1.05,
        center.dx,
        center.dy - radius * 1.40,
      );
    canvas.drawPath(topCrest, wingPaint);

    // Bottom Tail Feather Gem
    final gemPaint = Paint()..color = const Color(0xFFFFD700);
    _drawDiamond(
      canvas,
      Offset(center.dx, center.dy + radius + radius * 0.14),
      radius * 0.20,
      gemPaint,
    );
  }

  // 500 Days: Dragon Sovereign - Imperial Dragon Horns & 4 Dragon Claw Jade Jewels
  void _paintDragonDetails(Canvas canvas, Offset center, double radius) {
    final goldPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFE259),
          Color(0xFFFFA751),
          Color(0xFFFFD700),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));

    // Left Dragon Horn
    final leftHorn = Path()
      ..moveTo(center.dx - radius * 0.35, center.dy - radius * 0.90)
      ..quadraticBezierTo(
        center.dx - radius * 0.95,
        center.dy - radius * 1.35,
        center.dx - radius * 1.25,
        center.dy - radius * 1.25,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.85,
        center.dy - radius * 1.05,
        center.dx - radius * 0.65,
        center.dy - radius * 0.70,
      )
      ..close();
    canvas.drawPath(leftHorn, goldPaint);

    // Right Dragon Horn
    final rightHorn = Path()
      ..moveTo(center.dx + radius * 0.35, center.dy - radius * 0.90)
      ..quadraticBezierTo(
        center.dx + radius * 0.95,
        center.dy - radius * 1.35,
        center.dx + radius * 1.25,
        center.dy - radius * 1.25,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.85,
        center.dy - radius * 1.05,
        center.dx + radius * 0.65,
        center.dy - radius * 0.70,
      )
      ..close();
    canvas.drawPath(rightHorn, goldPaint);

    // 4 Imperial Jade Orbs held by Dragon Claws (Top, Bottom, Left, Right)
    final jadePaint = Paint()..color = const Color(0xFF00F260);
    final clawPaint = Paint()..color = const Color(0xFFFFD700);

    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final dist = radius + 4;
      final jx = center.dx + math.cos(angle) * dist;
      final jy = center.dy + math.sin(angle) * dist;

      // Golden claw bracket
      canvas.drawCircle(Offset(jx, jy), radius * 0.16, clawPaint);
      // Imperial Jade Pearl
      canvas.drawCircle(Offset(jx, jy), radius * 0.11, jadePaint);
      // Glimmer
      canvas.drawCircle(
        Offset(jx - radius * 0.03, jy - radius * 0.03),
        radius * 0.04,
        Paint()..color = Colors.white,
      );
    }
  }

  // 600 Days: Eternal Transcendence - 5-Point Supreme Crown + Divine Radiant Halo Rays
  void _paintEternalDetails(Canvas canvas, Offset center, double radius) {
    // 16-point Celestial Platinum Divine Halo Rays
    final haloRayCount = 16;
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF00FFFF),
          Color(0xFFFF00FF),
          Color(0xFFFFE600),
          Color(0xFF0072FF),
          Color(0xFF00FFFF),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));

    for (int i = 0; i < haloRayCount; i++) {
      final angle = i * (2 * math.pi / haloRayCount);
      final inner = radius + 2;
      final outer = radius + (i % 2 == 0 ? radius * 0.28 : radius * 0.16);

      final p1 = Offset(
        center.dx + math.cos(angle) * inner,
        center.dy + math.sin(angle) * inner,
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * outer,
        center.dy + math.sin(angle) * outer,
      );

      canvas.drawLine(p1, p2, rayPaint);
    }

    // Supreme 5-Point Royal Crown on Top
    final crownWidth = radius * 1.1;
    final crownHeight = radius * 0.46;
    final crownTop = center.dy - radius - crownHeight + 4;

    final crownPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFE600),
          Color(0xFFFFD700),
          Color(0xFFFFA000),
        ],
      ).createShader(Rect.fromLTWH(center.dx - crownWidth / 2, crownTop, crownWidth, crownHeight));

    final crownPath = Path()
      ..moveTo(center.dx - crownWidth * 0.45, center.dy - radius + 2)
      ..lineTo(center.dx - crownWidth * 0.50, crownTop + crownHeight * 0.35) // left peak
      ..lineTo(center.dx - crownWidth * 0.25, crownTop + crownHeight * 0.65) // left dip
      ..lineTo(center.dx - crownWidth * 0.22, crownTop + crownHeight * 0.20) // mid-left peak
      ..lineTo(center.dx, crownTop + crownHeight * 0.50) // center dip
      ..lineTo(center.dx, crownTop) // CENTER HIGHEST PEAK
      ..lineTo(center.dx, crownTop + crownHeight * 0.50)
      ..lineTo(center.dx + crownWidth * 0.22, crownTop + crownHeight * 0.20) // mid-right peak
      ..lineTo(center.dx + crownWidth * 0.25, crownTop + crownHeight * 0.65) // right dip
      ..lineTo(center.dx + crownWidth * 0.50, crownTop + crownHeight * 0.35) // right peak
      ..lineTo(center.dx + crownWidth * 0.45, center.dy - radius + 2)
      ..close();

    canvas.drawPath(crownPath, crownPaint);

    // Crown Jewel Diamonds on 5 peaks
    final diamondPaint = Paint()..color = const Color(0xFF00FFFF);
    _drawDiamond(canvas, Offset(center.dx, crownTop), radius * 0.12, diamondPaint);
    _drawDiamond(canvas, Offset(center.dx - crownWidth * 0.22, crownTop + crownHeight * 0.20), radius * 0.09, diamondPaint);
    _drawDiamond(canvas, Offset(center.dx + crownWidth * 0.22, crownTop + crownHeight * 0.20), radius * 0.09, diamondPaint);
    _drawDiamond(canvas, Offset(center.dx - crownWidth * 0.50, crownTop + crownHeight * 0.35), radius * 0.08, diamondPaint);
    _drawDiamond(canvas, Offset(center.dx + crownWidth * 0.50, crownTop + crownHeight * 0.35), radius * 0.08, diamondPaint);
  }

  void _draw4PointStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.75, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.75, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AvatarFramePainter oldDelegate) {
    return oldDelegate.frame.id != frame.id ||
        oldDelegate.size != size ||
        oldDelegate.showGlow != showGlow;
  }
}
