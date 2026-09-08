import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/routes/route_names.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../home/screens/moment_viewer_screen.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../capture/screens/camera_screen.dart';
import 'edit_group_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const GroupDetailScreen({
    super.key,
    required this.groupData,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '');

    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }

    return AppColors.primaryBlue;
  }

  String _formatCreatedAt(BuildContext context, dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return context.l10n.unknown;
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }


  String _cachedMemberIdsKey = '';
  Future<List<Map<String, dynamic>>>? _cachedMembersFuture;

  Future<List<Map<String, dynamic>>> _getMembersFuture(List<String> memberIds) {
    final sortedKey = (List<String>.from(memberIds)..sort()).join(',');
    if (_cachedMembersFuture == null || _cachedMemberIdsKey != sortedKey) {
      _cachedMemberIdsKey = sortedKey;
      _cachedMembersFuture = _loadMembersByIds(memberIds);
    }
    return _cachedMembersFuture!;
  }

  Future<List<Map<String, dynamic>>> _loadMembersByIds(
    List<String> memberIds,
  ) async {
    final repo = context.read<UserRepository>();
    final validIds = memberIds
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final results = await Future.wait(
      validIds.map((uid) async {
        try {
          final user = await repo.getUserProfile(uid);
          if (user != null) {
            return {
              'uid': user.uid,
              'name': user.name,
              'username': user.username,
              'email': user.email,
              'avatarUrl': user.avatarUrl,
            };
          }
        } catch (_) {}

        return {
          'uid': uid,
          'name': 'Thành viên',
          'username': '',
          'email': '',
          'avatarUrl': '',
        };
      }),
    );

    return results;
  }



  @override
  Widget build(BuildContext context) {
    final initialGroupId = (widget.groupData['id'] ?? widget.groupData['groupId'] ?? '').toString();
    final myUid = context.read<AuthController>().user?.uid;
    final currency = context.watch<ProfileController>().currency;

    if (initialGroupId.isEmpty || myUid == null) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: Center(
          child: Text(
            context.l10n.groupNotFound,
            style: AppTextStyles.body(context),
          ),
        ),
      );
    }

    String money(double value) {
      return AppCurrencyFormatter.formatFromVnd(
        amountVnd: value,
        currency: currency,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(myUid)
              .collection('groups')
              .doc(initialGroupId)
              .snapshots(),
          builder: (streamContext, snapshot) {
            final latestData = snapshot.data?.data();

            final groupData = latestData == null
                ? widget.groupData
                : {
                    ...widget.groupData,
                    ...latestData,
                    'id': initialGroupId,
                  };

            final groupName = (groupData['name'] ?? context.l10n.group).toString();
            final colorHex = (groupData['color'] ?? '#79AFFF').toString();
            final createdAt = groupData['createdAt'];

            final memberIds = (groupData['memberIds'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];

            final memberCount = _toDouble(
              groupData['memberCount'] ?? memberIds.length,
            ).toInt();

            final goalAmount = _toDouble(groupData['goalAmount']);
            final currentAmount = _toDouble(groupData['currentAmount']);
            final spentAmount = _toDouble(groupData['spentAmount']);
            final remainingBalance = currentAmount - spentAmount;

            final memberContributions = Map<String, dynamic>.from(
              groupData['memberContributions'] ?? {},
            );
            final memberSpent = Map<String, dynamic>.from(
              groupData['memberSpent'] ?? {},
            );

            final progress = goalAmount <= 0
                ? 0.0
                : (currentAmount / goalAmount).clamp(0.0, 1.0).toDouble();

            final ownerUid = (groupData['ownerUid'] ?? '').toString();
            final groupId = (groupData['id'] ?? '').toString();
            final isOwner = myUid == ownerUid;

            final groupColor = _parseHexColor(colorHex);

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _getMembersFuture(memberIds),
              builder: (futureContext, membersSnapshot) {
                final isLoadingMembers =
                    membersSnapshot.connectionState == ConnectionState.waiting;

                final members = membersSnapshot.data ?? [];

                return RefreshIndicator(
                  color: groupColor,
                  onRefresh: () async {
                    if (mounted) {
                      setState(() {
                        _cachedMemberIdsKey = '';
                        _cachedMembersFuture = null;
                      });
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    12,
                    AppSizes.pagePadding,
                    28,
                  ),
                  children: [
                    Row(
                      children: [
                        _TopCircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            context.l10n.groupDetails,
                            style: AppTextStyles.pageTitle(context),
                          ),
                        ),
                        _TopCircleButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteNames.groupChatConversation,
                            arguments: {
                              'groupId': groupId,
                              'groupName': groupName,
                              'groupColor': colorHex,
                              'memberUids': memberIds,
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _GroupHeroCard(
                      groupName: groupName,
                      memberCount: memberCount,
                      groupColor: groupColor,
                      createdAtText: _formatCreatedAt(context, createdAt),
                      isOwner: isOwner,
                      onOpenChat: () => Navigator.pushNamed(
                        context,
                        RouteNames.groupChatConversation,
                        arguments: {
                          'groupId': groupId,
                          'groupName': groupName,
                          'groupColor': colorHex,
                          'memberUids': memberIds,
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    _GoalProgressCard(
                      groupColor: groupColor,
                      currentAmount: currentAmount,
                      currentAmountText: money(currentAmount),
                      spentAmount: spentAmount,
                      spentAmountText: money(spentAmount),
                      remainingBalance: remainingBalance,
                      remainingBalanceText: money(remainingBalance),
                      goalAmountText: money(goalAmount),
                      progress: progress,
                      onAddContribution: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CameraScreen(
                            initialType: 'expense',
                            initialPrivacy: 'group',
                            initialGroupId: groupId,
                            initialGroupName: groupName,
                            initialGroupMemberIds: memberIds,
                            lockType: true,
                            lockPrivacy: true,
                            isGroupContribution: true,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _GroupExpenseHistorySection(
                      groupId: groupId,
                      groupColor: groupColor,
                      currency: currency,
                      members: members,
                      money: money,
                      myUid: myUid,
                    ),

                    const SizedBox(height: 18),

                    _MembersContributionCard(
                      members: members,
                      isLoadingMembers: isLoadingMembers,
                      goalAmount: goalAmount,
                      memberContributions: memberContributions,
                      memberSpent: memberSpent,
                      groupColor: groupColor,
                      money: money,
                      toDouble: _toDouble,
                    ),

                    const SizedBox(height: 18),

                    _GroupOptionsCard(
                      isOwner: isOwner,
                      groupColor: groupColor,
                      onEdit: () async {
                        final changed = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditGroupScreen(
                              groupData: groupData,
                            ),
                          ),
                        );

                        if (changed == true && mounted) {
                          setState(() {
                            _cachedMemberIdsKey = '';
                            _cachedMembersFuture = null;
                          });
                        }
                      },
                      onDeleteOrLeave: () async {
                        if (groupId.isEmpty) return;

                        final messenger = ScaffoldMessenger.of(context);
                        final l10n = context.l10n;
                        final repo = context.read<UserRepository>();
                        final navigator = Navigator.of(context);

                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: Text(
                              isOwner ? l10n.deleteGroup : l10n.leaveGroup,
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  isOwner
                                      ? l10n.deleteGroupConfirmation
                                      : l10n.leaveGroupConfirmation,
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx, false),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(l10n.cancel),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(48),
                                          backgroundColor: AppColors.expense,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx, true),
                                        child: Text(
                                          isOwner
                                              ? l10n.deleteGroup
                                              : l10n.leaveGroup,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );

                        if (ok != true) return;

                        try {
                          if (isOwner) {
                            await repo.deleteGroup(
                              myUid: myUid,
                              groupId: groupId,
                            );
                          } else {
                            await repo.leaveGroup(
                              myUid: myUid,
                              groupId: groupId,
                            );
                          }

                          if (!mounted) return;

                          messenger.showSnackBar(
                            SnackBar(
                              duration: AppDurations.snackBar,
                              content: Text(
                                isOwner ? l10n.groupDeleted : l10n.youLeftGroup,
                              ),
                            ),
                          );

                          navigator.pop(true);
                        } catch (e) {
                          if (!mounted) return;

                          messenger.showSnackBar(
                            SnackBar(
                              duration: AppDurations.snackBar,
                              content: Text(
                                isOwner
                                    ? l10n.cannotDeleteGroup(e.toString())
                                    : l10n.cannotLeaveGroup(e.toString()),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GroupHeroCard extends StatelessWidget {
  final String groupName;
  final int memberCount;
  final Color groupColor;
  final String createdAtText;
  final bool isOwner;
  final VoidCallback? onOpenChat;

  const _GroupHeroCard({
    required this.groupName,
    required this.memberCount,
    required this.groupColor,
    required this.createdAtText,
    required this.isOwner,
    this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: groupColor.withValues(alpha: 0.18),
            ),
            child: Icon(
              Icons.groups_2_rounded,
              color: groupColor,
              size: 46,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            groupName,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle(context).copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.membersCount(memberCount),
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isOwner) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.20),
                ),
              ),
              child: Text(
                context.l10n.groupOwner,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _InfoChip(
                icon: Icons.palette_outlined,
                text: context.l10n.groupColor,
                color: groupColor,
              ),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                text: createdAtText,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          if (onOpenChat != null) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: onOpenChat,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: groupColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      color: groupColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.groupChatOpen,
                      style: TextStyle(
                        color: groupColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final Color groupColor;
  final double currentAmount;
  final String currentAmountText;
  final double spentAmount;
  final String spentAmountText;
  final double remainingBalance;
  final String remainingBalanceText;
  final String goalAmountText;
  final double progress;
  final VoidCallback onAddContribution;

  const _GoalProgressCard({
    required this.groupColor,
    required this.currentAmount,
    required this.currentAmountText,
    required this.spentAmount,
    required this.spentAmountText,
    required this.remainingBalance,
    required this.remainingBalanceText,
    required this.goalAmountText,
    required this.progress,
    required this.onAddContribution,
  });

  @override
  Widget build(BuildContext context) {
    final isSurplus = remainingBalance >= 0;
    final balanceStatusColor = isSurplus ? AppColors.income : AppColors.expense;

    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: groupColor.withValues(alpha: 0.16),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: groupColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.groupFinancialOverview,
                      style: AppTextStyles.sectionTitle(context).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.groupFundBalanceAndProgress,
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: balanceStatusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: balanceStatusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSurplus
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: balanceStatusColor,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSurplus ? context.l10n.groupFundSurplus : context.l10n.groupFundDeficit,
                      style: TextStyle(
                        color: balanceStatusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            context.l10n.groupFundRemaining,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  remainingBalanceText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle(context).copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isSurplus
                        ? AppColors.textPrimary(context)
                        : AppColors.expense,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.innerBorder(context),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            size: 14,
                            color: AppColors.income,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.groupTotalContributed,
                            style: AppTextStyles.caption(context).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currentAmountText,
                          style: TextStyle(
                            color: AppColors.income,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.innerBorder(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 14,
                            color: spentAmount > 0
                                ? AppColors.expense
                                : AppColors.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.groupTotalSpent,
                            style: AppTextStyles.caption(context).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          spentAmountText,
                          style: TextStyle(
                            color: spentAmount > 0
                                ? AppColors.expense
                                : AppColors.textSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.innerBorder(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 14,
                            color: groupColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.groupGoal,
                            style: AppTextStyles.caption(context).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          goalAmountText,
                          style: TextStyle(
                            color: groupColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.groupGoalProgress,
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                context.l10n.reachedPercentage((progress * 100).round()),
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: groupColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.innerBorder(context),
              valueColor: AlwaysStoppedAnimation<Color>(groupColor),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddContribution,
              icon: const Icon(Icons.add_card_rounded, size: 18),
              label: Text(context.l10n.addContribution),
              style: FilledButton.styleFrom(
                backgroundColor: groupColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupExpenseHistorySection extends StatelessWidget {
  final String groupId;
  final Color groupColor;
  final String currency;
  final List<Map<String, dynamic>> members;
  final String Function(double value) money;
  final String myUid;

  const _GroupExpenseHistorySection({
    required this.groupId,
    required this.groupColor,
    required this.currency,
    required this.members,
    required this.money,
    required this.myUid,
  });

  String _formatDateTime(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    if (locale == 'vi') {
      return '$hh:$mm • $d/$m/$y';
    } else {
      return '$d/$m/$y • $hh:$mm';
    }
  }

  Map<String, dynamic>? _findMember(String uid) {
    for (final m in members) {
      if ((m['uid'] ?? '').toString() == uid) {
        return m;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final txRepo = context.read<TransactionRepository>();

    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.expense.withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.expense,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.groupExpenseHistory,
                  style: AppTextStyles.sectionTitle(context).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<TransactionModel>>(
            stream: txRepo.streamGroupTransactions(groupId),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final allTransactions = snapshot.data ?? [];
              // Lọc chỉ lấy các khoản thành viên thực sự đã chi tiêu từ quỹ nhóm
              final transactions = allTransactions.where((tx) =>
                  tx.isGroupExpense ||
                  (tx.privacy == 'group' &&
                      tx.type == 'expense' &&
                      !tx.isGroupContribution &&
                      tx.category != 'Quỹ nhóm' &&
                      tx.category != 'Group Fund')
              ).toList();
              transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (transactions.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.innerBorder(context),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 40,
                        color: AppColors.textSecondary(context).withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.groupNoExpensesYet,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.groupNoExpensesDesc,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(context).copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: transactions.map((tx) {
                  final isMe = tx.userId == myUid;
                  final spender = _findMember(tx.userId);
                  final spenderName = isMe
                      ? context.l10n.you
                      : (spender != null
                          ? (spender['name'] ?? spender['username'] ?? context.l10n.member).toString()
                          : context.l10n.member);
                  final spenderAvatar = (spender?['avatarUrl'] ?? '').toString();

                  final imgUrl = tx.imageUrl.isNotEmpty
                      ? tx.imageUrl
                      : (tx.thumbnailUrl.isNotEmpty
                          ? tx.thumbnailUrl
                          : tx.mediaUrl);

                  final hasImage = imgUrl.isNotEmpty;

                  final categoryDisplay = tx.category.isNotEmpty
                      ? BudgetNameLocalizer.display(context, tx.category)
                      : context.l10n.groupExpense;

                  final purpose = tx.caption.trim().isNotEmpty
                      ? tx.caption.trim()
                      : (tx.note.trim().isNotEmpty ? tx.note.trim() : '');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.innerBorder(context),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MomentViewerScreen(
                              transactions: [tx],
                              initialIndex: 0,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: groupColor.withValues(alpha: 0.12),
                                ),
                                child: hasImage
                                    ? Image.network(
                                        imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.receipt_rounded,
                                          color: groupColor,
                                        ),
                                      )
                                    : Icon(
                                        Icons.receipt_rounded,
                                        color: groupColor,
                                        size: 24,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tiêu những gì: Danh mục đã địa phương hoá
                                  Text(
                                    categoryDisplay,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body(context).copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  // Tiêu về việc gì: Lý do / caption chi tiêu
                                  if (purpose.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      purpose,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption(context).copyWith(
                                        fontSize: 12,
                                        color: AppColors.textPrimary(context).withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  // Ai tiêu & Tiêu lúc nào
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 8,
                                        backgroundColor: AppColors.card(context),
                                        backgroundImage: spenderAvatar.isNotEmpty
                                            ? NetworkImage(spenderAvatar)
                                            : null,
                                        child: spenderAvatar.isEmpty
                                            ? const Icon(Icons.person, size: 9)
                                            : null,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          '$spenderName • ${_formatDateTime(context, tx.createdAt)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.caption(context).copyWith(
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '-${money(tx.amount)}',
                                  style: const TextStyle(
                                    color: AppColors.expense,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MembersContributionCard extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final bool isLoadingMembers;
  final double goalAmount;
  final Map<String, dynamic> memberContributions;
  final Map<String, dynamic> memberSpent;
  final Color groupColor;
  final String Function(double value) money;
  final double Function(dynamic value) toDouble;

  const _MembersContributionCard({
    required this.members,
    required this.isLoadingMembers,
    required this.goalAmount,
    required this.memberContributions,
    required this.memberSpent,
    required this.groupColor,
    required this.money,
    required this.toDouble,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.contributingMembers,
            style: AppTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: 14),
          if (isLoadingMembers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                context.l10n.noMembersYet,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  fontSize: 15,
                ),
              ),
            )
          else
            ...members.map((member) {
              final memberUid = (member['uid'] ?? '').toString();

              final paidAmount = toDouble(
                memberContributions[memberUid],
              );
              final spentAmount = toDouble(
                memberSpent[memberUid],
              );

              final paidProgress = goalAmount <= 0
                  ? 0.0
                  : (paidAmount / goalAmount).clamp(0.0, 1.0).toDouble();

              final avatarUrl = (member['avatarUrl'] ?? '').toString();
              final username = (member['username'] ?? '').toString();
              final name = (member['name'] ?? context.l10n.user).toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.innerBorder(context),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.card(context),
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            color: AppColors.textSecondary(context),
                          )
                        : null,
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (username.isNotEmpty)
                        Text(
                          '@$username',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context),
                        ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        child: LinearProgressIndicator(
                          value: paidProgress,
                          minHeight: 5,
                          backgroundColor: AppColors.innerBorder(context),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            groupColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: groupColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${context.l10n.groupTotalContributed}: ${money(paidAmount)}',
                              style: TextStyle(
                                color: groupColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (spentAmount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${context.l10n.groupTotalSpent}: ${money(spentAmount)}',
                                style: const TextStyle(
                                  color: AppColors.expense,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _GroupOptionsCard extends StatelessWidget {
  final bool isOwner;
  final Color groupColor;
  final VoidCallback onEdit;
  final VoidCallback onDeleteOrLeave;

  const _GroupOptionsCard({
    required this.isOwner,
    required this.groupColor,
    required this.onEdit,
    required this.onDeleteOrLeave,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.groupOptions,
            style: AppTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: 14),
          _ActionTile(
            icon: Icons.edit_outlined,
            title: context.l10n.editGroup,
            subtitle: context.l10n.editGroupSubtitle,
            color: AppColors.primaryBlue,
            onTap: onEdit,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: isOwner ? Icons.delete_outline_rounded : Icons.exit_to_app_rounded,
            title: isOwner ? context.l10n.deleteGroup : context.l10n.leaveGroup,
            subtitle: isOwner
                ? context.l10n.deleteGroupSubtitle
                : context.l10n.leaveGroupSubtitle,
            color: AppColors.expense,
            onTap: onDeleteOrLeave,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionCard({
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: child,
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
        width: 48,
        height: 48,
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
          size: 20,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.innerBorder(context),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.16),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(context).copyWith(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}