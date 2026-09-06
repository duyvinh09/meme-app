import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../routes/route_names.dart';
import '../services/in_app_notification_service.dart';
import '../../features/feed/controllers/feed_controller.dart';
import '../../features/profile/widgets/avatar_with_frame.dart';

class InAppNotificationHost extends StatefulWidget {
  final Widget child;

  const InAppNotificationHost({
    super.key,
    required this.child,
  });

  @override
  State<InAppNotificationHost> createState() => _InAppNotificationHostState();
}

class _InAppNotificationHostState extends State<InAppNotificationHost>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  InAppNotificationItem? _activeItem;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    InAppNotificationService.instance.addListener(_handleNotificationChange);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    InAppNotificationService.instance.removeListener(_handleNotificationChange);
    _animController.dispose();
    super.dispose();
  }

  void _handleNotificationChange() {
    final newItem = InAppNotificationService.instance.currentNotification;
    if (newItem != null) {
      _autoDismissTimer?.cancel();
      setState(() {
        _activeItem = newItem;
      });

      HapticFeedback.mediumImpact();
      _animController.forward(from: 0.0);

      _autoDismissTimer = Timer(const Duration(seconds: 4, milliseconds: 500), () {
        _dismiss();
      });
    } else {
      _dismiss();
    }
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (_animController.isAnimating || _animController.value > 0) {
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _activeItem = null;
          });
          InAppNotificationService.instance.dismiss();
        }
      });
    }
  }

  void _handleTap() {
    final item = _activeItem;
    _dismiss();

    if (item != null) {
      HapticFeedback.lightImpact();
      if (item.type == 'friend_request') {
        AppRoutes.navigatorKey.currentState?.pushNamed(
          RouteNames.friendRequests,
        );
      } else if (item.type == 'mention') {
        if (item.postId != null && item.postId!.isNotEmpty) {
          final navContext = AppRoutes.navigatorKey.currentContext;
          if (navContext != null) {
            navContext.read<FeedController>().setTargetPostId(item.postId);
          }
        }
        AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          RouteNames.mainShell,
          (route) => false,
          arguments: {
            'initialIndex': 2,
            'targetPostId': item.postId,
          },
        );
      } else if (item.isGroup || (item.groupId != null && item.groupId!.isNotEmpty)) {
        final gId = item.groupId ?? '';
        if (gId.isNotEmpty) {
          AppRoutes.navigatorKey.currentState?.pushNamed(
            RouteNames.groupChatConversation,
            arguments: {
              'groupId': gId,
              'groupName': item.groupName ?? 'Nhóm',
            },
          );
        }
      } else {
        AppRoutes.navigatorKey.currentState?.pushNamed(
          RouteNames.chatConversation,
          arguments: {
            'friend': item.sender,
          },
        );
      }
    }
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,

        if (_activeItem != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Dismissible(
                      key: Key('in_app_notif_${_activeItem!.id}'),
                      direction: DismissDirection.up,
                      onDismissed: (_) => _dismiss(),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _handleTap,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2028).withValues(alpha: 0.96)
                                  : Colors.white.withValues(alpha: 0.97),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.14)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.45 : 0.16,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                if (_activeItem!.sender.avatarUrl.isNotEmpty)
                                  AvatarWithFrame(
                                    avatarUrl: _activeItem!.sender.avatarUrl,
                                    frameId: _activeItem!.sender.avatarFrame,
                                    size: 42,
                                  )
                                else
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF374151)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getInitials(_activeItem!.sender.name),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF111827),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),

                                // Sender Name & Message preview
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _activeItem!.isGroup &&
                                                      _activeItem!.groupName != null &&
                                                      _activeItem!.groupName!.isNotEmpty
                                                  ? '${_activeItem!.sender.name.isNotEmpty ? _activeItem!.sender.name : "Thành viên"} • ${_activeItem!.groupName}'
                                                  : (_activeItem!.sender.name.isNotEmpty
                                                      ? _activeItem!.sender.name
                                                      : 'Tin nhắn mới'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF111827),
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'vừa xong',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black45,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      _buildMessageSubtitle(isDark),
                                    ],
                                  ),
                                ),

                                // Post thumbnail if replying to post
                                if (_activeItem!.postImageUrl != null &&
                                    _activeItem!.postImageUrl!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _activeItem!.postImageUrl!,
                                      width: 38,
                                      height: 38,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
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
            ),
          ),
      ],
    );
  }

  Widget _buildMessageSubtitle(bool isDark) {
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF4B5563);
    final item = _activeItem!;

    if (item.type == 'friend_request') {
      return Row(
        children: [
          const Icon(
            Icons.person_add_rounded,
            size: 14,
            color: Color(0xFF3B82F6),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Đã gửi cho bạn lời mời kết bạn! 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (item.type == 'friend_accepted') {
      return Row(
        children: [
          const Icon(
            Icons.celebration_rounded,
            size: 14,
            color: Color(0xFFFFB800),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Đã chấp nhận lời mời kết bạn! 🎉',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (item.type == 'post_reply') {
      return Row(
        children: [
          const Icon(
            Icons.reply_rounded,
            size: 14,
            color: Color(0xFFFFB800),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Đã trả lời bài viết: ${item.messageText}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subtextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (item.type == 'message_reaction') {
      return Row(
        children: [
          Text(
            item.reactionEmoji ?? '❤️',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Đã bày tỏ cảm xúc về tin nhắn của bạn',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subtextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (item.type == 'reaction') {
      return Text(
        'Đã thả cảm xúc: ${item.reactionEmoji ?? item.messageText}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: subtextColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      item.messageText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: subtextColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
