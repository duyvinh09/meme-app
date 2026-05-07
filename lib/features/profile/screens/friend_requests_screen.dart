import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  int selectedTab = 0; // 0 = received, 1 = sent

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().user?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('Không có người dùng'),
        ),
      );
    }

    final repo = context.read<UserRepository>();

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: repo.streamFriendRequests(uid),
          builder: (context, receivedSnapshot) {
            final receivedRequests = receivedSnapshot.data ?? [];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: repo.streamSentFriendRequests(uid),
              builder: (context, sentSnapshot) {
                final sentRequests = sentSnapshot.data ?? [];

                final currentList =
                selectedTab == 0 ? receivedRequests : sentRequests;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.pagePadding,
                        12,
                        AppSizes.pagePadding,
                        0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusXLarge,
                          ),
                          border: Border.all(
                            color: AppColors.border(context),
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 58,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _RoundIconButton(
                                      icon: Icons.close_rounded,
                                      onTap: () => Navigator.pop(context),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Yêu cầu kết bạn',
                                      style: AppTextStyles.pageTitle(context)
                                          .copyWith(
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _RoundIconButton(
                                      icon: Icons.refresh_rounded,
                                      iconColor: AppColors.primaryBlue,
                                      onTap: () {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              height: 60,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.border(context),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _RequestTabButton(
                                      icon: Icons.mail_rounded,
                                      label: 'Đã nhận',
                                      count: receivedRequests.length,
                                      selected: selectedTab == 0,
                                      onTap: () {
                                        setState(() {
                                          selectedTab = 0;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _RequestTabButton(
                                      icon: Icons.send_rounded,
                                      label: 'Đã gửi',
                                      count: sentRequests.length,
                                      selected: selectedTab == 1,
                                      onTap: () {
                                        setState(() {
                                          selectedTab = 1;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: currentList.isEmpty
                          ? _EmptyRequestState(
                        isReceivedTab: selectedTab == 0,
                      )
                          : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.pagePadding,
                          18,
                          AppSizes.pagePadding,
                          24,
                        ),
                        itemCount: currentList.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = currentList[index];

                          if (selectedTab == 0) {
                            return _ReceivedRequestCard(
                              item: item,
                              onReject: () async {
                                await repo.rejectFriendRequest(
                                  myUid: uid,
                                  fromUid: item['fromUid'],
                                );
                              },
                              onAccept: () async {
                                await repo.acceptFriendRequest(
                                  myUid: uid,
                                  requestData: item,
                                );
                              },
                            );
                          }

                          return _SentRequestTile(item: item);
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

class _ReceivedRequestCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  const _ReceivedRequestCard({
    required this.item,
    required this.onReject,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = (item['fromAvatarUrl'] ?? '').toString();
    final name = (item['fromName'] ?? '').toString().trim();
    final username = (item['fromUsername'] ?? '').toString().trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surface(context),
                  backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Icon(
                    Icons.person,
                    color: AppColors.textPrimary(context),
                  )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Người dùng' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sectionTitle(context).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary(context),
                        backgroundColor: AppColors.surface(context),
                        side: BorderSide(
                          color: AppColors.innerBorder(context),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Từ chối',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Chấp nhận',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SentRequestTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _SentRequestTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = (item['toAvatarUrl'] ?? '').toString();
    final name = (item['toName'] ?? '').toString().trim();
    final username = (item['toUsername'] ?? '').toString().trim();

    const pendingColor = Color(0xFFFFA23D);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.surface(context),
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          )
              : null,
        ),
        title: Text(
          name.isEmpty ? 'Người dùng' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sectionTitle(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Yêu cầu gửi đến @$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: 14,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: pendingColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: pendingColor,
              ),
              SizedBox(width: 8),
              Text(
                'Đang chờ',
                style: TextStyle(
                  color: pendingColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _RequestTabButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? AppColors.textPrimary(context)
        : AppColors.textSecondary(context);

    final badgeBg = selected
        ? AppColors.primaryBlue
        : AppColors.textSecondary(context).withOpacity(0.35);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.card(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: textColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface(context),
          border: Border.all(
            color: AppColors.innerBorder(context),
          ),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.textPrimary(context),
          size: 28,
        ),
      ),
    );
  }
}

class _EmptyRequestState extends StatelessWidget {
  final bool isReceivedTab;

  const _EmptyRequestState({
    required this.isReceivedTab,
  });

  @override
  Widget build(BuildContext context) {
    final title = isReceivedTab ? 'Không có yêu cầu' : 'Chưa gửi lời mời nào';
    final desc = isReceivedTab
        ? 'Khi người dùng Meme khác gửi yêu cầu kết bạn cho bạn, chúng sẽ xuất hiện ở đây'
        : 'Những lời mời kết bạn bạn đã gửi sẽ hiển thị ở đây';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface(context),
              ),
              child: Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.card(context),
                    border: Border.all(
                      color: AppColors.border(context),
                    ),
                  ),
                  child: Icon(
                    isReceivedTab
                        ? Icons.mail_outline_rounded
                        : Icons.send_rounded,
                    size: 40,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle(context).copyWith(
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}