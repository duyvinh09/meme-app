import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/chat_bubble_theme.dart';

class ChatBubbleDecorPainter extends CustomPainter {
  final ChatBubbleTheme theme;
  final bool isMe;

  ChatBubbleDecorPainter({
    required this.theme,
    required this.isMe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme.decorStyle) {
      case ChatDecorStyle.doge:
        _paintDoge(canvas, size);
        break;
      case ChatDecorStyle.spain:
        _paintSpain(canvas, size);
        break;
      case ChatDecorStyle.argentina:
        _paintArgentina(canvas, size);
        break;
      case ChatDecorStyle.faceHug:
        _paintFaceHug(canvas, size);
        break;
      case ChatDecorStyle.pepeHeart:
        _paintPepeHeart(canvas, size);
        break;
      case ChatDecorStyle.sharkPig:
        _paintSharkPig(canvas, size);
        break;
      case ChatDecorStyle.bearTongue:
        _paintBearTongue(canvas, size);
        break;
      case ChatDecorStyle.frogChick:
        _paintFrogChick(canvas, size);
        break;
      case ChatDecorStyle.dogHungry:
        _paintDogHungry(canvas, size);
        break;
      case ChatDecorStyle.dino:
        _paintDino(canvas, size);
        break;
      case ChatDecorStyle.dachshund:
        _paintDachshund(canvas, size);
        break;
      case ChatDecorStyle.frogHungry:
        _paintFrogHungry(canvas, size);
        break;
      case ChatDecorStyle.shout:
        _paintShout(canvas, size);
        break;
      case ChatDecorStyle.olivia:
        _paintOlivia(canvas, size);
        break;
      case ChatDecorStyle.frogDuck:
        _paintFrogDuck(canvas, size);
        break;
      case ChatDecorStyle.catMuscle:
        _paintCatMuscle(canvas, size);
        break;
      case ChatDecorStyle.capybara:
        _paintCapybara(canvas, size);
        break;
      case ChatDecorStyle.frogBox:
        _paintFrogBox(canvas, size);
        break;
      case ChatDecorStyle.catDog:
        _paintCatDog(canvas, size);
        break;
      case ChatDecorStyle.none:
        break;
    }
  }

  // ─── 1. Doge — Snug Scroll Rolls + Compact Shiba Inu Head ─────────────────
  void _paintDoge(Canvas canvas, Size size) {
    final woodPaint = Paint()..color = const Color(0xFFD4A373);
    final woodDark = Paint()..color = const Color(0xFFA67040);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFF8C531B);

    // Left & Right scroll roll rods hugging the sides
    for (final isLeft in [true, false]) {
      final x = isLeft ? -3.0 : size.width;
      final rollRect = Rect.fromLTWH(x, 1, 3.0, size.height - 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rollRect, const Radius.circular(1.5)), woodPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rollRect, const Radius.circular(1.5)), outline);

      // Compact scroll knobs
      canvas.drawCircle(Offset(x + 1.5, 0.5), 1.8, woodDark);
      canvas.drawCircle(Offset(x + 1.5, 0.5), 1.8, outline);
      canvas.drawCircle(Offset(x + 1.5, size.height - 0.5), 1.8, woodDark);
      canvas.drawCircle(Offset(x + 1.5, size.height - 0.5), 1.8, outline);
    }

    // Shiba Inu head on top-right (compact, top sits at Y = -3.5)
    final hx = size.width - 16.0;
    final shibaGold = Paint()..color = const Color(0xFFF39C12);
    final shibaWhite = Paint()..color = const Color(0xFFFFF7ED);
    final darkOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFF78350F);

    // Ears (tucked, max Y = -6.5)
    final leftEar = Path()..moveTo(hx - 1, -2)..lineTo(hx - 2, -6.5)..lineTo(hx + 3, -3.5)..close();
    final rightEar = Path()..moveTo(hx + 10, -3.5)..lineTo(hx + 15, -6.5)..lineTo(hx + 14, -2)..close();
    canvas.drawPath(leftEar, shibaGold);
    canvas.drawPath(leftEar, darkOutline);
    canvas.drawPath(rightEar, shibaGold);
    canvas.drawPath(rightEar, darkOutline);

    // Head oval
    final headRect = Rect.fromLTWH(hx - 2, -4, 17, 12);
    canvas.drawOval(headRect, shibaGold);
    canvas.drawOval(headRect, darkOutline);

    // White muzzle patch
    final muzzle = Path()
      ..moveTo(hx + 1, 2)
      ..quadraticBezierTo(hx + 6.5, -2, hx + 12, 2)
      ..quadraticBezierTo(hx + 13, 6.5, hx + 6.5, 7)
      ..quadraticBezierTo(hx, 6.5, hx + 1, 2)
      ..close();
    canvas.drawPath(muzzle, shibaWhite);

    // Eyebrow white spots
    canvas.drawCircle(Offset(hx + 2.5, -2), 0.9, shibaWhite);
    canvas.drawCircle(Offset(hx + 10.5, -2), 0.9, shibaWhite);

    // Eyes
    canvas.drawCircle(Offset(hx + 3, 0.5), 1.2, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(Offset(hx + 10, 0.5), 1.2, Paint()..color = const Color(0xFF1E293B));

    // Nose & smiling mouth
    canvas.drawOval(Rect.fromLTWH(hx + 5.2, 2, 2.6, 1.8), Paint()..color = Colors.black);
    canvas.drawPath(
      Path()..moveTo(hx + 4.5, 4.2)..quadraticBezierTo(hx + 6.5, 5.5, hx + 8.5, 4.2),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..strokeCap = StrokeCap.round..color = const Color(0xFF78350F),
    );
  }

  // ─── 2. Tây Ban Nha — Spain Ribbon + Compact Corner Trophy ────────────────
  void _paintSpain(Canvas canvas, Size size) {
    final red = Paint()..color = const Color(0xFFEF4444);
    final yellow = Paint()..color = const Color(0xFFFACC15);

    // Slim 2.5px banner strictly on bottom rim
    final bannerH = 2.5;
    final by = size.height - bannerH;
    final rWidth = size.width - 6;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(3, by, rWidth, bannerH), const Radius.circular(1.2)), red);
    canvas.drawRect(Rect.fromLTWH(3 + rWidth * 0.25, by, rWidth * 0.5, bannerH), yellow);

    // Trophy on bottom-left corner (compact height = 10px, stays within corner margin)
    final gold = Paint()..color = const Color(0xFFFFD700);
    final goldDark = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = const Color(0xFFB45309);
    final ty = size.height - 11.5;

    final cup = Path()
      ..moveTo(2, ty + 1)
      ..lineTo(10, ty + 1)
      ..lineTo(8.5, ty + 6)
      ..quadraticBezierTo(6, ty + 8.5, 3.5, ty + 6)
      ..close();
    canvas.drawPath(cup, gold);
    canvas.drawPath(cup, goldDark);

    // Quai cúp
    canvas.drawArc(Rect.fromLTWH(-0.5, ty + 1.5, 3.5, 4), math.pi * 0.5, math.pi, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = const Color(0xFFFFD700));
    canvas.drawArc(Rect.fromLTWH(9, ty + 1.5, 3.5, 4), -math.pi * 0.5, math.pi, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = const Color(0xFFFFD700));

    // Chân cúp
    canvas.drawRect(Rect.fromLTWH(5, ty + 6.5, 2, 2), gold);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(3, ty + 8.5, 6, 2), const Radius.circular(0.8)), gold);

    // Ngôi sao vô địch trên cúp
    _drawStar(canvas, Offset(6, ty + 3.5), 1.6, Paint()..color = const Color(0xFFB45309));
  }

  // ─── 3. Argentina — Albiceleste Ribbon + Compact World Cup Trophy ─────────
  void _paintArgentina(Canvas canvas, Size size) {
    final skyBlue = Paint()..color = const Color(0xFF60A5FA);
    final white = Paint()..color = Colors.white;

    // Slim 2.5px banner on bottom rim
    final bannerH = 2.5;
    final by = size.height - bannerH;
    final rWidth = size.width - 6;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(3, by, rWidth, bannerH), const Radius.circular(1.2)), skyBlue);
    canvas.drawRect(Rect.fromLTWH(3 + rWidth * 0.3, by, rWidth * 0.4, bannerH), white);

    // World Cup Trophy silhouette on bottom-left corner (height = 10.5px)
    final gold = Paint()..color = const Color(0xFFFFD700);
    final goldDark = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = const Color(0xFFB45309);
    final ty = size.height - 11.5;

    // Quả cầu cúp
    canvas.drawCircle(Offset(6.0, ty + 2.5), 2.2, gold);
    canvas.drawCircle(Offset(6.0, ty + 2.5), 2.2, goldDark);

    // Thân cúp uốn lượn
    final stem = Path()
      ..moveTo(3.8, ty + 3.5)
      ..quadraticBezierTo(4.8, ty + 5.5, 4.2, ty + 7.5)
      ..lineTo(7.8, ty + 7.5)
      ..quadraticBezierTo(7.2, ty + 5.5, 8.2, ty + 3.5)
      ..close();
    canvas.drawPath(stem, gold);
    canvas.drawPath(stem, goldDark);

    // Đế cúp
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(3, ty + 7.5, 6, 2.5), const Radius.circular(0.8)), gold);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(3, ty + 7.5, 6, 2.5), const Radius.circular(0.8)), goldDark);

    // 3 ngôi sao nhỏ trên thân cúp
    _drawStar(canvas, Offset(3.5, ty + 0.5), 1.2, Paint()..color = const Color(0xFFF59E0B));
    _drawStar(canvas, Offset(6.0, ty - 0.8), 1.4, Paint()..color = const Color(0xFFF59E0B));
    _drawStar(canvas, Offset(8.5, ty + 0.5), 1.2, Paint()..color = const Color(0xFFF59E0B));
  }

  // ─── 4. Ôm mặt — Chibi Face Hugging Top Border ────────────────────────────
  void _paintFaceHug(Canvas canvas, Size size) {
    final skin = Paint()..color = const Color(0xFFFFE0D2);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFF475569);
    final hair = Paint()..color = const Color(0xFF1E293B);

    final cx = size.width / 2;
    // Chibi face peeking low over top rim (top of head at Y = -3.5)
    final headRect = Rect.fromLTWH(cx - 8, -3.5, 16, 10);
    canvas.drawOval(headRect, skin);
    canvas.drawOval(headRect, outline);

    // Hair bangs
    final hairPath = Path()
      ..moveTo(cx - 8, -1)
      ..quadraticBezierTo(cx - 4, -4.5, cx, -1.5)
      ..quadraticBezierTo(cx + 4, -4.5, cx + 8, -1)
      ..lineTo(cx + 8, -3.5)
      ..quadraticBezierTo(cx, -6.5, cx - 8, -3.5)
      ..close();
    canvas.drawPath(hairPath, hair);

    // Cute smiling eyes (^_^)
    final eyePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1E293B);
    canvas.drawPath(Path()..moveTo(cx - 5.5, 0.5)..quadraticBezierTo(cx - 3.5, -1.5, cx - 1.5, 0.5), eyePaint);
    canvas.drawPath(Path()..moveTo(cx + 1.5, 0.5)..quadraticBezierTo(cx + 3.5, -1.5, cx + 5.5, 0.5), eyePaint);

    // Blush
    canvas.drawOval(Rect.fromLTWH(cx - 7, 2, 3.5, 1.8), Paint()..color = const Color(0xFFFDA4AF));
    canvas.drawOval(Rect.fromLTWH(cx + 3.5, 2, 3.5, 1.8), Paint()..color = const Color(0xFFFDA4AF));

    // Two tiny paws holding top border
    canvas.drawOval(Rect.fromLTWH(cx - 9.5, 3, 3.5, 3), skin);
    canvas.drawOval(Rect.fromLTWH(cx - 9.5, 3, 3.5, 3), outline);
    canvas.drawOval(Rect.fromLTWH(cx + 6, 3, 3.5, 3), skin);
    canvas.drawOval(Rect.fromLTWH(cx + 6, 3, 3.5, 3), outline);
  }

  // ─── 5. Pepe thả tim — Pepe Head & Compact Heart Cascade ───────────────────
  void _paintPepeHeart(Canvas canvas, Size size) {
    final frogGreen = Paint()..color = const Color(0xFF65A30D);
    final frogDark = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF3F6212);
    final eyeWhite = Paint()..color = Colors.white;

    // Pepe Head on top-left (tucked to Y = -3.5)
    final head = Rect.fromLTWH(2, -3.5, 15, 10);
    canvas.drawOval(head, frogGreen);
    canvas.drawOval(head, frogDark);

    // Bulging eyes (top of eye at Y = -5.5)
    canvas.drawCircle(Offset(6, -3.5), 2.8, frogGreen);
    canvas.drawCircle(Offset(6, -3.5), 2.8, frogDark);
    canvas.drawCircle(Offset(12.5, -3.5), 2.8, frogGreen);
    canvas.drawCircle(Offset(12.5, -3.5), 2.8, frogDark);

    canvas.drawCircle(Offset(6, -3.5), 1.9, eyeWhite);
    canvas.drawCircle(Offset(12.5, -3.5), 1.9, eyeWhite);
    canvas.drawCircle(Offset(6.8, -3.5), 0.9, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(13.3, -3.5), 0.9, Paint()..color = Colors.black);

    // Smug mouth
    canvas.drawPath(
      Path()..moveTo(5, 2)..quadraticBezierTo(9, 4.5, 13.5, 2),
      Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeCap = StrokeCap.round..color = const Color(0xFF365314),
    );

    // Compact hearts on top-right corner
    _drawHeart(canvas, Offset(size.width - 7, -2), 4.0, const Color(0xFFEC4899));
    _drawHeart(canvas, Offset(size.width - 14, -4.5), 2.6, const Color(0xFFF43F5E));
  }

  // ─── 6. Cá mập heo — Pig & Shark at Bottom Corners ────────────────────────
  void _paintSharkPig(Canvas canvas, Size size) {
    final pigPink = Paint()..color = const Color(0xFFF472B6);
    final pigLight = Paint()..color = const Color(0xFFFCE7F3);
    final pigDark = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFFBE185D);

    final py = size.height - 10.0;
    // Pig head bottom-left
    canvas.drawOval(Rect.fromLTWH(1, py, 13, 10), pigPink);
    canvas.drawOval(Rect.fromLTWH(1, py, 13, 10), pigDark);

    // Ears
    canvas.drawPath(Path()..moveTo(2, py)..lineTo(0, py - 3)..lineTo(5, py)..close(), pigPink);
    canvas.drawPath(Path()..moveTo(2, py)..lineTo(0, py - 3)..lineTo(5, py)..close(), pigDark);
    canvas.drawPath(Path()..moveTo(9, py)..lineTo(12, py - 3)..lineTo(12, py)..close(), pigPink);
    canvas.drawPath(Path()..moveTo(9, py)..lineTo(12, py - 3)..lineTo(12, py)..close(), pigDark);

    // Snout + eyes
    canvas.drawOval(Rect.fromLTWH(4, py + 3.5, 7, 4.5), pigLight);
    canvas.drawOval(Rect.fromLTWH(4, py + 3.5, 7, 4.5), pigDark);
    canvas.drawCircle(Offset(6.2, py + 5.5), 0.7, pigDark);
    canvas.drawCircle(Offset(8.8, py + 5.5), 0.7, pigDark);
    canvas.drawCircle(Offset(4.5, py + 2.5), 1.0, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(10.5, py + 2.5), 1.0, Paint()..color = Colors.black);

    // Baby Shark bottom-right
    final sharkBlue = Paint()..color = const Color(0xFF38BDF8);
    final sharkDark = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF0284C7);
    final rx = size.width;

    canvas.drawOval(Rect.fromLTWH(rx - 14, py + 1, 14, 9), sharkBlue);
    canvas.drawOval(Rect.fromLTWH(rx - 14, py + 1, 14, 9), sharkDark);

    // Fin
    final fin = Path()..moveTo(rx - 9, py + 1)..lineTo(rx - 7, py - 3.5)..lineTo(rx - 4.5, py + 1)..close();
    canvas.drawPath(fin, sharkBlue);
    canvas.drawPath(fin, sharkDark);

    // Teeth
    final teethPaint = Paint()..color = Colors.white;
    for (double tx = rx - 12; tx <= rx - 6; tx += 2.0) {
      canvas.drawPath(Path()..moveTo(tx, py + 5.5)..lineTo(tx + 1, py + 7.5)..lineTo(tx + 2, py + 5.5)..close(), teethPaint);
    }
    canvas.drawCircle(Offset(rx - 4, py + 4), 1.0, Paint()..color = Colors.black);
  }

  // ─── 7. Gấu thè lưỡi — Bear Head + Tongue Along Left Border ────────────────
  void _paintBearTongue(Canvas canvas, Size size) {
    final bearBrown = Paint()..color = const Color(0xFF854D0E);
    final bearCream = Paint()..color = const Color(0xFFFEF3C7);
    final bearOutline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF713F12);
    final tongueRed = Paint()..color = const Color(0xFFF43F5E);

    // Bear Head top-left (tucked to Y = -3.5)
    canvas.drawOval(Rect.fromLTWH(2, -3.5, 14, 11), bearBrown);
    canvas.drawOval(Rect.fromLTWH(2, -3.5, 14, 11), bearOutline);

    // Ears
    canvas.drawCircle(Offset(4, -3), 2.5, bearBrown);
    canvas.drawCircle(Offset(4, -3), 2.5, bearOutline);
    canvas.drawCircle(Offset(4, -3), 1.2, bearCream);
    canvas.drawCircle(Offset(14, -3), 2.5, bearBrown);
    canvas.drawCircle(Offset(14, -3), 2.5, bearOutline);
    canvas.drawCircle(Offset(14, -3), 1.2, bearCream);

    // Muzzle & eyes
    canvas.drawOval(Rect.fromLTWH(5.5, 1, 7, 4.5), bearCream);
    canvas.drawOval(Rect.fromLTWH(5.5, 1, 7, 4.5), bearOutline);
    canvas.drawOval(Rect.fromLTWH(7.8, 1.5, 2.4, 1.5), Paint()..color = Colors.black);
    canvas.drawCircle(Offset(5.5, -0.5), 1.1, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(12.5, -0.5), 1.1, Paint()..color = Colors.black);

    // Tongue hugging closely along the left outer border
    final tx = 6.5;
    final tw = 4.0;
    final tonguePath = Path()
      ..moveTo(tx, 4)
      ..quadraticBezierTo(tx - 1.5, size.height * 0.5, tx + tw / 2, size.height - 3)
      ..quadraticBezierTo(tx + tw + 1.5, size.height * 0.5, tx + tw, 4)
      ..close();
    canvas.drawPath(tonguePath, tongueRed);
    canvas.drawPath(tonguePath, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.7..color = const Color(0xFFBE123C));
  }

  // ─── 8. Ếch gà con — Bathtub Rim & Corner Peeking ─────────────────────────
  void _paintFrogChick(Canvas canvas, Size size) {
    final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF0284C7);
    final frogGreen = Paint()..color = const Color(0xFF22C55E);
    final chickYellow = Paint()..color = const Color(0xFFFACC15);

    // Frog peeking from bottom-left corner
    final fy = size.height - 6.0;
    canvas.drawCircle(Offset(8, fy), 5.0, frogGreen);
    canvas.drawCircle(Offset(8, fy), 5.0, outline);
    canvas.drawCircle(Offset(5.5, fy - 4), 2.0, frogGreen);
    canvas.drawCircle(Offset(10.5, fy - 4), 2.0, frogGreen);
    canvas.drawCircle(Offset(5.5, fy - 4), 0.9, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(10.5, fy - 4), 0.9, Paint()..color = Colors.black);

    // Chick peeking from bottom-right corner
    final cx = size.width - 8.0;
    canvas.drawCircle(Offset(cx, fy), 5.0, chickYellow);
    canvas.drawCircle(Offset(cx, fy), 5.0, outline);
    canvas.drawPath(Path()..moveTo(cx - 4, fy)..lineTo(cx - 7, fy + 1)..lineTo(cx - 4, fy + 2)..close(), Paint()..color = const Color(0xFFEA580C));
    canvas.drawCircle(Offset(cx - 1.5, fy - 1.5), 1.0, Paint()..color = Colors.black);

    // Soap bubbles strictly along the bottom edge
    final bubPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final bubOutline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5..color = const Color(0xFF93C5FD);
    for (final b in [
      (size.width * 0.40, size.height - 1.5, 2.5),
      (size.width * 0.50, size.height - 2.5, 3.0),
      (size.width * 0.60, size.height - 1.8, 2.4),
    ]) {
      canvas.drawCircle(Offset(b.$1, b.$2), b.$3, bubPaint);
      canvas.drawCircle(Offset(b.$1, b.$2), b.$3, bubOutline);
    }
  }

  // ─── 9. Cún thèm ăn — Hungry Dog on Left & Hot Dog on Right Edge ───────────
  void _paintDogHungry(Canvas canvas, Size size) {
    final dogYellow = Paint()..color = const Color(0xFFFDE047);
    final dogEar = Paint()..color = const Color(0xFFEAB308);
    final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF991B1B);
    final mid = size.height / 2;

    // Dog on left edge (compact, doesn't intrude into text)
    canvas.drawOval(Rect.fromLTWH(-4, mid - 7, 10, 14), dogYellow);
    canvas.drawOval(Rect.fromLTWH(-4, mid - 7, 10, 14), outline);
    canvas.drawOval(Rect.fromLTWH(-5, mid - 5, 4, 9), dogEar);
    canvas.drawCircle(Offset(2, mid - 1.5), 1.4, Paint()..color = Colors.black);
    canvas.drawOval(Rect.fromLTWH(2, mid + 5, 2.2, 3.5), Paint()..color = const Color(0xFF7DD3FC));

    // Hot dog on right edge
    final rx = size.width;
    final bun = Paint()..color = const Color(0xFFD97706);
    final sausage = Paint()..color = const Color(0xFFDC2626);

    canvas.drawOval(Rect.fromLTWH(rx - 12, mid - 5, 12, 5), bun);
    canvas.drawOval(Rect.fromLTWH(rx - 13.5, mid - 2.5, 14, 5), sausage);
    canvas.drawOval(Rect.fromLTWH(rx - 12, mid + 1, 12, 5), bun);

    // Mustard only on hotdog
    final mustard = Path()
      ..moveTo(rx - 12, mid)
      ..quadraticBezierTo(rx - 9, mid - 2, rx - 6, mid)
      ..quadraticBezierTo(rx - 3, mid + 2, rx, mid);
    canvas.drawPath(mustard, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..strokeCap = StrokeCap.round..color = const Color(0xFFFEF08A));
  }

  // ─── 10. Khủng long — Compact Dino Jaws & Snug Spikes ─────────────────────
  void _paintDino(Canvas canvas, Size size) {
    final dinoTeal = Paint()..color = const Color(0xFF0D9488);
    final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF115E59);

    // Upper jaw on left edge
    final upperJaw = Path()
      ..moveTo(0, 0)
      ..lineTo(-5, size.height * 0.15)
      ..lineTo(-3.5, size.height * 0.38)
      ..lineTo(0, size.height * 0.44)
      ..close();
    canvas.drawPath(upperJaw, dinoTeal);
    canvas.drawPath(upperJaw, outline);

    // Lower jaw on left edge
    final lowerJaw = Path()
      ..moveTo(0, size.height * 0.56)
      ..lineTo(-3.5, size.height * 0.62)
      ..lineTo(-5, size.height * 0.85)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lowerJaw, dinoTeal);
    canvas.drawPath(lowerJaw, outline);

    // Teeth
    final teethPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 2; i++) {
      final ty = size.height * 0.20 + i * size.height * 0.10;
      canvas.drawPath(Path()..moveTo(0, ty)..lineTo(-2.2, ty + 2.5)..lineTo(0, ty + 5)..close(), teethPaint);
    }

    // Dino eye on left edge
    canvas.drawCircle(Offset(4, size.height * 0.22), 2.6, dinoTeal);
    canvas.drawCircle(Offset(4, size.height * 0.22), 2.6, outline);
    canvas.drawCircle(Offset(4, size.height * 0.22), 1.5, Paint()..color = Colors.black);

    // Compact dorsal spikes on top (max height 2.8px above top)
    for (int i = 0; i < 3; i++) {
      final sx = size.width * 0.45 + i * (size.width * 0.14);
      final spike = Path()..moveTo(sx, 0)..lineTo(sx + 2.5, -2.8)..lineTo(sx + 5, 0)..close();
      canvas.drawPath(spike, dinoTeal);
      canvas.drawPath(spike, outline);
    }
  }

  // ─── 11. Chó lạp xưởng — Dachshund Head, Paws & Tail at Edges ──────────────
  void _paintDachshund(Canvas canvas, Size size) {
    final dogBrown = Paint()..color = const Color(0xFF78350F);
    final dogDark = Paint()..color = const Color(0xFF451A03);
    final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF451A03);
    final mid = size.height / 2;

    // Head on left edge
    final head = Rect.fromLTWH(-5, mid - 6, 11, 13);
    canvas.drawOval(head, dogBrown);
    canvas.drawOval(head, outline);

    // Ear
    final ear = Rect.fromLTWH(-6.5, mid - 4, 4.5, 10);
    canvas.drawOval(ear, dogDark);
    canvas.drawOval(ear, outline);

    canvas.drawCircle(Offset(1.5, mid - 1.5), 1.3, Paint()..color = Colors.black);
    canvas.drawOval(Rect.fromLTWH(-2, mid + 2.5, 3, 2.2), Paint()..color = Colors.black);

    // 4 stubby paws along bottom border
    for (final lx in [8.0, 18.0, size.width - 20.0, size.width - 10.0]) {
      final pawRect = Rect.fromLTWH(lx - 2.5, size.height - 2, 5, 3.5);
      canvas.drawRRect(RRect.fromRectAndRadius(pawRect, const Radius.circular(1.5)), dogBrown);
      canvas.drawRRect(RRect.fromRectAndRadius(pawRect, const Radius.circular(1.5)), outline);
    }

    // Wagging tail curving right
    final tail = Path()
      ..moveTo(size.width, mid)
      ..quadraticBezierTo(size.width + 4, mid - 4, size.width + 2, mid - 8);
    canvas.drawPath(tail, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round..color = const Color(0xFF78350F));
  }

  // ─── 12. Ếch đói bụng — Cute Frog Nestled Inside Corner Curving Upward ────
  void _paintFrogHungry(Canvas canvas, Size size) {
    final frogGreen = Paint()..color = const Color(0xFF4ADE80);
    final frogLight = Paint()..color = const Color(0xFFBBF7D0);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF15803D);
    final eyeWhite = Paint()..color = Colors.white;

    // Con ếch nằm gọn bên trong góc bo dưới-trái (trong khung chat, cong ôm theo viền bo tròn)
    final frogCenter = Offset(11.0, size.height - 9.0);

    // Chân sau co lại ôm sát góc cong đáy
    canvas.drawOval(
      Rect.fromCenter(center: Offset(5.5, size.height - 5.5), width: 7.0, height: 5.0),
      frogGreen,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(5.5, size.height - 5.5), width: 7.0, height: 5.0),
      outline,
    );

    // Thân ếch bầu bĩnh nghiêng cong lên hướng về góc trên-phải
    canvas.save();
    canvas.translate(frogCenter.dx, frogCenter.dy);
    canvas.rotate(-math.pi / 7); // Nghiêng cong lên 25 độ hướng lên góc trên phải

    // Bụng và thân
    final bodyRect = Rect.fromCenter(center: Offset.zero, width: 13.0, height: 10.5);
    canvas.drawOval(bodyRect, frogGreen);
    canvas.drawOval(bodyRect, outline);
    // Bụng sáng màu
    canvas.drawOval(Rect.fromLTWH(-3.0, -1.0, 7.5, 5.0), frogLight);

    // 2 mắt ếch tròn ngước nhìn lên
    canvas.drawCircle(const Offset(-3.2, -5.2), 2.6, frogGreen);
    canvas.drawCircle(const Offset(-3.2, -5.2), 2.6, outline);
    canvas.drawCircle(const Offset(3.0, -5.2), 2.6, frogGreen);
    canvas.drawCircle(const Offset(3.0, -5.2), 2.6, outline);

    canvas.drawCircle(const Offset(-3.2, -5.2), 1.7, eyeWhite);
    canvas.drawCircle(const Offset(3.0, -5.2), 1.7, eyeWhite);
    canvas.drawCircle(const Offset(-2.8, -5.5), 0.9, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(3.4, -5.5), 0.9, Paint()..color = Colors.black);

    // Bàn chân trước nhỏ đặt lên mép
    canvas.drawCircle(const Offset(5.0, 3.5), 1.6, frogGreen);

    canvas.restore();

    // Chú ruồi nhỏ xinh ở góc trên-phải bên trong khung chat
    final flyPos = Offset(size.width - 10.0, 8.0);
    canvas.drawOval(Rect.fromCenter(center: flyPos, width: 3.8, height: 2.8), Paint()..color = const Color(0xFF1E293B));
    // Cánh ruồi trong suốt
    final wingPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawOval(Rect.fromCenter(center: Offset(flyPos.dx - 1.8, flyPos.dy - 2.2), width: 3.0, height: 2.0), wingPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(flyPos.dx + 1.8, flyPos.dy - 2.2), width: 3.0, height: 2.0), wingPaint);
    // Vệt bay lượn nhẹ
    final buzzPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0xFF64748B).withValues(alpha: 0.5);
    canvas.drawArc(Rect.fromCircle(center: Offset(flyPos.dx + 4, flyPos.dy), radius: 3), -math.pi * 0.5, math.pi, false, buzzPaint);

    // Lưỡi ếch: Xuất phát từ miệng ếch, uốn cong mềm mại men sát góc đáy rồi lượn cong lên tới chú ruồi
    final startX = frogCenter.dx + 4.5;
    final startY = frogCenter.dy - 2.0;

    final tongue = Path()
      ..moveTo(startX, startY)
      ..cubicTo(
        size.width * 0.35, size.height - 3.5, // Men dọc theo sát đáy bên trong khung chat
        size.width - 6.0, size.height - 8.0,  // Ôm theo góc bo dưới phải bên trong
        flyPos.dx - 2.0, flyPos.dy + 2.5,     // Vòng cong lên thẳng tới chú ruồi
      );

    canvas.drawPath(
      tongue,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFEF4444),
    );

    // Đầu lưỡi đỏ quấn quanh chú ruồi
    canvas.drawCircle(Offset(flyPos.dx - 1.5, flyPos.dy + 2.0), 1.2, Paint()..color = const Color(0xFFDC2626));
  }

  // ─── 13. La hét — Shouting Mouth & Subtle Perimeter Sonic Waves ───────────
  void _paintShout(Canvas canvas, Size size) {
    final skin = Paint()..color = const Color(0xFFFFD1BA);
    final mouthDark = Paint()..color = const Color(0xFF881337);
    final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF9F1239);
    final mid = size.height / 2;

    // Screaming face on left edge
    canvas.drawOval(Rect.fromLTWH(-5, mid - 7, 11, 14), skin);
    canvas.drawOval(Rect.fromLTWH(-5, mid - 7, 11, 14), outline);
    canvas.drawOval(Rect.fromLTWH(-3.5, mid - 1, 8, 5.5), mouthDark);
    canvas.drawCircle(Offset(0, mid - 4), 1.1, Paint()..color = Colors.black);

    // Subtle sonic shockwave arcs hugging left corner (low alpha, non-intrusive)
    for (int i = 0; i < 2; i++) {
      final r = 7.0 + i * 5.0;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(4, mid + 2), radius: r),
        -math.pi * 0.35,
        math.pi * 0.70,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFF43F5E).withValues(alpha: 0.35 - i * 0.12),
      );
    }

    // Impact stars in top-right corner
    _drawStar(canvas, Offset(size.width - 6, 4), 2.5, Paint()..color = const Color(0xFFF43F5E));
  }

  // ─── 14. Olivia Rodrigo — Subtle Butterfly & Daisy in Corners ─────────────
  void _paintOlivia(Canvas canvas, Size size) {
    final pink = Paint()..color = const Color(0xFFDB2777);
    final darkPink = Paint()..color = const Color(0xFF9D174D);

    // Daisy in top-left corner
    _drawFlower(canvas, Offset(5.5, 5.5), 4.2, pink);
    // Butterfly in bottom-right corner
    _drawButterfly(canvas, Offset(size.width - 6.5, size.height - 6.5), 5.0, pink, darkPink);

    // Subtle sparkle dot at corner
    _drawStar(canvas, Offset(size.width * 0.35, 2.5), 1.6, Paint()..color = const Color(0xFFEC4899).withValues(alpha: 0.6));
  }

  // ─── 15. Ếch vịt — Duck on Left Edge & Mini Frog on Right Corner ──────────
  void _paintFrogDuck(Canvas canvas, Size size) {
    final duckYellow = Paint()..color = const Color(0xFFFDE047);
    final duckOrange = Paint()..color = const Color(0xFFF97316);
    final duckDark = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFFCA8A04);
    final frogGreen = Paint()..color = const Color(0xFF22C55E);

    final dy = size.height * 0.42;

    // Duck body on left edge
    canvas.drawOval(Rect.fromLTWH(-3, dy, 16, size.height * 0.48), duckYellow);
    canvas.drawOval(Rect.fromLTWH(-3, dy, 16, size.height * 0.48), duckDark);

    // Duck Head
    canvas.drawCircle(Offset(10, dy), 5.0, duckYellow);
    canvas.drawCircle(Offset(10, dy), 5.0, duckDark);

    // Beak
    final beak = Path()..moveTo(14, dy - 1.5)..lineTo(18.5, dy)..lineTo(14, dy + 1.5)..close();
    canvas.drawPath(beak, duckOrange);

    canvas.drawCircle(Offset(11.5, dy - 1.5), 1.0, Paint()..color = Colors.black);

    // Little Frog on top-right edge (top at Y = -2.5)
    final fx = size.width - 12.0;
    final fy = 2.0;
    canvas.drawOval(Rect.fromLTWH(fx, fy, 10, 8), frogGreen);
    canvas.drawOval(Rect.fromLTWH(fx, fy, 10, 8), Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8..color = const Color(0xFF15803D));
    canvas.drawCircle(Offset(fx + 2.5, fy - 1), 1.6, frogGreen);
    canvas.drawCircle(Offset(fx + 7.5, fy - 1), 1.6, frogGreen);
    canvas.drawCircle(Offset(fx + 2.5, fy - 1), 0.8, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(fx + 7.5, fy - 1), 0.8, Paint()..color = Colors.black);
  }

  // ─── 16. Mèo khoe cơ — Compact Buff Cat Shoulders ────────────────────────
  void _paintCatMuscle(Canvas canvas, Size size) {
    final catWhite = Paint()..color = Colors.white;
    final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF1E293B);
    final catPink = Paint()..color = const Color(0xFFFDA4AF);
    final mid = size.height * 0.42;

    // LEFT Bicep Arm (compact, top at Y = -3.5)
    final leftArm = Path()
      ..moveTo(1, mid)
      ..lineTo(-2.5, mid - 5)
      ..quadraticBezierTo(-6, mid - 10, -2.5, mid - 13)
      ..quadraticBezierTo(1, mid - 10, 2, mid - 5)
      ..lineTo(3, mid)
      ..close();
    canvas.drawPath(leftArm, catWhite);
    canvas.drawPath(leftArm, outline);
    canvas.drawCircle(Offset(2, mid), 2.2, catWhite);
    canvas.drawCircle(Offset(2, mid), 2.2, outline);

    // RIGHT Bicep Arm
    final rightArm = Path()
      ..moveTo(size.width - 1, mid)
      ..lineTo(size.width + 2.5, mid - 5)
      ..quadraticBezierTo(size.width + 6, mid - 10, size.width + 2.5, mid - 13)
      ..quadraticBezierTo(size.width - 1, mid - 10, size.width - 2, mid - 5)
      ..lineTo(size.width - 3, mid)
      ..close();
    canvas.drawPath(rightArm, catWhite);
    canvas.drawPath(rightArm, outline);
    canvas.drawCircle(Offset(size.width - 2, mid), 2.2, catWhite);
    canvas.drawCircle(Offset(size.width - 2, mid), 2.2, outline);

    // Cat head top-center (tucked to Y = -3.5)
    final hx = size.width / 2;
    canvas.drawOval(Rect.fromLTWH(hx - 7, -3.5, 14, 10), catWhite);
    canvas.drawOval(Rect.fromLTWH(hx - 7, -3.5, 14, 10), outline);

    // Ears (tucked to Y = -5.5)
    canvas.drawPath(Path()..moveTo(hx - 7, -1)..lineTo(hx - 5.5, -5.5)..lineTo(hx - 2.5, -2)..close(), catWhite);
    canvas.drawPath(Path()..moveTo(hx - 7, -1)..lineTo(hx - 5.5, -5.5)..lineTo(hx - 2.5, -2)..close(), outline);
    canvas.drawPath(Path()..moveTo(hx + 7, -1)..lineTo(hx + 5.5, -5.5)..lineTo(hx + 2.5, -2)..close(), catWhite);
    canvas.drawPath(Path()..moveTo(hx + 7, -1)..lineTo(hx + 5.5, -5.5)..lineTo(hx + 2.5, -2)..close(), outline);
    canvas.drawPath(Path()..moveTo(hx - 6, -1)..lineTo(hx - 5.5, -4)..lineTo(hx - 3, -1.8)..close(), catPink);
    canvas.drawPath(Path()..moveTo(hx + 6, -1)..lineTo(hx + 5.5, -4)..lineTo(hx + 3, -1.8)..close(), catPink);

    // Smug eyes
    final eyePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..strokeCap = StrokeCap.round..color = Colors.black;
    canvas.drawPath(Path()..moveTo(hx - 4.5, 1)..quadraticBezierTo(hx - 2.5, -0.5, hx - 1, 1), eyePaint);
    canvas.drawPath(Path()..moveTo(hx + 1, 1)..quadraticBezierTo(hx + 2.5, -0.5, hx + 4.5, 1), eyePaint);
    canvas.drawCircle(Offset(hx, 3), 0.8, catPink);
  }

  // ─── 17. Capybara — Stoic Capybara on Left Edge with Snug Orange ──────────
  void _paintCapybara(Canvas canvas, Size size) {
    final capyBrown = Paint()..color = const Color(0xFFB45309);
    final capyDark = Paint()..color = const Color(0xFF78350F);
    final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF78350F);
    final mid = size.height / 2;

    // Capybara head on left edge (compact, doesn't cross into text)
    final head = Rect.fromLTWH(-4, mid - 7, 12, 14);
    canvas.drawRRect(RRect.fromRectAndRadius(head, const Radius.circular(3.5)), capyBrown);
    canvas.drawRRect(RRect.fromRectAndRadius(head, const Radius.circular(3.5)), outline);

    // Ear
    canvas.drawCircle(Offset(3, mid - 6), 2.2, capyBrown);
    canvas.drawCircle(Offset(3, mid - 6), 2.2, outline);

    // Snout
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-3, mid + 2, 8, 4.5), const Radius.circular(2)), capyDark);
    canvas.drawCircle(Offset(0, mid + 3.5), 0.6, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(3, mid + 3.5), 0.6, Paint()..color = Colors.black);

    // Chill flat eye
    canvas.drawLine(Offset(2, mid - 2.5), Offset(5, mid - 2.5), Paint()..color = Colors.black..strokeWidth = 1.0..strokeCap = StrokeCap.round);

    // Compact Orange on head (sits at top-left edge, height = -3.5)
    final orange = Paint()..color = const Color(0xFFF97316);
    canvas.drawCircle(Offset(3, mid - 10.5), 3.2, orange);
    canvas.drawCircle(Offset(3, mid - 10.5), 3.2, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6..color = const Color(0xFFEA580C));
    // Tiny Leaf
    canvas.drawPath(
      Path()..moveTo(3, mid - 13.5)..quadraticBezierTo(1, mid - 15, 1, mid - 12.5)..close(),
      Paint()..color = const Color(0xFF15803D),
    );
  }

  // ─── 18. Ếch (box) — Frog Eyes Snug on Top Rim ────────────────────────────
  void _paintFrogBox(Canvas canvas, Size size) {
    final frogGreen = Paint()..color = const Color(0xFF15803D);
    final outline = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = const Color(0xFF14532D);
    final eyeWhite = Paint()..color = Colors.white;

    // Frog Eyes snug on top rim (centers at Y = 0.5, radius = 4.8)
    for (final ex in [12.0, size.width - 12.0]) {
      canvas.drawCircle(Offset(ex, 0.5), 4.8, frogGreen);
      canvas.drawCircle(Offset(ex, 0.5), 4.8, outline);
      canvas.drawCircle(Offset(ex, 0.5), 3.2, eyeWhite);
      canvas.drawCircle(Offset(ex, 0.5), 1.6, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(ex + 0.8, -0.3), 0.6, eyeWhite);
    }

    // Smile line along bottom edge
    final mouth = Path()
      ..moveTo(8, size.height - 2)
      ..quadraticBezierTo(size.width / 2, size.height + 1.5, size.width - 8, size.height - 2);
    canvas.drawPath(mouth, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round..color = const Color(0xFF14532D));

    // Rosy cheeks at bottom corners
    canvas.drawOval(Rect.fromLTWH(5, size.height - 6, 5, 3), Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.7));
    canvas.drawOval(Rect.fromLTWH(size.width - 10, size.height - 6, 5, 3), Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.7));
  }

  // ─── 19. Mèo chó — Kitten & Puppy in Top Corners ──────────────────────────
  void _paintCatDog(Canvas canvas, Size size) {
    final catOrange = Paint()..color = const Color(0xFFF97316);
    final dogBlue = Paint()..color = const Color(0xFF60A5FA);
    final catOutline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF78350F);
    final dogOutline = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.9..color = const Color(0xFF1D4ED8);
    final pink = Paint()..color = const Color(0xFFFDA4AF);

    // KITTEN on top-left (tucked to Y = -3.5)
    final catHead = Rect.fromLTWH(2, -3.5, 12, 9);
    canvas.drawOval(catHead, catOrange);
    canvas.drawOval(catHead, catOutline);
    // Ears
    canvas.drawPath(Path()..moveTo(2, -1.5)..lineTo(3.5, -6)..lineTo(6.5, -2.5)..close(), catOrange);
    canvas.drawPath(Path()..moveTo(2, -1.5)..lineTo(3.5, -6)..lineTo(6.5, -2.5)..close(), catOutline);
    canvas.drawPath(Path()..moveTo(9.5, -2.5)..lineTo(12.5, -6)..lineTo(14, -1.5)..close(), catOrange);
    canvas.drawPath(Path()..moveTo(9.5, -2.5)..lineTo(12.5, -6)..lineTo(14, -1.5)..close(), catOutline);
    canvas.drawPath(Path()..moveTo(3, -1.5)..lineTo(4.5, -4.5)..lineTo(6, -2.5)..close(), pink);
    canvas.drawPath(Path()..moveTo(10.5, -2.5)..lineTo(12, -4.5)..lineTo(13, -1.5)..close(), pink);
    canvas.drawCircle(Offset(4.5, 1), 1.0, Paint()..color = const Color(0xFF15803D));
    canvas.drawCircle(Offset(11.5, 1), 1.0, Paint()..color = const Color(0xFF15803D));

    // PUPPY on top-right (tucked to Y = -3.5)
    final dogHead = Rect.fromLTWH(size.width - 14, -3.5, 12, 9);
    canvas.drawOval(dogHead, dogBlue);
    canvas.drawOval(dogHead, dogOutline);
    canvas.drawOval(Rect.fromLTWH(size.width - 15.5, -1, 3.5, 7), Paint()..color = const Color(0xFF3B82F6));
    canvas.drawOval(Rect.fromLTWH(size.width - 2, -1, 3.5, 7), Paint()..color = const Color(0xFF3B82F6));
    canvas.drawCircle(Offset(size.width - 11, 1), 1.0, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(size.width - 5, 1), 1.0, Paint()..color = Colors.black);
    canvas.drawOval(Rect.fromLTWH(size.width - 9, 3, 3.0, 2.5), Paint()..color = const Color(0xFFF43F5E));

    // Little heart on top-center
    _drawHeart(canvas, Offset(size.width / 2, -1.5), 3.0, const Color(0xFFEC4899));

    // Tiny paws at bottom corners
    _drawPaw(canvas, Offset(6, size.height - 1.5), 2.2, catOrange);
    _drawPaw(canvas, Offset(size.width - 6, size.height - 1.5), 2.2, dogBlue);
  }

  // ─── Shared Vector Drawing Helpers ─────────────────────────────────────────

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(center.dx, center.dy + size * 0.6)
      ..cubicTo(center.dx - size, center.dy - size * 0.3, center.dx - size * 0.5, center.dy - size, center.dx, center.dy - size * 0.4)
      ..cubicTo(center.dx + size * 0.5, center.dy - size, center.dx + size, center.dy - size * 0.3, center.dx, center.dy + size * 0.6);
    canvas.drawPath(path, paint);
  }

  void _drawFlower(Canvas canvas, Offset center, double radius, Paint paint) {
    for (int i = 0; i < 5; i++) {
      final angle = i * (2 * math.pi / 5) - math.pi / 2;
      canvas.drawCircle(
        Offset(center.dx + math.cos(angle) * radius * 0.65, center.dy + math.sin(angle) * radius * 0.65),
        radius * 0.46,
        paint,
      );
    }
    canvas.drawCircle(center, radius * 0.38, Paint()..color = const Color(0xFFFDE047));
    canvas.drawCircle(center, radius * 0.16, Paint()..color = const Color(0xFFF59E0B));
  }

  void _drawButterfly(Canvas canvas, Offset center, double size, Paint upperPaint, Paint lowerPaint) {
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - size * 0.55, center.dy - size * 0.2), width: size * 0.8, height: size * 1.05), upperPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + size * 0.55, center.dy - size * 0.2), width: size * 0.8, height: size * 1.05), upperPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - size * 0.40, center.dy + size * 0.35), width: size * 0.58, height: size * 0.62), lowerPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + size * 0.40, center.dy + size * 0.35), width: size * 0.58, height: size * 0.62), lowerPaint);
    canvas.drawRect(Rect.fromCenter(center: center, width: 1.0, height: size * 0.75), Paint()..color = Colors.black);
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      final r = i.isEven ? size : size * 0.42;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPaw(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawCircle(center, size * 0.75, paint);
    for (int i = 0; i < 3; i++) {
      final angle = -math.pi * 0.72 + i * math.pi * 0.36;
      canvas.drawCircle(
        Offset(center.dx + math.cos(angle) * size * 1.35, center.dy + math.sin(angle) * size * 1.35),
        size * 0.42,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChatBubbleDecorPainter oldDelegate) {
    return oldDelegate.theme.id != theme.id || oldDelegate.isMe != isMe;
  }
}
