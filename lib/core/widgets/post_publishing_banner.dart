import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_icon_registry.dart';
import '../services/post_publishing_service.dart';

class PostPublishingBannerHost extends StatefulWidget {
  const PostPublishingBannerHost({super.key});

  @override
  State<PostPublishingBannerHost> createState() => _PostPublishingBannerHostState();
}

class _PostPublishingBannerHostState extends State<PostPublishingBannerHost>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    PostPublishingService.instance.addListener(_handleStateChange);
  }

  @override
  void dispose() {
    PostPublishingService.instance.removeListener(_handleStateChange);
    _animController.dispose();
    super.dispose();
  }

  void _handleStateChange() {
    if (!mounted) return;
    final service = PostPublishingService.instance;
    final isVisible = service.isVisible;

    if (isVisible) {
      if (!_animController.isCompleted && !_animController.isAnimating) {
        HapticFeedback.lightImpact();
        _animController.forward();
      }
      setState(() {});
    } else {
      if (_animController.isCompleted || _animController.isAnimating) {
        _animController.reverse().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = PostPublishingService.instance;
    if (!service.isVisible && _animController.isDismissed) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.maybeLocaleOf(context);
    final isEn = locale?.languageCode.toLowerCase() == 'en';
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bannerBottom = bottomInset + 104.0;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bannerBottom,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dismissible(
            key: const Key('post_publishing_banner_dismissible'),
            direction: DismissDirection.down,
            onDismissed: (_) {
              service.dismiss();
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2028).withValues(alpha: 0.96)
                      : const Color(0xFF181A20).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Status Icon & Status Text
                        Expanded(
                          child: _buildStatusSection(service, isEn),
                        ),

                        const SizedBox(width: 12),

                        // Media Thumbnail with Paperclip
                        _buildMediaThumbnailWithClip(service),

                        // "Xem" action button when success
                        if (service.isSuccess) ...[
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              service.viewPost();
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              child: Text(
                                isEn ? 'View' : 'Xem',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(PostPublishingService service, bool isEn) {
    if (service.isUploading) {
      if (service.isFinalizing) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isEn ? 'Posting...' : 'Đang đăng...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEn ? 'Posting...' : 'Đang đăng...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEn
                      ? 'Keep Meme open until upload completes.'
                      : 'Mở Meme cho đến khi tải lên xong.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (service.isSuccess) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isEn ? 'Posted' : 'Đã đăng',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      );
    }

    // Error
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFEF4444),
          size: 20,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            isEn ? 'Failed to post' : 'Đăng thất bại',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  static const Map<String, Map<String, dynamic>> _defaultCategoryMeta = {
    'Ăn uống': {
      'icon': Icons.shopping_cart_outlined,
      'color': Color(0xFF59D46F),
    },
    'Food': {
      'icon': Icons.shopping_cart_outlined,
      'color': Color(0xFF59D46F),
    },
    'Mua sắm': {
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFFF4D8D),
    },
    'Shopping': {
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFFF4D8D),
    },
    'Di chuyển': {
      'icon': Icons.directions_bus_outlined,
      'color': Color(0xFF2F9BFF),
    },
    'Đi lại': {
      'icon': Icons.directions_bus_outlined,
      'color': Color(0xFF2F9BFF),
    },
    'Transport': {
      'icon': Icons.directions_bus_outlined,
      'color': Color(0xFF2F9BFF),
    },
    'Giải trí': {
      'icon': Icons.movie_outlined,
      'color': Color(0xFFFFA52F),
    },
    'Entertainment': {
      'icon': Icons.movie_outlined,
      'color': Color(0xFFFFA52F),
    },
    'Giáo dục': {
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFF8B7CFF),
    },
    'Học tập': {
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFF8B7CFF),
    },
    'Education': {
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFF8B7CFF),
    },
    'Lương': {
      'icon': Icons.payments_outlined,
      'color': Color(0xFF7DFFA1),
    },
    'Salary': {
      'icon': Icons.payments_outlined,
      'color': Color(0xFF7DFFA1),
    },
    'Quà tặng': {
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFFFF4D4D),
    },
    'Gift': {
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFFFF4D4D),
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

  Widget _buildMediaThumbnailWithClip(PostPublishingService service) {
    final displayFile = service.thumbnailFile ??
        (!service.isVideo ? service.mediaFile : null);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2F38),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                if (displayFile != null && displayFile.existsSync())
                  Image.file(
                    displayFile,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackThumbnail(service),
                  )
                else
                  _buildFallbackThumbnail(service),

                // Video play indicator icon overlay
                if (service.isVideo)
                  Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.55),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Silver Metallic Paperclip pinned over top edge
        const Positioned(
          top: -8,
          right: 3,
          child: PaperclipWidget(
            width: 14,
            height: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackThumbnail(PostPublishingService service) {
    if (service.isVideo) {
      return Container(
        width: 42,
        height: 42,
        color: const Color(0xFF333642),
        child: const Icon(
          Icons.videocam_rounded,
          color: Colors.white54,
          size: 20,
        ),
      );
    }

    Color catColor = const Color(0xFF79AFFF);
    if (service.categoryColorHex != null &&
        service.categoryColorHex!.trim().isNotEmpty) {
      var cleaned = service.categoryColorHex!.trim().replaceAll('#', '');
      if (cleaned.length == 6) cleaned = 'FF$cleaned';
      if (cleaned.length == 8) {
        try {
          catColor = Color(int.parse(cleaned, radix: 16));
        } catch (_) {}
      }
    } else if (service.category != null && service.category!.trim().isNotEmpty) {
      final meta = _defaultCategoryMeta[service.category!.trim()];
      if (meta != null && meta['color'] is Color) {
        catColor = meta['color'] as Color;
      }
    }

    IconData catIcon = Icons.account_balance_wallet_rounded;
    if (service.categoryIconCodePoint != null &&
        service.categoryIconCodePoint! > 0) {
      catIcon = AppIconRegistry.fromCodePoint(service.categoryIconCodePoint!);
    } else if (service.category != null && service.category!.trim().isNotEmpty) {
      final meta = _defaultCategoryMeta[service.category!.trim()];
      if (meta != null && meta['icon'] is IconData) {
        catIcon = meta['icon'] as IconData;
      }
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catColor.withValues(alpha: 0.38),
            catColor.withValues(alpha: 0.18),
            const Color(0xFF1B1D24),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          catIcon,
          size: 21,
          color: catColor,
        ),
      ),
    );
  }
}

class PaperclipWidget extends StatelessWidget {
  final double width;
  final double height;

  const PaperclipWidget({
    super.key,
    this.width = 14,
    this.height = 25,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.15, // Slight natural tilt
      child: CustomPaint(
        size: Size(width, height),
        painter: _PaperclipPainter(),
      ),
    );
  }
}

class _PaperclipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow path
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    final path = Path();
    // Start inside bottom inner curve
    path.moveTo(w * 0.42, h * 0.62);
    path.lineTo(w * 0.42, h * 0.28);
    // Inner top curve
    path.arcToPoint(
      Offset(w * 0.76, h * 0.28),
      radius: Radius.circular(w * 0.17),
      clockwise: true,
    );
    // Outer down right line
    path.lineTo(w * 0.76, h * 0.78);
    // Bottom big outer curve
    path.arcToPoint(
      Offset(w * 0.18, h * 0.78),
      radius: Radius.circular(w * 0.29),
      clockwise: true,
    );
    // Outer up left line
    path.lineTo(w * 0.18, h * 0.20);
    // Top big outer curve
    path.arcToPoint(
      Offset(w * 0.94, h * 0.20),
      radius: Radius.circular(w * 0.38),
      clockwise: true,
    );
    // Down right end line
    path.lineTo(w * 0.94, h * 0.68);

    canvas.drawPath(path.shift(const Offset(0.8, 1.2)), shadowPaint);

    // Silver metallic gradient for paperclip wire
    final metallicPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE2E8F0),
          Color(0xFFCBD5E1),
          Color(0xFFFFFFFF),
          Color(0xFF94A3B8),
          Color(0xFFE2E8F0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, metallicPaint);

    // White shine highlight
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final shinePath = Path()
      ..moveTo(w * 0.18, h * 0.40)
      ..lineTo(w * 0.18, h * 0.22);
    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
