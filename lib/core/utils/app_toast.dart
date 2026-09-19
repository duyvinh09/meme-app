import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppToast {
  AppToast._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2000),
    bool isError = false,
    double bottomMargin = 20,
  }) {
    if (!context.mounted) return;

    try {
      HapticFeedback.lightImpact();

      // Dismiss existing toast
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _activeEntry?.remove();
      _activeEntry = null;

      final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
          Navigator.of(context, rootNavigator: true).overlay;
      if (overlay == null) return;

      final isDark = AppColors.isDark(context);
      final bgColor = isError
          ? AppColors.expense
          : (isDark ? const Color(0xFF222634) : const Color(0xFF1E293B));
      const textColor = Colors.white;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) {
          final bottomPadding = MediaQuery.of(ctx).padding.bottom;
          return _AppToastWidget(
            message: message,
            icon: icon,
            bgColor: bgColor,
            textColor: textColor,
            isDark: isDark,
            bottomMargin: bottomMargin + bottomPadding,
            duration: duration,
            onDismiss: () {
              if (_activeEntry == entry) {
                _activeEntry?.remove();
                _activeEntry = null;
              }
            },
          );
        },
      );

      _activeEntry = entry;
      overlay.insert(entry);
    } catch (_) {}
  }
}

class _AppToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color bgColor;
  final Color textColor;
  final bool isDark;
  final double bottomMargin;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AppToastWidget({
    required this.message,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.isDark,
    required this.bottomMargin,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();

    _hideTimer = Timer(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.bottomMargin,
      left: 20,
      right: 20,
      child: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: () {
                  _hideTimer?.cancel();
                  _controller.reverse().then((_) {
                    if (mounted) widget.onDismiss();
                  });
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.bgColor.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: widget.isDark ? 0.14 : 0.08,
                      ),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.textColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
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
}
