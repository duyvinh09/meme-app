import 'package:flutter/material.dart';
import '../../../data/models/chat_bubble_theme.dart';
import 'chat_bubble_decor_painter.dart';

class ChatBubbleDecoratedBox extends StatelessWidget {
  final ChatBubbleTheme theme;
  final Widget child;
  final bool isMe;
  final BorderRadius? customBorderRadius;
  final EdgeInsetsGeometry padding;

  const ChatBubbleDecoratedBox({
    super.key,
    required this.theme,
    required this.child,
    this.isMe = true,
    this.customBorderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        customBorderRadius ?? BorderRadius.circular(theme.borderRadius);

    return CustomPaint(
      foregroundPainter: ChatBubbleDecorPainter(
        theme: theme,
        isMe: isMe,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: theme.gradient == null ? theme.backgroundColor : null,
          gradient: theme.gradient,
          borderRadius: borderRadius,
          border: theme.borderColor != null
              ? Border.all(
                  color: theme.borderColor!,
                  width: theme.borderWidth,
                )
              : null,
          boxShadow: [
            if (theme.glowColor != null)
              BoxShadow(
                color: theme.glowColor!.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}
