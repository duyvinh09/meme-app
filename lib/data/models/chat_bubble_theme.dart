import 'package:flutter/material.dart';

enum ChatDecorStyle {
  none,
  doge,
  faceHug,
  pepeHeart,
  sharkPig,
  bearTongue,
  frogChick,
  dogHungry,
  dino,
  dachshund,
  frogHungry,
  shout,
  spain,
  argentina,
  olivia,
  frogDuck,
  catMuscle,
  capybara,
  frogBox,
  catDog,
}

class ChatBubbleTheme {
  final String id;
  final String nameVi;
  final String nameEn;
  final Color backgroundColor;
  final Gradient? gradient;
  final Color textColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final Color? glowColor;
  final ChatDecorStyle decorStyle;
  final bool isDefault;

  const ChatBubbleTheme({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.backgroundColor,
    this.gradient,
    required this.textColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.borderRadius = 18.0,
    this.glowColor,
    this.decorStyle = ChatDecorStyle.none,
    this.isDefault = false,
  });

  String get name => nameVi;

  String getName(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return isVi ? nameVi : nameEn;
  }

  static const List<ChatBubbleTheme> allThemes = [
    // 1. Mặc định / Classic
    ChatBubbleTheme(
      id: 'default',
      nameVi: 'Mặc định',
      nameEn: 'Default Blue',
      backgroundColor: Color(0xFF0084FF),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0099FF), Color(0xFF0066FF)],
      ),
      textColor: Colors.white,
      decorStyle: ChatDecorStyle.none,
      isDefault: true,
    ),

    // 2. Doge (Cuộn giấy Doge)
    ChatBubbleTheme(
      id: 'doge',
      nameVi: 'Doge',
      nameEn: 'Doge Scroll',
      backgroundColor: Color(0xFFFFF0CA),
      textColor: Color(0xFF3E2723),
      borderColor: Color(0xFFE0A96D),
      borderWidth: 1.8,
      borderRadius: 14.0,
      decorStyle: ChatDecorStyle.doge,
    ),

    // 3. Tây Ban Nha (Spain Champion)
    ChatBubbleTheme(
      id: 'spain',
      nameVi: 'Tây Ban Nha',
      nameEn: 'Spain Trophy',
      backgroundColor: Color(0xFFFFECC4),
      textColor: Color(0xFF5D120D),
      borderColor: Color(0xFFEF4444),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.spain,
    ),

    // 4. Argentina (Argentina Champion)
    ChatBubbleTheme(
      id: 'argentina',
      nameVi: 'Argentina',
      nameEn: 'Argentina Trophy',
      backgroundColor: Color(0xFFC7E8FF),
      textColor: Color(0xFF0C356A),
      borderColor: Color(0xFF60A5FA),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.argentina,
    ),

    // 5. Ôm mặt (Face Hug)
    ChatBubbleTheme(
      id: 'face_hug',
      nameVi: 'Ôm mặt',
      nameEn: 'Face Hug',
      backgroundColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF1E293B),
      borderColor: Color(0xFF475569),
      borderWidth: 2.0,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.faceHug,
    ),

    // 6. Pepe thả tim (Pepe Love)
    ChatBubbleTheme(
      id: 'pepe_heart',
      nameVi: 'Pepe thả tim',
      nameEn: 'Pepe Heart',
      backgroundColor: Color(0xFFFDE2E4),
      textColor: Color(0xFF701A75),
      borderColor: Color(0xFFF472B6),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.pepeHeart,
    ),

    // 7. Cá mập heo (Shark & Pig)
    ChatBubbleTheme(
      id: 'shark_pig',
      nameVi: 'Cá mập heo',
      nameEn: 'Shark & Pig',
      backgroundColor: Color(0xFFE0E7FF),
      textColor: Color(0xFF1E1B4B),
      borderColor: Color(0xFF818CF8),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.sharkPig,
    ),

    // 8. Gấu thè lưỡi (Bear Tongue)
    ChatBubbleTheme(
      id: 'bear_tongue',
      nameVi: 'Gấu thè lưỡi',
      nameEn: 'Bear Tongue',
      backgroundColor: Color(0xFFFFDDE1),
      textColor: Color(0xFF4C0519),
      borderColor: Color(0xFFFB7185),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.bearTongue,
    ),

    // 9. Ếch gà con (Frog & Chick)
    ChatBubbleTheme(
      id: 'frog_chick',
      nameVi: 'Ếch gà con',
      nameEn: 'Frog & Chick',
      backgroundColor: Color(0xFFBAE6FD),
      textColor: Color(0xFF0369A1),
      borderColor: Color(0xFF38BDF8),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.frogChick,
    ),

    // 10. Cún thèm ăn (Hungry Dog)
    ChatBubbleTheme(
      id: 'dog_hungry',
      nameVi: 'Cún thèm ăn',
      nameEn: 'Hotdog Pup',
      backgroundColor: Color(0xFFF87171),
      textColor: Colors.white,
      borderColor: Color(0xFFDC2626),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.dogHungry,
    ),

    // 11. Khủng long (Dino Roar)
    ChatBubbleTheme(
      id: 'dino',
      nameVi: 'Khủng long',
      nameEn: 'Dino Roar',
      backgroundColor: Color(0xFF99F6E4),
      textColor: Color(0xFF115E59),
      borderColor: Color(0xFF2DD4BF),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.dino,
    ),

    // 12. Chó lạp xưởng (Dachshund Dog)
    ChatBubbleTheme(
      id: 'dachshund',
      nameVi: 'Chó lạp xưởng',
      nameEn: 'Dachshund',
      backgroundColor: Color(0xFF926247),
      textColor: Colors.white,
      borderColor: Color(0xFF5A3825),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.dachshund,
    ),

    // 13. Ếch đói bụng (Hungry Frog)
    ChatBubbleTheme(
      id: 'frog_hungry',
      nameVi: 'Ếch đói bụng',
      nameEn: 'Frog Catch',
      backgroundColor: Color(0xFFE2F3E3),
      textColor: Color(0xFF14532D),
      borderColor: Color(0xFF86EFAC),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.frogHungry,
    ),

    // 14. La hét (Screaming Shout)
    ChatBubbleTheme(
      id: 'shout',
      nameVi: 'La hét',
      nameEn: 'Shouting Face',
      backgroundColor: Color(0xFFFDA4AF),
      textColor: Color(0xFF881337),
      borderColor: Color(0xFFF43F5E),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.shout,
    ),

    // 15. Olivia Rodrigo (Hoa bướm)
    ChatBubbleTheme(
      id: 'olivia',
      nameVi: 'Olivia Rodrigo',
      nameEn: 'Olivia Blossom',
      backgroundColor: Color(0xFFF9A8D4),
      textColor: Color(0xFF500724),
      borderColor: Color(0xFFEC4899),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.olivia,
    ),

    // 16. Ếch vịt (Frog Riding Duck)
    ChatBubbleTheme(
      id: 'frog_duck',
      nameVi: 'Ếch vịt',
      nameEn: 'Duck & Frog',
      backgroundColor: Color(0xFFFEF08A),
      textColor: Color(0xFF713F12),
      borderColor: Color(0xFFFACC15),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.frogDuck,
    ),

    // 17. Mèo khoe cơ (Muscle Buff Cat)
    ChatBubbleTheme(
      id: 'cat_muscle',
      nameVi: 'Mèo khoe cơ',
      nameEn: 'Buff Cat',
      backgroundColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF0F172A),
      borderColor: Color(0xFF334155),
      borderWidth: 2.0,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.catMuscle,
    ),

    // 18. Capybara (Chuột lang nước quả cam)
    ChatBubbleTheme(
      id: 'capybara',
      nameVi: 'Capybara',
      nameEn: 'Capybara Orange',
      backgroundColor: Color(0xFFD4A373),
      textColor: Color(0xFF3A1F04),
      borderColor: Color(0xFF8C531B),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.capybara,
    ),

    // 19. Ếch (Frog Head Box)
    ChatBubbleTheme(
      id: 'frog_box',
      nameVi: 'Ếch',
      nameEn: 'Frog Head',
      backgroundColor: Color(0xFF16A34A),
      textColor: Colors.white,
      borderColor: Color(0xFF15803D),
      borderWidth: 2.0,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.frogBox,
    ),

    // 20. Mèo chó (Cat & Dog Pillow Banner)
    ChatBubbleTheme(
      id: 'cat_dog',
      nameVi: 'Mèo chó',
      nameEn: 'Cat & Dog Pillow',
      backgroundColor: Color(0xFFFFFBEB),
      textColor: Color(0xFF451A03),
      borderColor: Color(0xFFFDE68A),
      borderWidth: 1.8,
      borderRadius: 16.0,
      decorStyle: ChatDecorStyle.catDog,
    ),
  ];

  static ChatBubbleTheme getTheme(String id) {
    for (final theme in allThemes) {
      if (theme.id == id) return theme;
    }
    return allThemes.first;
  }
}
