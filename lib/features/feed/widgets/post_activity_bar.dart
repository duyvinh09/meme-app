import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../data/models/post_reaction_model.dart';
import '../../../data/models/post_view_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import 'post_activity_bottom_sheet.dart';

class PostActivityBar extends StatelessWidget {
  final TransactionModel transaction;
  final bool isDark;

  const PostActivityBar({
    super.key,
    required this.transaction,
    this.isDark = true,
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
    final chatCtrl = context.read<ChatController>();

    final bgColor = isDark
        ? const Color(0xFF26262A).withValues(alpha: 0.90)
        : const Color(0xFFE5E7EB).withValues(alpha: 0.92);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);

    return StreamBuilder<List<PostViewModel>>(
      stream: chatCtrl.postViewsStream(transaction.id),
      builder: (context, viewsSnapshot) {
        return StreamBuilder<List<PostReactionModel>>(
          stream: chatCtrl.postReactionsStream(transaction.id),
          builder: (context, reactionsSnapshot) {
            final views = viewsSnapshot.data ?? [];
            final reactions = reactionsSnapshot.data ?? [];

            // Combine unique users
            final Map<String, _BarUserPreview> uniqueUsers = {};
            for (final v in views) {
              uniqueUsers[v.userId] = _BarUserPreview(
                userId: v.userId,
                userName: v.userName,
                userAvatar: v.userAvatar,
              );
            }
            for (final r in reactions) {
              uniqueUsers.putIfAbsent(
                r.userId,
                () => _BarUserPreview(
                  userId: r.userId,
                  userName: r.userName,
                  userAvatar: r.userAvatar,
                ),
              );
            }

            final userList = uniqueUsers.values.toList();
            final hasActivity = userList.isNotEmpty;

            return Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  PostActivityBottomSheet.show(context, transaction);
                },
                child: Container(
                  height: 48,
                  padding: hasActivity
                      ? const EdgeInsets.fromLTRB(16, 6, 8, 6)
                      : const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: borderColor,
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: hasActivity
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Left: Hoạt động with Material Icon
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n.postActivityTitle,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Right: Overlapping circular avatar badges
                            _buildOverlappingAvatars(userList.take(5).toList(), context),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.noPostActivityYet,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.70)
                                    : Colors.black.withValues(alpha: 0.60),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverlappingAvatars(List<_BarUserPreview> users, BuildContext context) {
    const double avatarSize = 32.0;
    const double overlap = 10.0;
    final totalWidth = avatarSize + (users.length - 1) * (avatarSize - overlap);
    final userRepo = context.read<UserRepository>();

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: List.generate(users.length, (index) {
          final preview = users[index];

          return Positioned(
            left: index * (avatarSize - overlap),
            child: StreamBuilder<UserModel?>(
              stream: userRepo.streamUserProfile(preview.userId),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final avatarUrl = (user != null && user.avatarUrl.isNotEmpty)
                    ? user.avatarUrl
                    : preview.userAvatar;
                final name = (user != null && user.name.trim().isNotEmpty)
                    ? user.name.trim()
                    : (user != null && user.username.trim().isNotEmpty)
                        ? user.username.trim()
                        : preview.userName;
                final hasAvatar = avatarUrl.isNotEmpty;

                return Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF26262A) : const Color(0xFFE5E7EB),
                      width: 2.0,
                    ),
                    color: isDark ? const Color(0xFF3F424E) : const Color(0xFFD1D5DB),
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                _getInitials(name),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _getInitials(name),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _BarUserPreview {
  final String userId;
  final String userName;
  final String userAvatar;

  _BarUserPreview({
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });
}
