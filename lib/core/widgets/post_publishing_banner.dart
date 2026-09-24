import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/post_publishing_service.dart';

class PostPublishingBannerHost extends StatefulWidget {
  const PostPublishingBannerHost({super.key});

  @override
  State<PostPublishingBannerHost> createState() => _PostPublishingBannerHostState();
}

class _PostPublishingBannerHostState extends State<PostPublishingBannerHost>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
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
    _progressController.dispose();
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

      if (service.isUploading) {
        _progressController.reset();
        _progressController.animateTo(
          0.88,
          duration: const Duration(milliseconds: 3200),
          curve: Curves.easeOutCubic,
        );
      } else if (service.isSuccess) {
        _progressController.animateTo(
          1.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
      setState(() {});
    } else {
      if (_animController.isCompleted || _animController.isAnimating) {
        _animController.reverse().then((_) {
          if (mounted) {
            _progressController.reset();
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
                  child: Stack(
                    children: [
                      // Full background progress bar fill during upload & success
                      if (service.isUploading || service.isSuccess)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, _) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressController.value.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF383C4A).withValues(alpha: 0.65)
                                        : const Color(0xFF333846).withValues(alpha: 0.70),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      Padding(
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
                    ],
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
            const _RotatingSpinnerIcon(size: 20),
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
          const _RotatingSpinnerIcon(size: 20),
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
                    errorBuilder: (_, __, ___) => _buildFallbackThumbnail(service.isVideo),
                  )
                else
                  _buildFallbackThumbnail(service.isVideo),

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

  Widget _buildFallbackThumbnail(bool isVideo) {
    return Container(
      width: 42,
      height: 42,
      color: const Color(0xFF333642),
      child: Icon(
        isVideo ? Icons.videocam_rounded : Icons.image_rounded,
        color: Colors.white54,
        size: 20,
      ),
    );
  }
}

class _RotatingSpinnerIcon extends StatefulWidget {
  final double size;
  const _RotatingSpinnerIcon({this.size = 20});

  @override
  State<_RotatingSpinnerIcon> createState() => _RotatingSpinnerIconState();
}

class _RotatingSpinnerIconState extends State<_RotatingSpinnerIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spinnerController,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _SpinnerArcPainter(),
      ),
    );
  }
}

class _SpinnerArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 3.5) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepGradient = SweepGradient(
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.6),
        Colors.white,
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    canvas.drawArc(rect, 0.0, math.pi * 1.5, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
