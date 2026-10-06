import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../constants/app_icon_registry.dart';
import '../../constants/widget_frames.dart';

class MomentWidgetData {
  final int streak;
  final String type; // 'expense' | 'income'
  final double amount;
  final String formattedAmount;
  final String caption;
  final String category;
  final int? categoryIconCodePoint;
  final String? categoryColorHex;
  final String? groupName;
  final String? authorName;
  final Uint8List? imageBytes;
  final ui.Image? decodedImage;
  final bool isVideo;
  final bool isDark;
  final bool isEn;
  final bool hasTransaction;
  final String widgetFrame;

  const MomentWidgetData({
    required this.streak,
    required this.type,
    required this.amount,
    required this.formattedAmount,
    required this.caption,
    this.category = '',
    this.categoryIconCodePoint,
    this.categoryColorHex,
    this.groupName,
    this.authorName,
    this.imageBytes,
    this.decodedImage,
    this.isVideo = false,
    this.isDark = true,
    this.isEn = false,
    this.hasTransaction = true,
    this.widgetFrame = 'none',
  });
}

class MomentAppWidgetView extends StatelessWidget {
  final MomentWidgetData data;

  const MomentAppWidgetView({
    super.key,
    required this.data,
  });

  static const Map<String, Map<String, dynamic>> _defaultCategoryMeta = {
    'Ăn uống': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFFF9F43),
    },
    'Food': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFFF9F43),
    },
    'Mua sắm': {
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFFF5252),
    },
    'Shopping': {
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFFF5252),
    },
    'Di chuyển': {
      'icon': Icons.directions_car_rounded,
      'color': Color(0xFF48DBFB),
    },
    'Đi lại': {
      'icon': Icons.directions_car_rounded,
      'color': Color(0xFF48DBFB),
    },
    'Transport': {
      'icon': Icons.directions_car_rounded,
      'color': Color(0xFF48DBFB),
    },
    'Giải trí': {
      'icon': Icons.sports_esports_rounded,
      'color': Color(0xFF9B59B6),
    },
    'Entertainment': {
      'icon': Icons.sports_esports_rounded,
      'color': Color(0xFF9B59B6),
    },
    'Giáo dục': {
      'icon': Icons.school_rounded,
      'color': Color(0xFF2ECC71),
    },
    'Học tập': {
      'icon': Icons.school_rounded,
      'color': Color(0xFF2ECC71),
    },
    'Education': {
      'icon': Icons.school_rounded,
      'color': Color(0xFF2ECC71),
    },
    'Lương': {
      'icon': Icons.payments_rounded,
      'color': Color(0xFF10B981),
    },
    'Salary': {
      'icon': Icons.payments_rounded,
      'color': Color(0xFF10B981),
    },
    'Quà tặng': {
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFFFF6B6B),
    },
    'Gift': {
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFFFF6B6B),
    },
    'Quỹ nhóm': {
      'icon': Icons.groups_rounded,
      'color': Color(0xFFFFD166),
    },
    'Group Fund': {
      'icon': Icons.groups_rounded,
      'color': Color(0xFFFFD166),
    },
    'Khác': {
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFFAAAAAA),
    },
    'Other': {
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFFAAAAAA),
    },
  };

  IconData _resolveCategoryIcon() {
    if (data.categoryIconCodePoint != null && data.categoryIconCodePoint! > 0) {
      return AppIconRegistry.fromCodePoint(data.categoryIconCodePoint!);
    }
    final meta = _defaultCategoryMeta[data.category];
    if (meta != null && meta['icon'] is IconData) {
      return meta['icon'] as IconData;
    }
    return Icons.account_balance_wallet_rounded;
  }

  Color _resolveCategoryColor() {
    if (data.categoryColorHex != null && data.categoryColorHex!.trim().isNotEmpty) {
      var cleaned = data.categoryColorHex!.trim().replaceAll('#', '');
      if (cleaned.length == 6) {
        cleaned = 'FF$cleaned';
      }
      if (cleaned.length == 8) {
        try {
          return Color(int.parse(cleaned, radix: 16));
        } catch (_) {}
      }
    }
    final meta = _defaultCategoryMeta[data.category];
    if (meta != null && meta['color'] is Color) {
      return meta['color'] as Color;
    }
    return const Color(0xFF79AFFF);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = data.isDark;
    final isExpense = data.type == 'expense';
    final hasImage = data.imageBytes != null && data.imageBytes!.isNotEmpty;

    // Translucent Frosted Glass Tint for Income / Expense Badge
    final badgeBgColor = isExpense
        ? const Color(0xFFFF3B30).withValues(alpha: 0.40)
        : const Color(0xFF10B981).withValues(alpha: 0.40);

    final badgeBorderColor = isExpense
        ? const Color(0xFFFF6961).withValues(alpha: 0.65)
        : const Color(0xFF34D399).withValues(alpha: 0.65);

    final sign = isExpense ? '-' : '+';
    final displayAmount = data.hasTransaction
        ? '$sign${data.formattedAmount}'
        : '';

    final catColor = _resolveCategoryColor();
    final catIcon = _resolveCategoryIcon();

    final frameItem = WidgetFrames.getById(data.widgetFrame);
    final hasFrame = !frameItem.isNone && frameItem.gradient != null;
    final borderWidth = hasFrame ? frameItem.borderWidth : 1.0;

    return MediaQuery(
      data: const MediaQueryData(
        size: Size(220, 220),
        devicePixelRatio: 2.5,
        textScaler: TextScaler.noScaling,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 220,
            height: 220,
            padding: hasFrame ? EdgeInsets.all(borderWidth) : EdgeInsets.zero,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: hasFrame ? frameItem.gradient : null,
              border: hasFrame
                  ? null
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFE5E9F2),
                      width: 1,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(hasFrame ? (26 - borderWidth) : 25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background (Image OR Category-Themed Card)
                  if (data.decodedImage != null) ...[
                    RawImage(
                      image: data.decodedImage!,
                      fit: BoxFit.cover,
                      width: 220,
                      height: 220,
                      filterQuality: FilterQuality.medium,
                    ),

                    // Video Play Icon Indicator if it's a video
                    if (data.isVideo)
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                  ] else if (hasImage) ...[
                    Image.memory(
                      data.imageBytes!,
                      fit: BoxFit.cover,
                      width: 220,
                      height: 220,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                    ),

                    // Video Play Icon Indicator if it's a video
                    if (data.isVideo)
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                  ] else ...[
                    // Category-themed card background when there's no photo/video
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  catColor.withValues(alpha: 0.28),
                                  const Color(0xFF14151B),
                                  const Color(0xFF0F1015),
                                ]
                              : [
                                  catColor.withValues(alpha: 0.18),
                                  const Color(0xFFF6F8FC),
                                  const Color(0xFFEDF2F9),
                                ],
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: catColor.withValues(alpha: 0.24),
                                  border: Border.all(
                                    color: catColor.withValues(alpha: 0.55),
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: catColor.withValues(alpha: 0.35),
                                      blurRadius: 22,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  catIcon,
                                  size: 42,
                                  color: catColor,
                                ),
                              ),
                              if (data.category.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  data.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'ProximaSoft',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E2235),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // 2. Dark Overlay Gradients for Readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: hasImage ? 0.45 : 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: hasImage ? 0.85 : 0.65),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. Top Row: Streak Badge (Left) & Translucent Income/Expense Badge (Right)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Streak Badge (Top Left)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 13,
                                color: Color(0xFFFF5722),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${data.streak}',
                                style: const TextStyle(
                                  fontFamily: 'ProximaSoft',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expense / Income Badge (Top Right - Translucent Frosted Glass)
                        if (data.hasTransaction && displayAmount.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: badgeBorderColor,
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              displayAmount,
                              style: const TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 4. Bottom Row: Group/User Name & Caption
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Group Name or Author Subtitle if applicable
                        if (data.groupName != null && data.groupName!.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.group_rounded,
                                size: 12,
                                color: Color(0xFFFFD166),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data.groupName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'ProximaSoft',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFFD166),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ] else if (data.authorName != null && data.authorName!.isNotEmpty) ...[
                          Text(
                            data.authorName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'ProximaSoft',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],

                        // Main Caption Text
                        Text(
                          data.hasTransaction && data.caption.isNotEmpty
                              ? data.caption
                              : (data.hasTransaction
                                  ? (data.category.isNotEmpty
                                      ? data.category
                                      : (isExpense
                                          ? (data.isEn ? 'New Expense' : 'Chi tiêu mới')
                                          : (data.isEn ? 'New Income' : 'Thu nhập mới')))
                                  : (data.isEn
                                      ? 'Tap to add spending 📸'
                                      : 'Chạm để thêm chi tiêu 📸')),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'ProximaSoft',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
