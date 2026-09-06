import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../data/models/post_reaction_model.dart';
import '../../../data/models/post_view_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../profile/widgets/avatar_with_frame.dart';

class PostActivityBottomSheet extends StatelessWidget {
  final TransactionModel transaction;
  final bool isDark;

  const PostActivityBottomSheet({
    super.key,
    required this.transaction,
    this.isDark = true,
  });

  static void show(BuildContext context, TransactionModel transaction) {
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PostActivityBottomSheet(
        transaction: transaction,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatCtrl = context.read<ChatController>();
    final bgColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return StreamBuilder<List<PostViewModel>>(
      stream: chatCtrl.postViewsStream(transaction.id),
      builder: (context, viewsSnapshot) {
        return StreamBuilder<List<PostReactionModel>>(
          stream: chatCtrl.postReactionsStream(transaction.id),
          builder: (context, reactionsSnapshot) {
            final views = viewsSnapshot.data ?? [];
            final reactions = reactionsSnapshot.data ?? [];

            // Group reactions by userId
            final Map<String, List<String>> userReactions = {};
            for (final r in reactions) {
              userReactions.putIfAbsent(r.userId, () => []).add(r.emoji);
            }

            // Merge unique users who either viewed or reacted
            final Map<String, _ActivityUserItem> userMap = {};

            for (final v in views) {
              userMap[v.userId] = _ActivityUserItem(
                userId: v.userId,
                userName: v.userName,
                userAvatar: v.userAvatar,
                userFrame: v.userFrame,
                viewedAt: v.viewedAt,
                reactions: userReactions[v.userId] ?? [],
              );
            }

            for (final r in reactions) {
              if (!userMap.containsKey(r.userId)) {
                userMap[r.userId] = _ActivityUserItem(
                  userId: r.userId,
                  userName: r.userName,
                  userAvatar: r.userAvatar,
                  userFrame: 'default',
                  viewedAt: r.createdAt,
                  reactions: userReactions[r.userId] ?? [r.emoji],
                );
              }
            }

            final activityList = userMap.values.toList()
              ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    // Drag Handle
                    Container(
                      width: 38,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header
                    Text(
                      context.l10n.postActivityTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),

                    // User List
                    if (activityList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 38,
                              color: subtextColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.l10n.noPostActivityYet,
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          itemCount: activityList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _ActivityUserTile(
                              item: activityList[index],
                              isDark: isDark,
                              textColor: textColor,
                              subtextColor: subtextColor,
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
      },
    );
  }
}

class _ActivityUserTile extends StatelessWidget {
  final _ActivityUserItem item;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;

  const _ActivityUserTile({
    required this.item,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
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
    final userRepo = context.read<UserRepository>();
    final myUid = context.read<AuthController>().user?.uid;

    return StreamBuilder<UserModel?>(
      stream: userRepo.streamUserProfile(item.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isMe = item.userId == myUid;

        String displayName = '';
        if (user != null && user.name.trim().isNotEmpty) {
          displayName = user.name.trim();
        } else if (user != null && user.username.trim().isNotEmpty) {
          displayName = user.username.trim();
        } else if (item.userName.trim().isNotEmpty) {
          displayName = item.userName.trim();
        } else if (isMe) {
          displayName = 'Bạn';
        } else {
          displayName = context.l10n.someone;
        }

        final avatarUrl = (user != null && user.avatarUrl.isNotEmpty)
            ? user.avatarUrl
            : item.userAvatar;
        final frameId = (user != null && user.avatarFrame.isNotEmpty)
            ? user.avatarFrame
            : item.userFrame;

        final hasAvatar = avatarUrl.isNotEmpty;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(
              AppSizes.radiusMedium,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              if (hasAvatar)
                AvatarWithFrame(
                  avatarUrl: avatarUrl,
                  frameId: frameId,
                  size: 44,
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white24
                          : Colors.black12,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(displayName),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1F2937),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 14),

              // Name & Viewed status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          context.l10n.postViewedStatus,
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '✨',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Reactions (Emojis sent by this friend)
              if (item.reactions.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: item.reactions
                      .toSet()
                      .take(3)
                      .map((emoji) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityUserItem {
  final String userId;
  final String userName;
  final String userAvatar;
  final String userFrame;
  final DateTime viewedAt;
  final List<String> reactions;

  _ActivityUserItem({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userFrame,
    required this.viewedAt,
    required this.reactions,
  });
}
