import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../profile/widgets/avatar_with_frame.dart';

class TypingDotsIndicator extends StatefulWidget {
  final Color? color;
  final double dotSize;
  final double spacing;

  const TypingDotsIndicator({
    super.key,
    this.color,
    this.dotSize = 6.5,
    this.spacing = 3.5,
  });

  @override
  State<TypingDotsIndicator> createState() => _TypingDotsIndicatorState();
}

class _TypingDotsIndicatorState extends State<TypingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : const Color(0xFF6B7280));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.22;
            final progress = (_controller.value - delay) % 1.0;
            // Smooth sine wave bouncing calculation between 0.0 and 1.0
            final double bounce = (progress >= 0 && progress <= 0.5)
                ? math.sin(progress * 2 * math.pi)
                : 0.0;
            final translateY = -bounce * 4.5;
            final scale = 0.85 + (bounce * 0.25);
            final opacity = 0.45 + (bounce * 0.55);

            return Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor.withValues(alpha: opacity.clamp(0.0, 1.0)),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Message list typing bubble (shows on receiver side when friend is typing)
class ChatTypingBubble extends StatelessWidget {
  final UserModel friend;
  final bool isDark;

  const ChatTypingBubble({
    super.key,
    required this.friend,
    required this.isDark,
  });

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Friend Avatar
          if (friend.avatarUrl.isNotEmpty)
            AvatarWithFrame(
              avatarUrl: friend.avatarUrl,
              frameId: friend.avatarFrame,
              size: 28,
            )
          else
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
              child: Center(
                child: Text(
                  _getInitials(friend.name),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Receiver typing bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242526) : const Color(0xFFE4E6EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TypingDotsIndicator(
              dotSize: 7,
              spacing: 4,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Scroll-to-Bottom Button that seamlessly transforms
/// into typing dots `...` when a friend is actively typing.
class ChatScrollToBottomButton extends StatelessWidget {
  final bool isVisible;
  final bool isFriendTyping;
  final bool isDark;
  final UserModel? friend;
  final VoidCallback onTap;

  const ChatScrollToBottomButton({
    super.key,
    required this.isVisible,
    required this.isFriendTyping,
    required this.isDark,
    this.friend,
    required this.onTap,
  });

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF26262B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.10);
    final iconColor = isDark ? Colors.white : const Color(0xFF111827);

    final liveFriend = friend;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isVisible ? 1.0 : 0.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isFriendTyping ? 12 : 10,
                  vertical: isFriendTyping ? 6 : 9,
                ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isFriendTyping
                      ? const Color(0xFF0084FF).withValues(alpha: 0.50)
                      : borderColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFriendTyping
                        ? const Color(0xFF0084FF).withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.18),
                    blurRadius: isFriendTyping ? 12 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFriendTyping) ...[
                    if (liveFriend != null) ...[
                      if (liveFriend.avatarUrl.isNotEmpty)
                        AvatarWithFrame(
                          avatarUrl: liveFriend.avatarUrl,
                          frameId: liveFriend.avatarFrame,
                          size: 22,
                        )
                      else
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(liveFriend.name),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 7),
                    ],
                    const TypingDotsIndicator(
                      dotSize: 5.5,
                      spacing: 3.0,
                      color: Color(0xFF0084FF),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF0084FF),
                      size: 16,
                    ),
                  ] else ...[
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
