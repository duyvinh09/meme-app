import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  Future<void> _openAddFriendScreen(BuildContext context) async {
    final uid = context.read<AuthController>().user?.uid;
    final repo = context.read<UserRepository>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFriendScreen(
          myUid: uid,
          repo: repo,
        ),
      ),
    );
  }

  Future<void> _confirmRemoveFriend({
    required BuildContext context,
    required String myUid,
    required String friendUid,
    required String friendName,
  }) async {
    final repo = context.read<UserRepository>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.deleteFriendQuestion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.deleteFriendWarning(friendName),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.deleteFriendGroupsNote,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.delete),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await repo.removeFriend(
      myUid: myUid,
      friendUid: friendUid,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: AppDurations.snackBar,
        content: Text(context.l10n.friendDeleted(friendName)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().user?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(context.l10n.user),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: context.read<UserRepository>().streamFriends(uid),
          builder: (context, snapshot) {
            final friends = snapshot.data ?? [];
            final isEmpty = friends.isEmpty;

            return StreamBuilder<int>(
              stream: context
                  .read<UserRepository>()
                  .streamPendingFriendRequestCount(uid),
              builder: (context, badgeSnapshot) {
                final pendingCount = badgeSnapshot.data ?? 0;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.pagePadding,
                        12,
                        AppSizes.pagePadding,
                        0,
                      ),
                      child: Row(
                        children: [
                          _TopCircleButton(
                            icon: Icons.arrow_back_ios_new,
                            onTap: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppColors.border(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                _TopSmallButton(
                                  icon: Icons.mail_outline,
                                  badgeCount: pendingCount,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RouteNames.friendRequests,
                                    );
                                  },
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: AppColors.border(context),
                                ),
                                _TopSmallButton(
                                  icon: Icons.add,
                                  backgroundColor: AppColors.primaryBlue,
                                  iconColor: Colors.white,
                                  onTap: () => _openAddFriendScreen(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.friendsTitle,
                          style: AppTextStyles.pageTitle(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: isEmpty
                          ? _EmptyFriendsView(
                        onAddFriend: () => _openAddFriendScreen(context),
                      )
                          : ListView.separated(
                        cacheExtent: 800,
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.pagePadding,
                          24,
                          AppSizes.pagePadding,
                          24,
                        ),
                        itemCount: friends.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = friends[index];

                          final friendUid =
                          (item['uid'] ?? '').toString();
                          final friendName =
                          (item['name'] ?? '').toString();
                          final friendUsername =
                          (item['username'] ?? '').toString();
                          final avatarUrl =
                          (item['avatarUrl'] ?? '').toString();

                          return _FriendTile(
                            friendName: friendName,
                            friendUsername: friendUsername,
                            avatarUrl: avatarUrl,
                            onRemove: () {
                              _confirmRemoveFriend(
                                context: context,
                                myUid: uid,
                                friendUid: friendUid,
                                friendName: friendName.isEmpty
                                    ? 'Người dùng'
                                    : friendName,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String friendName;
  final String friendUsername;
  final String avatarUrl;
  final VoidCallback onRemove;

  const _FriendTile({
    required this.friendName,
    required this.friendUsername,
    required this.avatarUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.surface(context),
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? Icon(
            Icons.person_rounded,
            color: AppColors.textSecondary(context),
          )
              : null,
        ),
        title: Text(
          friendName.isEmpty ? context.l10n.user : friendName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          friendUsername.isEmpty ? '' : '@$friendUsername',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context),
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.card(context),
          onSelected: (value) {
            if (value == 'remove') {
              onRemove();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'remove',
              child: Text(context.l10n.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFriendsView extends StatelessWidget {
  final VoidCallback onAddFriend;

  const _EmptyFriendsView({
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.18),
              ),
              child: const Icon(
                Icons.group_outlined,
                size: 56,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.l10n.noFriends,
              style: AppTextStyles.pageTitle(context).copyWith(
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.noFriendsSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 210,
              height: 58,
              child: FilledButton.icon(
                onPressed: onAddFriend,
                icon: const Icon(Icons.add),
                label: Text(
                  context.l10n.addFriend,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSizes.radiusMedium,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card(context),
          border: Border.all(
            color: AppColors.border(context),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary(context),
        ),
      ),
    );
  }
}

class _TopSmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final int badgeCount;

  const _TopSmallButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 54,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 52,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.textPrimary(context),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: AppColors.card(context),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}