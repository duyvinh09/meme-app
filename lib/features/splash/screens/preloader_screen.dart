import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class PreloaderScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final Future<void> Function()? preloadAction;
  final Duration minDisplayDuration;

  const PreloaderScreen({
    super.key,
    this.onComplete,
    this.preloadAction,
    this.minDisplayDuration = const Duration(milliseconds: 2200),
  });

  @override
  State<PreloaderScreen> createState() => _PreloaderScreenState();
}

class _PreloaderScreenState extends State<PreloaderScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _exitController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _footerFade;
  late final Animation<Offset> _footerSlide;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (Facebook-style smooth entrance)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _footerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    _footerSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Subtle pulse/breath animation (keeps center logo alive while loading)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 3. Exit fade animation
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
    _exitFade = _exitController;

    _startFlow();
  }

  Future<void> _startFlow() async {
    final startTime = DateTime.now();

    _entranceController.forward().then((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    // Thực hiện tác vụ nạp trước dữ liệu trong khi preloader đang hiển thị
    if (widget.preloadAction != null) {
      try {
        await widget.preloadAction!();
      } catch (e) {
        debugPrint('Preloader preloadAction error: $e');
      }
    }

    // Đảm bảo hiển thị ít nhất bằng minDisplayDuration để tạo trải nghiệm mượt mà
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < widget.minDisplayDuration) {
      await Future.delayed(widget.minDisplayDuration - elapsed);
    }

    _finishPreloader();
  }

  void _finishPreloader() {
    if (!mounted) return;
    _exitController.reverse().then((_) {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF090A0F)
        : const Color(0xFFFFFFFF);

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: backgroundColor,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: backgroundColor,
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: FadeTransition(
          opacity: _exitFade,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle ambient glow behind center
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryBlue.withValues(
                            alpha: isDark ? 0.08 : 0.04,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Center: meme_wordmark.png logo
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_entranceController, _pulseController]),
                  builder: (context, child) {
                    final pulseScale = 1.0 + (_pulseController.value * 0.022);
                    return FadeTransition(
                      opacity: _logoFade,
                      child: Transform.scale(
                        scale: _logoScale.value * pulseScale,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/icons/meme_wordmark.png',
                    width: 195,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'meme',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          color: AppColors.primaryBlue,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bottom: Facebook-style "from MEME" branding
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: FadeTransition(
                      opacity: _footerFade,
                      child: SlideTransition(
                        position: _footerSlide,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'from',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? const Color(0xFF7A7E89)
                                    : const Color(0xFF8A8E99),
                              ),
                            ),
                            const SizedBox(height: 5),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF50ADFE),
                                  Color(0xFF79AFFF),
                                  Color(0xFF8B7CFF),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: const Text(
                                'M E M E',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4.2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Subtle sleek loader indicator
                            _FacebookStyleLoadingIndicator(isDark: isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacebookStyleLoadingIndicator extends StatefulWidget {
  final bool isDark;

  const _FacebookStyleLoadingIndicator({required this.isDark});

  @override
  State<_FacebookStyleLoadingIndicator> createState() =>
      _FacebookStyleLoadingIndicatorState();
}

class _FacebookStyleLoadingIndicatorState
    extends State<_FacebookStyleLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return SizedBox(
      width: 44,
      height: 2.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Container(color: trackColor),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _controller.value;
                return Align(
                  alignment: Alignment(-1.0 + (progress * 2.0), 0.0),
                  child: Container(
                    width: 20,
                    height: 2.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF50ADFE),
                          Color(0xFF8B7CFF),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
