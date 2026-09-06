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

  // 1. Doge - Rolled Parchment Scroll + Compact Doge Shiba Head
  void _paintDoge(Canvas canvas, Size size) {
    final scrollWood = Paint()..color = const Color(0xFFD4A373);
    final scrollOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF8C531B);

    // Left Scroll Roll (slim & snug)
    final leftRoll = Rect.fromLTWH(-3.5, 0, 3.5, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(leftRoll, const Radius.circular(2)), scrollWood);
    canvas.drawRRect(RRect.fromRectAndRadius(leftRoll, const Radius.circular(2)), scrollOutline);

    // Right Scroll Roll
    final rightRoll = Rect.fromLTWH(size.width, 0, 3.5, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rightRoll, const Radius.circular(2)), scrollWood);
    canvas.drawRRect(RRect.fromRectAndRadius(rightRoll, const Radius.circular(2)), scrollOutline);

    // Doge Head on Top-Right Corner (compact, max 5px above)
    final dogeHead = Rect.fromLTWH(size.width - 18, -5, 15, 11);
    final dogePaint = Paint()..color = const Color(0xFFF39C12);
    canvas.drawOval(dogeHead, dogePaint);
    canvas.drawOval(dogeHead, scrollOutline);

    // Ears
    final leftEar = Path()
      ..moveTo(size.width - 18, -2)
      ..lineTo(size.width - 19, -8)
      ..lineTo(size.width - 14, -4)
      ..close();
    canvas.drawPath(leftEar, dogePaint);
    canvas.drawPath(leftEar, scrollOutline);

    final rightEar = Path()
      ..moveTo(size.width - 8, -4)
      ..lineTo(size.width - 4, -8)
      ..lineTo(size.width - 3, -2)
      ..close();
    canvas.drawPath(rightEar, dogePaint);
    canvas.drawPath(rightEar, scrollOutline);

    // Eyes & Nose
    final blackPaint = Paint()..color = const Color(0xFF2C3E50);
    canvas.drawCircle(Offset(size.width - 14, -1), 1.0, blackPaint);
    canvas.drawCircle(Offset(size.width - 8, -1), 1.0, blackPaint);
    canvas.drawCircle(Offset(size.width - 11, 2), 1.2, blackPaint);
  }

  // 2. Spain Trophy Banner
  void _paintSpain(Canvas canvas, Size size) {
    final ribbonRed = Paint()..color = const Color(0xFFEF4444);
    final ribbonYellow = Paint()..color = const Color(0xFFFACC15);

    // Bottom strip (snug within 3px)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, size.height - 3, size.width - 4, 3),
        const Radius.circular(1.5),
      ),
      ribbonRed,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.25, size.height - 3, size.width * 0.5, 3),
        const Radius.circular(1),
      ),
      ribbonYellow,
    );

    // Compact Trophy on bottom-left corner
    final trophyPaint = Paint()..color = const Color(0xFFFFD700);
    final cup = Path()
      ..moveTo(1, size.height - 9)
      ..lineTo(9, size.height - 9)
      ..lineTo(7, size.height - 4)
      ..lineTo(3, size.height - 4)
      ..close();
    canvas.drawPath(cup, trophyPaint);
    canvas.drawRect(Rect.fromLTWH(4, size.height - 4, 2, 3), trophyPaint);
  }

  // 3. Argentina Trophy Banner
  void _paintArgentina(Canvas canvas, Size size) {
    final skyBlue = Paint()..color = const Color(0xFF60A5FA);
    final white = Paint()..color = Colors.white;

    // Sky blue & white ribbon at bottom
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, size.height - 3, size.width - 4, 3),
        const Radius.circular(1.5),
      ),
      skyBlue,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.3, size.height - 3, size.width * 0.4, 3),
        const Radius.circular(1),
      ),
      white,
    );

    // Compact Golden Cup on bottom-left
    final gold = Paint()..color = const Color(0xFFFFD700);
    canvas.drawOval(Rect.fromLTWH(1, size.height - 9, 8, 8), gold);
    canvas.drawCircle(Offset(13, size.height - 2.5), 3, white);
  }

  // 4. Face Hug - Peeking Character
  void _paintFaceHug(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF334155);
    final skin = Paint()..color = const Color(0xFFFFD1BA);
    final hair = Paint()..color = const Color(0xFF1E293B);

    // Compact Head on top-left corner
    final headRect = Rect.fromLTWH(4, -5, 16, 11);
    canvas.drawOval(headRect, skin);
    canvas.drawOval(headRect, outline);

    // Hair
    final hairPath = Path()
      ..moveTo(4, -1)
      ..quadraticBezierTo(12, -7, 20, -1)
      ..lineTo(20, -3)
      ..quadraticBezierTo(12, -8, 4, -3)
      ..close();
    canvas.drawPath(hairPath, hair);

    // Hands
    canvas.drawCircle(Offset(5, 0), 2.2, skin);
    canvas.drawCircle(Offset(5, 0), 2.2, outline);
    canvas.drawCircle(Offset(19, 0), 2.2, skin);
    canvas.drawCircle(Offset(19, 0), 2.2, outline);
  }

  // 5. Pepe Heart
  void _paintPepeHeart(Canvas canvas, Size size) {
    final frogGreen = Paint()..color = const Color(0xFF65A30D);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF3F6212);

    // Compact Pepe Head on top-left
    final head = Rect.fromLTWH(3, -5, 14, 10);
    canvas.drawOval(head, frogGreen);
    canvas.drawOval(head, outline);

    // Bulging Eyes
    final eyeWhite = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(7, -5), 2.8, eyeWhite);
    canvas.drawCircle(Offset(7, -5), 2.8, outline);
    canvas.drawCircle(Offset(13, -5), 2.8, eyeWhite);
    canvas.drawCircle(Offset(13, -5), 2.8, outline);
    canvas.drawCircle(Offset(8, -5), 1.0, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(14, -5), 1.0, Paint()..color = Colors.black);

    // Floating Heart on top-right corner
    _drawHeart(canvas, Offset(size.width - 8, -2), 4.5, const Color(0xFFEC4899));
  }

  // 6. Shark & Pig
  void _paintSharkPig(Canvas canvas, Size size) {
    final pigPink = Paint()..color = const Color(0xFFF472B6);
    final pigOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFDB2777);

    // Compact Pig on bottom-left corner
    final pigBody = Rect.fromLTWH(2, size.height - 9, 13, 10);
    canvas.drawOval(pigBody, pigPink);
    canvas.drawOval(pigBody, pigOutline);
    canvas.drawOval(Rect.fromLTWH(3.5, size.height - 6, 5, 3.5), Paint()..color = const Color(0xFFFBCFE8));

    // Compact Shark on bottom-right corner
    final sharkBlue = Paint()..color = const Color(0xFF38BDF8);
    final sharkOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF0284C7);

    final sharkBody = Rect.fromLTWH(size.width - 15, size.height - 9, 13, 10);
    canvas.drawOval(sharkBody, sharkBlue);
    canvas.drawOval(sharkBody, sharkOutline);

    // Shark Fin
    final fin = Path()
      ..moveTo(size.width - 9, size.height - 9)
      ..lineTo(size.width - 6, size.height - 13)
      ..lineTo(size.width - 4, size.height - 9)
      ..close();
    canvas.drawPath(fin, sharkBlue);
    canvas.drawPath(fin, sharkOutline);
  }

  // 7. Bear Tongue
  void _paintBearTongue(Canvas canvas, Size size) {
    final bearBrown = Paint()..color = const Color(0xFF854D0E);
    final bearOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF713F12);

    final head = Rect.fromLTWH(3, -5, 14, 10);
    canvas.drawOval(head, bearBrown);
    canvas.drawOval(head, bearOutline);

    // Bear Ears
    canvas.drawCircle(Offset(4.5, -4.5), 2.5, bearBrown);
    canvas.drawCircle(Offset(15.5, -4.5), 2.5, bearBrown);

    // Tongue Accent on bottom
    final tongueRed = Paint()..color = const Color(0xFFF43F5E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, size.height - 2.5, size.width - 16, 3),
        const Radius.circular(1.5),
      ),
      tongueRed,
    );
  }

  // 8. Frog & Chick in Bathtub
  void _paintFrogChick(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF0369A1);

    // Compact Green Frog on top-left
    final frog = Paint()..color = const Color(0xFF22C55E);
    canvas.drawCircle(Offset(9, -2), 5, frog);
    canvas.drawCircle(Offset(9, -2), 5, outline);
    canvas.drawCircle(Offset(6.5, -5.5), 2.2, frog);
    canvas.drawCircle(Offset(11.5, -5.5), 2.2, frog);

    // Compact Yellow Chick on top-right
    final chick = Paint()..color = const Color(0xFFFACC15);
    canvas.drawCircle(Offset(size.width - 9, -2), 5, chick);
    canvas.drawCircle(Offset(size.width - 9, -2), 5, outline);
    // Beak
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 14, -2)
        ..lineTo(size.width - 17, -0.5)
        ..lineTo(size.width - 14, 1)
        ..close(),
      Paint()..color = const Color(0xFFEA580C),
    );

    // Soap Bubbles on bottom-right
    final bubble = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(size.width - 8, size.height - 1), 2.5, bubble);
    canvas.drawCircle(Offset(size.width - 13, size.height - 1), 2.0, bubble);
  }

  // 9. Hungry Hotdog Pup
  void _paintDogHungry(Canvas canvas, Size size) {
    final dogYellow = Paint()..color = const Color(0xFFFDE047);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF991B1B);

    // Compact Dog head on left
    final head = Rect.fromLTWH(-4, size.height * 0.25, 8, size.height * 0.5);
    canvas.drawOval(head, dogYellow);
    canvas.drawOval(head, outline);

    // Floppy Ear
    canvas.drawOval(Rect.fromLTWH(-5, size.height * 0.2, 4, 8), Paint()..color = const Color(0xFFEAB308));

    // Mustard squiggle across top
    final mustard = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFFEF08A);
    final mPath = Path()
      ..moveTo(6, 3)
      ..quadraticBezierTo(size.width * 0.3, 1, size.width * 0.5, 3)
      ..quadraticBezierTo(size.width * 0.7, 5, size.width - 6, 3);
    canvas.drawPath(mPath, mustard);
  }

  // 10. Dino Roar
  void _paintDino(Canvas canvas, Size size) {
    final dinoTeal = Paint()..color = const Color(0xFF0D9488);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF115E59);

    // Dino mouth on left edge
    final mouth = Path()
      ..moveTo(0, 4)
      ..lineTo(-4, size.height * 0.35)
      ..lineTo(-1, size.height * 0.50)
      ..lineTo(-4, size.height * 0.65)
      ..lineTo(0, size.height - 4)
      ..close();
    canvas.drawPath(mouth, dinoTeal);
    canvas.drawPath(mouth, outline);

    // Teeth
    final teeth = Paint()..color = Colors.white;
    canvas.drawPath(
      Path()
        ..moveTo(-0.5, 6)
        ..lineTo(-2.5, 9)
        ..lineTo(-0.5, 12)
        ..close(),
      teeth,
    );

    // Compact back spikes on top-right
    for (int i = 0; i < 3; i++) {
      final sx = size.width - 18 + i * 5.5;
      final spike = Path()
        ..moveTo(sx, 0)
        ..lineTo(sx + 2, -3.5)
        ..lineTo(sx + 4, 0)
        ..close();
      canvas.drawPath(spike, dinoTeal);
    }
  }

  // 11. Dachshund Dog Body
  void _paintDachshund(Canvas canvas, Size size) {
    final dogBrown = Paint()..color = const Color(0xFF78350F);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF451A03);

    // Dachshund Head on left corner
    final head = Rect.fromLTWH(-5, 2, 10, 12);
    canvas.drawOval(head, dogBrown);
    canvas.drawOval(head, outline);

    // Floppy Ear
    final ear = Rect.fromLTWH(-6, 4, 4.5, 9);
    canvas.drawOval(ear, Paint()..color = const Color(0xFF92400E));

    // Stubby Paws on bottom
    canvas.drawOval(Rect.fromLTWH(6, size.height - 2, 5, 3.5), dogBrown);
    canvas.drawOval(Rect.fromLTWH(size.width - 11, size.height - 2, 5, 3.5), dogBrown);

    // Tail on right
    final tail = Path()
      ..moveTo(size.width, size.height * 0.35)
      ..quadraticBezierTo(size.width + 4, size.height * 0.2, size.width + 2, size.height * 0.45);
    canvas.drawPath(
      tail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF78350F),
    );
  }

  // 12. Frog Catching Fly
  void _paintFrogHungry(Canvas canvas, Size size) {
    final frogGreen = Paint()..color = const Color(0xFF4ADE80);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF15803D);

    // Frog on bottom-left corner
    final frogBody = Rect.fromLTWH(1, size.height - 11, 12, 11);
    canvas.drawOval(frogBody, frogGreen);
    canvas.drawOval(frogBody, outline);
    canvas.drawCircle(Offset(4, size.height - 11), 2.2, frogGreen);
    canvas.drawCircle(Offset(9, size.height - 11), 2.2, frogGreen);

    // Tongue arc
    final tongue = Path()
      ..moveTo(8, size.height - 4)
      ..quadraticBezierTo(size.width * 0.5, size.height - 1, size.width - 4, -1);
    canvas.drawPath(
      tongue,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFEF4444),
    );

    // Fly
    canvas.drawCircle(Offset(size.width - 4, -2), 1.6, Paint()..color = Colors.black);
  }

  // 13. Screaming Shout
  void _paintShout(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF9F1239);

    // Mouth on left edge
    final mouth = Rect.fromLTWH(-4, size.height * 0.3, 7, size.height * 0.4);
    canvas.drawOval(mouth, Paint()..color = const Color(0xFF881337));
    canvas.drawOval(mouth, outline);

    // Candy wrap on right
    final wrap = Path()
      ..moveTo(size.width, size.height * 0.35)
      ..lineTo(size.width + 4, size.height * 0.2)
      ..lineTo(size.width + 4, size.height * 0.8)
      ..lineTo(size.width, size.height * 0.65)
      ..close();
    canvas.drawPath(wrap, Paint()..color = const Color(0xFFFDA4AF));
    canvas.drawPath(wrap, outline);
  }

  // 14. Olivia Rodrigo Blossom
  void _paintOlivia(Canvas canvas, Size size) {
    final pinkPaint = Paint()..color = const Color(0xFFDB2777);

    // Small Blossom on top-left
    _drawFlower(canvas, Offset(6, 6), 4.2, pinkPaint);
    // Small Butterfly on bottom-right
    _drawButterfly(canvas, Offset(size.width - 7, size.height - 7), 5.0, pinkPaint);
  }

  // 15. Duck & Frog
  void _paintFrogDuck(Canvas canvas, Size size) {
    final duckYellow = Paint()..color = const Color(0xFFFDE047);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFCA8A04);

    // Duck Tail on left
    final tail = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(-4, size.height * 0.45)
      ..lineTo(0, size.height * 0.6)
      ..close();
    canvas.drawPath(tail, duckYellow);
    canvas.drawPath(tail, outline);

    // Duck Head on top-right
    canvas.drawCircle(Offset(size.width - 6, -2), 5.5, duckYellow);
    canvas.drawCircle(Offset(size.width - 6, -2), 5.5, outline);
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 1, -2)
        ..lineTo(size.width + 3.5, -0.5)
        ..lineTo(size.width - 1, 1)
        ..close(),
      Paint()..color = const Color(0xFFEA580C),
    );

    // Mini Frog on Duck Head
    canvas.drawCircle(Offset(size.width - 11, -5.5), 3.0, Paint()..color = const Color(0xFF22C55E));
  }

  // 16. Buff Muscle Cat
  void _paintCatMuscle(Canvas canvas, Size size) {
    final catWhite = Paint()..color = Colors.white;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF1E293B);

    // Arm on top-left
    final arm = Path()
      ..moveTo(3, 4)
      ..lineTo(-3, -2)
      ..lineTo(-1, -7)
      ..lineTo(5, -4)
      ..lineTo(5, 2)
      ..close();
    canvas.drawPath(arm, catWhite);
    canvas.drawPath(arm, outline);

    // Cat Head on top-right
    final head = Rect.fromLTWH(size.width - 14, -5, 12, 9);
    canvas.drawOval(head, catWhite);
    canvas.drawOval(head, outline);
    // Ears
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 14, -3)
        ..lineTo(size.width - 12, -8)
        ..lineTo(size.width - 8, -4)
        ..close(),
      catWhite,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 14, -3)
        ..lineTo(size.width - 12, -8)
        ..lineTo(size.width - 8, -4)
        ..close(),
      outline,
    );
  }

  // 17. Capybara with Orange
  void _paintCapybara(Canvas canvas, Size size) {
    final capyBrown = Paint()..color = const Color(0xFFB45309);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF78350F);

    // Snout on left edge (compact, only 4px out)
    final snout = Rect.fromLTWH(-4, size.height * 0.25, 9, size.height * 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(snout, const Radius.circular(3.5)), capyBrown);
    canvas.drawRRect(RRect.fromRectAndRadius(snout, const Radius.circular(3.5)), outline);

    // Ear
    canvas.drawCircle(Offset(1, size.height * 0.25), 2, capyBrown);

    // Mini Tangerine with leaf
    final orange = Paint()..color = const Color(0xFFF97316);
    canvas.drawCircle(Offset(-1, size.height * 0.2 - 2), 3.0, orange);
    canvas.drawCircle(Offset(-1, size.height * 0.2 - 4.5), 0.9, Paint()..color = const Color(0xFF15803D));
  }

  // 18. Frog Box (Frog Face Bubble)
  void _paintFrogBox(Canvas canvas, Size size) {
    final frogGreen = Paint()..color = const Color(0xFF15803D);
    final eyeWhite = Paint()..color = Colors.white;
    final pupilBlack = Paint()..color = Colors.black;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF14532D);

    // Compact Frog Eye on top-left
    canvas.drawCircle(Offset(12, -2), 4.5, frogGreen);
    canvas.drawCircle(Offset(12, -2), 4.5, outline);
    canvas.drawCircle(Offset(12, -2), 3.0, eyeWhite);
    canvas.drawCircle(Offset(12, -2), 1.5, pupilBlack);

    // Compact Frog Eye on top-right
    canvas.drawCircle(Offset(size.width - 12, -2), 4.5, frogGreen);
    canvas.drawCircle(Offset(size.width - 12, -2), 4.5, outline);
    canvas.drawCircle(Offset(size.width - 12, -2), 3.0, eyeWhite);
    canvas.drawCircle(Offset(size.width - 12, -2), 1.5, pupilBlack);

    // Bottom strip
    final mouthBar = Rect.fromLTWH(8, size.height - 3, size.width - 16, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mouthBar, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFFEA580C),
    );
  }

  // 19. Cat & Dog Pillow Banner
  void _paintCatDog(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF78350F);

    // Compact Cat on top-left
    final catOrange = Paint()..color = const Color(0xFFF97316);
    final catHead = Rect.fromLTWH(3, -5, 12, 9);
    canvas.drawOval(catHead, catOrange);
    canvas.drawOval(catHead, outline);
    // Ears
    canvas.drawPath(
      Path()
        ..moveTo(3, -3)
        ..lineTo(4.5, -8)
        ..lineTo(8, -5)
        ..close(),
      catOrange,
    );

    // Compact Dog on top-right
    final dogBlue = Paint()..color = const Color(0xFF60A5FA);
    final dogHead = Rect.fromLTWH(size.width - 15, -5, 12, 9);
    canvas.drawOval(dogHead, dogBlue);
    canvas.drawOval(dogHead, outline);

    // Paws
    canvas.drawOval(Rect.fromLTWH(5, size.height - 2.5, 6, 3.5), catOrange);
    canvas.drawOval(Rect.fromLTWH(size.width - 11, size.height - 2.5, 6, 3.5), dogBlue);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(center.dx, center.dy + size * 0.6)
      ..cubicTo(
        center.dx - size,
        center.dy - size * 0.3,
        center.dx - size * 0.5,
        center.dy - size,
        center.dx,
        center.dy - size * 0.4,
      )
      ..cubicTo(
        center.dx + size * 0.5,
        center.dy - size,
        center.dx + size,
        center.dy - size * 0.3,
        center.dx,
        center.dy + size * 0.6,
      );
    canvas.drawPath(path, paint);
  }

  void _drawFlower(Canvas canvas, Offset center, double radius, Paint paint) {
    for (int i = 0; i < 5; i++) {
      final angle = i * (2 * math.pi / 5);
      final px = center.dx + math.cos(angle) * (radius * 0.6);
      final py = center.dy + math.sin(angle) * (radius * 0.6);
      canvas.drawCircle(Offset(px, py), radius * 0.4, paint);
    }
    canvas.drawCircle(center, radius * 0.35, Paint()..color = const Color(0xFFFDE047));
  }

  void _drawButterfly(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 2, center.dy - 2), width: size * 0.7, height: size * 0.9), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 2, center.dy - 2), width: size * 0.7, height: size * 0.9), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - 1.5, center.dy + 2), width: size * 0.5, height: size * 0.6), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx + 1.5, center.dy + 2), width: size * 0.5, height: size * 0.6), paint);
    canvas.drawRect(Rect.fromCenter(center: center, width: 1.0, height: size * 0.8), Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant ChatBubbleDecorPainter oldDelegate) {
    return oldDelegate.theme.id != theme.id || oldDelegate.isMe != isMe;
  }
}
