import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TransactionMomentImage extends StatelessWidget {
  final String imageUrl;
  final String category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? caption;

  final int? categoryIconCodePoint;
  final String? categoryColorHex;

  final bool isVideo;
  final bool showVideoBadge;

  const TransactionMomentImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.caption,
    this.categoryIconCodePoint,
    this.categoryColorHex,
    this.isVideo = false,
    this.showVideoBadge = true,
  });

  static const Map<String, Map<String, dynamic>> _defaultCategoryMeta = {
    'Ăn uống': {
      'icon': Icons.shopping_cart_outlined,
      'color': Color(0xFF59D46F),
    },
    'Mua sắm': {
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFFF4D8D),
    },
    'Đi lại': {
      'icon': Icons.directions_bus_outlined,
      'color': Color(0xFF2F9BFF),
    },
    'Giải trí': {
      'icon': Icons.movie_outlined,
      'color': Color(0xFFFFA52F),
    },
    'Học tập': {
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFF8B7CFF),
    },
    'Lương': {
      'icon': Icons.payments_outlined,
      'color': Color(0xFF7DFFA1),
    },
    'Quà tặng': {
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFFFF4D4D),
    },
    'Khác': {
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFFAAAAAA),
    },
  };

  IconData get _icon {
    if (isVideo) {
      return Icons.play_arrow_rounded;
    }

    if (categoryIconCodePoint != null && categoryIconCodePoint! > 0) {
      return IconData(
        categoryIconCodePoint!,
        fontFamily: 'MaterialIcons',
      );
    }

    return _defaultCategoryMeta[category]?['icon'] as IconData? ??
        Icons.account_balance_wallet_outlined;
  }

  Color get _color {
    final savedColor = _parseColorHex(categoryColorHex);

    if (savedColor != null) {
      return savedColor;
    }

    if (isVideo) {
      return const Color(0xFF5E5CE6);
    }

    return _defaultCategoryMeta[category]?['color'] as Color? ??
        _fallbackTopicColor(category);
  }

  Color? _parseColorHex(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    var cleaned = value.trim().replaceAll('#', '');

    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    if (cleaned.length != 8) return null;

    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return null;
    }
  }

  Color _fallbackTopicColor(String value) {
    const colors = [
      Color(0xFF79AFFF),
      Color(0xFF7CC486),
      Color(0xFFFF8B8B),
      Color(0xFFFFB457),
      Color(0xFFB466CB),
      Color(0xFF1CC5C0),
    ];

    final index = value.hashCode.abs() % colors.length;
    return colors[index];
  }

  int? _cacheSize(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      return null;
    }

    return (value * 2).round();
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    final trimmedImageUrl = imageUrl.trim();

    final content = trimmedImageUrl.isEmpty
        ? _withVideoOverlay(
      radius: radius,
      child: _buildGeneratedMoment(radius),
    )
        : ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: trimmedImageUrl,
            width: width,
            height: height,
            fit: fit,
            alignment: Alignment.center,
            memCacheWidth: _cacheSize(width),
            memCacheHeight: _cacheSize(height),
            maxWidthDiskCache: _cacheSize(width),
            maxHeightDiskCache: _cacheSize(height),
            fadeInDuration: const Duration(milliseconds: 120),
            fadeOutDuration: const Duration(milliseconds: 80),
            useOldImageOnUrlChange: true,
            filterQuality: FilterQuality.low,
            placeholder: (context, url) {
              return _buildGeneratedMoment(
                radius,
                centerChild: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              );
            },
            errorWidget: (context, url, error) {
              return _buildGeneratedMoment(radius);
            },
          ),
          if (isVideo && showVideoBadge) _buildVideoOverlay(),
        ],
      ),
    );

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: content,
      );
    }

    return content;
  }

  Widget _withVideoOverlay({
    required BorderRadius radius,
    required Widget child,
  }) {
    if (!isVideo || !showVideoBadge) return child;

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          _buildVideoOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = math.min(
          constraints.maxWidth.isFinite ? constraints.maxWidth : (width ?? 100),
          constraints.maxHeight.isFinite ? constraints.maxHeight : (height ?? 100),
        );

        final isTiny = boxSize <= 60;
        final isSmall = boxSize <= 90;

        final playSize = isTiny ? 20.0 : isSmall ? 30.0 : 42.0;
        final iconSize = isTiny ? 15.0 : isSmall ? 22.0 : 31.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(isTiny ? 0.05 : 0.08),
                ),
              ),
            ),
            Center(
              child: Container(
                width: playSize,
                height: playSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.34),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: isTiny ? 0.7 : 1,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
            if (!isTiny)
              Positioned(
                right: isSmall ? 4 : 7,
                top: isSmall ? 4 : 7,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 5 : 7,
                    vertical: isSmall ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.16),
                    ),
                  ),
                  child: Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 8 : 9.5,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGeneratedMoment(
      BorderRadius radius, {
        Widget? centerChild,
      }) {
    final icon = _icon;
    final color = _color;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : (width ?? 160);

            final maxHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : (height ?? 160);

            final boxSize = math.min(maxWidth, maxHeight);

            final isTiny = boxSize <= 70;
            final isSmall = boxSize <= 130;

            final iconCircleSize = isTiny
                ? (boxSize * 0.54).clamp(34.0, 42.0)
                : isSmall
                ? (boxSize * 0.58).clamp(48.0, 70.0)
                : (boxSize * 0.52).clamp(78.0, 138.0);

            final iconSize = centerChild != null
                ? (iconCircleSize * 0.42).clamp(18.0, 28.0)
                : isTiny
                ? (iconCircleSize * 0.58).clamp(22.0, 28.0)
                : isSmall
                ? (iconCircleSize * 0.56).clamp(30.0, 42.0)
                : (iconCircleSize * 0.54).clamp(46.0, 76.0);

            final categoryFontSize = isTiny
                ? 0.0
                : isSmall
                ? (boxSize * 0.105).clamp(10.0, 14.0)
                : (boxSize * 0.10).clamp(18.0, 28.0);

            final showCategoryText = !isTiny;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.96),
                    color.withOpacity(0.72),
                    const Color(0xFF20232C),
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
                            Colors.black.withOpacity(0.18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              width: iconCircleSize,
                              height: iconCircleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.24),
                                  width: isTiny ? 1.2 : 1.8,
                                ),
                              ),
                              child: Center(
                                child: centerChild ??
                                    Icon(
                                      icon,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                              ),
                            ),
                          ),
                          if (showCategoryText) ...[
                            SizedBox(height: isSmall ? 8 : 18),
                            Text(
                              isVideo ? 'Video' : category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: categoryFontSize,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}