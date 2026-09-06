import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/localization_extension.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/user_model.dart';

enum MessageMenuAction {
  reply,
  copy,
  unsend,
  deleteForMe,
  report,
}

class MessageActionMenuOverlay extends StatefulWidget {
  final ChatMessageModel message;
  final bool isMe;
  final UserModel friend;
  final Rect messageRect;
  final Widget messageChild;
  final ValueChanged<String> onSelectReaction;
  final ValueChanged<MessageMenuAction> onSelectAction;

  const MessageActionMenuOverlay({
    super.key,
    required this.message,
    required this.isMe,
    required this.friend,
    required this.messageRect,
    required this.messageChild,
    required this.onSelectReaction,
    required this.onSelectAction,
  });

  static Future<void> show({
    required BuildContext context,
    required ChatMessageModel message,
    required bool isMe,
    required UserModel friend,
    required GlobalKey messageKey,
    required Widget messageChild,
    required ValueChanged<String> onSelectReaction,
    required ValueChanged<MessageMenuAction> onSelectAction,
  }) {
    RenderBox? renderBox =
        messageKey.currentContext?.findRenderObject() as RenderBox?;
    renderBox ??= context.findRenderObject() as RenderBox?;

    final screenSize = MediaQuery.of(context).size;
    final Rect rect;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    } else {
      rect = Rect.fromLTWH(
        isMe ? screenSize.width - 240 : 16,
        screenSize.height / 2 - 40,
        220,
        60,
      );
    }

    HapticFeedback.mediumImpact();

    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, anim, secondaryAnim) {
          return FadeTransition(
            opacity: anim,
            child: MessageActionMenuOverlay(
              message: message,
              isMe: isMe,
              friend: friend,
              messageRect: rect,
              messageChild: messageChild,
              onSelectReaction: onSelectReaction,
              onSelectAction: onSelectAction,
            ),
          );
        },
      ),
    );
  }

  @override
  State<MessageActionMenuOverlay> createState() =>
      _MessageActionMenuOverlayState();
}

class _MessageActionMenuOverlayState extends State<MessageActionMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shiftAnimation;

  // 6 default quick reactions matching the reference UI
  static const List<String> _quickEmojis = [
    '❤️',
    '😆',
    '😮',
    '😢',
    '😡',
    '👍',
  ];

  static const List<String> _allEmojis = [
    '❤️', '😆', '😮', '😢', '😡', '👍', '👎', '🔥',
    '🤣', '🥺', '😱', '👏', '😍', '🎉', '😎', '💯',
    '👀', '💀', '😭', '🤯', '🥳', '✨', '🙏', '🥰',
    '🤩', '💩', '🤑', '🤫', '🥱', '🫶', '🚀', '💖',
    '🙈', '🤤', '😈', '💤', '🍕', '💪', '🤝', '💔',
    '😻', '🦄', '💐', '🎂', '🍻', '☕', '🎈', '⚡',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _shiftAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _openFullEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E222D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.selectReaction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: _allEmojis.length,
                    itemBuilder: (context, index) {
                      final emoji = _allEmojis[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(sheetCtx).pop();
                          Navigator.of(this.context).pop();
                          widget.onSelectReaction(emoji);
                        },
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topSafePadding = MediaQuery.of(context).padding.top;
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    final rect = widget.messageRect;
    final isMe = widget.isMe;

    const reactionPillHeight = 52.0;
    const menuWidth = 220.0;
    const gap = 10.0;
    final isText = widget.message.type == 'text' || widget.message.type.isEmpty;

    final isRecalled = widget.message.isRecalled;
    final canUnsend = widget.isMe &&
        !isRecalled &&
        DateTime.now().difference(widget.message.createdAt).inSeconds <= 15 * 60;

    // Approximate action menu height based on items
    final int actionItemCount = isRecalled
        ? 1
        : (2 +
            (isText && widget.message.text.trim().isNotEmpty ? 1 : 0) +
            (canUnsend ? 1 : 0) +
            (!isMe ? 1 : 0));
    final double menuHeight = actionItemCount * 48.0 + 8.0;

    // Calculate required upward shift if message is near the bottom
    final double requiredBottom = screenSize.height - bottomSafePadding - 16.0;
    final double idealMenuBottom = rect.bottom + gap + menuHeight;
    double targetShiftY = 0.0;

    if (idealMenuBottom > requiredBottom) {
      targetShiftY = idealMenuBottom - requiredBottom;
      // Ensure shift doesn't push reaction pill off the top
      final double maxShift = rect.top - reactionPillHeight - gap - topSafePadding - 12.0;
      if (maxShift > 0 && targetShiftY > maxShift) {
        targetShiftY = maxShift;
      }
    }

    // Reaction pill horizontal alignment
    double reactionLeft;
    if (isMe) {
      reactionLeft = (rect.right - 290).clamp(16.0, screenSize.width - 306.0);
    } else {
      reactionLeft = rect.left.clamp(16.0, screenSize.width - 306.0);
    }

    // Action menu horizontal alignment
    double menuLeft;
    if (isMe) {
      menuLeft = (rect.right - menuWidth).clamp(16.0, screenSize.width - menuWidth - 16.0);
    } else {
      menuLeft = rect.left.clamp(16.0, screenSize.width - menuWidth - 16.0);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _dismiss();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismiss,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double currentShiftY = targetShiftY * _shiftAnimation.value;
              final double currentMessageTop = rect.top - currentShiftY;
              final double currentReactionTop = currentMessageTop - reactionPillHeight - gap;
              final double currentMenuTop = currentMessageTop + rect.height + gap;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Blurred Backdrop Filter & Dark Overlay
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 18 * _fadeAnimation.value,
                        sigmaY: 18 * _fadeAnimation.value,
                      ),
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: 0.45 * _fadeAnimation.value,
                        ),
                      ),
                    ),
                  ),

                  // 2. Focused Message (Smoothly translates upward into view)
                  Positioned(
                    top: currentMessageTop,
                    left: rect.left,
                    width: rect.width,
                    height: rect.height,
                    child: IgnorePointer(
                      child: widget.messageChild,
                    ),
                  ),

                  // 3. Emoji Reactions Pill (Above Message) - only if NOT recalled
                  if (!isRecalled)
                    Positioned(
                      top: currentReactionTop,
                      left: reactionLeft,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildReactionPill(context),
                        ),
                      ),
                    ),

                  // 4. Action Context Menu (Below Message)
                  Positioned(
                    top: currentMenuTop,
                    left: menuLeft,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      alignment: isMe ? Alignment.topRight : Alignment.topLeft,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildActionMenu(
                          context,
                          isText: isText,
                          canUnsend: canUnsend,
                          isRecalled: isRecalled,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReactionPill(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF22242A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._quickEmojis.map((emoji) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                  widget.onSelectReaction(emoji);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              );
            }),

            const SizedBox(width: 4),

            // Plus (+) Button to pick any emoji
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                _openFullEmojiPicker();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(
    BuildContext context, {
    required bool isText,
    required bool canUnsend,
    required bool isRecalled,
  }) {
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF22242A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRecalled) ...[
                // If already recalled, only allow Delete for me
                _buildMenuItem(
                  icon: Icons.delete_outline_rounded,
                  title: l10n.deleteForMe,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSelectAction(MessageMenuAction.deleteForMe);
                  },
                ),
              ] else ...[
                // 1. Reply
                _buildMenuItem(
                  icon: Icons.reply_rounded,
                  title: l10n.reply,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSelectAction(MessageMenuAction.reply);
                  },
                ),

                // 2. Copy (if text message)
                if (isText && widget.message.text.trim().isNotEmpty) ...[
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.copy_rounded,
                    title: l10n.copy,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelectAction(MessageMenuAction.copy);
                    },
                  ),
                ],

                // 3. Unsend (if within 15 mins and sent by me)
                if (canUnsend) ...[
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.undo_rounded,
                    title: l10n.unsend,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelectAction(MessageMenuAction.unsend);
                    },
                  ),
                ],

                // 4. Delete for me
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.delete_outline_rounded,
                  title: l10n.deleteForMe,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSelectAction(MessageMenuAction.deleteForMe);
                  },
                ),

                // 5. Report (if received from friend)
                if (!widget.isMe) ...[
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.flag_outlined,
                    title: l10n.report,
                    isDestructive: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelectAction(MessageMenuAction.report);
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFFF4D4F) : Colors.white;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              icon,
              size: 20,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.6,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}
