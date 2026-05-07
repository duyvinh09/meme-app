import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
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

  String _formatCreatedAt(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return 'Không rõ';
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double _parseMoney(String value, String currency) {
    final cleaned = currency == 'USD'
        ? value.replaceAll(RegExp(r'[^0-9.]'), '')
        : value.replaceAll(RegExp(r'[^0-9]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  Future<List<Map<String, dynamic>>> _loadMembersByIds(
      List<String> memberIds,
      ) async {
    final repo = context.read<UserRepository>();
    final result = <Map<String, dynamic>>[];

    for (final uid in memberIds) {
      final user = await repo.getUserProfile(uid);

      if (user != null) {
        result.add({
          'uid': user.uid,
          'name': user.name,
          'username': user.username,
          'email': user.email,
          'avatarUrl': user.avatarUrl,
        });
      }
    }

    return result;
  }

  Future<void> _showAddContributionSheet({
    required BuildContext context,
    required List<Map<String, dynamic>> members,
    required String groupId,
    required String? myUid,
    required bool isOwner,
    required Color groupColor,
  }) async {
    if (myUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy người dùng hiện tại'),
        ),
      );
      return;
    }

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhóm chưa có thành viên để đóng góp'),
        ),
      );
      return;
    }

    final repo = context.read<UserRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final currency = context.read<ProfileController>().currency;

    final amountController = TextEditingController();

    final meInGroup = members.where((member) {
      return (member['uid'] ?? '').toString() == myUid;
    }).toList();

    if (!isOwner && meInGroup.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Bạn không còn thuộc nhóm này'),
        ),
      );
      return;
    }

    String selectedUid = isOwner ? (members.first['uid'] ?? '').toString() : myUid;

    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final selectedMember = members.where((member) {
              return (member['uid'] ?? '').toString() == selectedUid;
            }).toList();

            final selectedName = selectedMember.isEmpty
                ? 'Bạn'
                : (selectedMember.first['name'] ?? 'Bạn').toString();

            final selectedUsername = selectedMember.isEmpty
                ? ''
                : (selectedMember.first['username'] ?? '').toString();

            final selectedAvatar = selectedMember.isEmpty
                ? ''
                : (selectedMember.first['avatarUrl'] ?? '').toString();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary(context).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Thêm tiền đóng góp',
                    style: AppTextStyles.sectionTitle(context).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (isOwner)
                    DropdownButtonFormField<String>(
                      value: selectedUid,
                      dropdownColor: AppColors.card(context),
                      style: AppTextStyles.body(context).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Chọn thành viên',
                        labelStyle: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                        filled: true,
                        fillColor: AppColors.surface(context),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          borderSide: BorderSide(
                            color: AppColors.innerBorder(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          borderSide: BorderSide(
                            color: groupColor,
                            width: 1.4,
                          ),
                        ),
                      ),
                      items: members.map((member) {
                        final uid = (member['uid'] ?? '').toString();
                        final name = (member['name'] ?? 'Người dùng').toString();
                        final username = (member['username'] ?? '').toString();

                        return DropdownMenuItem<String>(
                          value: uid,
                          child: Text(
                            username.isEmpty ? name : '$name (@$username)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          selectedUid = value;
                        });
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: groupColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        border: Border.all(
                          color: groupColor.withOpacity(0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.surface(context),
                            backgroundImage: selectedAvatar.isNotEmpty
                                ? NetworkImage(selectedAvatar)
                                : null,
                            child: selectedAvatar.isEmpty
                                ? Icon(
                              Icons.person_rounded,
                              color: AppColors.textSecondary(context),
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bạn đang đóng góp cho',
                                  style: AppTextStyles.caption(context).copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  selectedUsername.isEmpty
                                      ? selectedName
                                      : '$selectedName (@$selectedUsername)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body(context).copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.lock_rounded,
                            color: groupColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: currency == 'VND' ? [MoneyInputFormatter()] : [],
                    cursorColor: groupColor,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Số tiền',
                      hintText: AppCurrencyFormatter.formatInputHint(currency),
                      suffixText: AppCurrencyFormatter.symbol(currency),
                      labelStyle: TextStyle(
                        color: AppColors.textSecondary(context),
                      ),
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary(context).withOpacity(0.65),
                      ),
                      suffixStyle: AppTextStyles.caption(context).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      filled: true,
                      fillColor: AppColors.surface(context),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        borderSide: BorderSide(
                          color: AppColors.innerBorder(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        borderSide: BorderSide(
                          color: groupColor,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                        final inputAmount = _parseMoney(
                          amountController.text,
                          currency,
                        );

                        if (inputAmount <= 0) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Nhập số tiền hợp lệ'),
                            ),
                          );
                          return;
                        }

                        if (!isOwner && selectedUid != myUid) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Bạn chỉ có thể thêm tiền cho chính mình',
                              ),
                            ),
                          );
                          return;
                        }

                        final amount = AppCurrencyFormatter.toVnd(
                          inputAmount: inputAmount,
                          currency: currency,
                        );

                        setSheetState(() {
                          isSaving = true;
                        });

                        try {
                          await repo.addGroupContribution(
                            groupId: groupId,
                            actorUid: myUid,
                            memberUid: selectedUid,
                            amount: amount,
                          );

                          if (!mounted) return;

                          Navigator.of(sheetContext).pop();

                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Đã thêm tiền đóng góp'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          setSheetState(() {
                            isSaving = false;
                          });

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Không thể thêm đóng góp: $e'),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: groupColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                      child: Text(
                        isSaving ? 'Đang lưu...' : 'Xác nhận',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialGroupId = (widget.groupData['id'] ?? '').toString();
    final myUid = context.read<AuthController>().user?.uid;
    final currency = context.watch<ProfileController>().currency;

    if (initialGroupId.isEmpty || myUid == null) {
      return const Scaffold(
        body: Center(
          child: Text('Không tìm thấy nhóm'),
        ),
      );
    }

    String money(double value) {
      return AppCurrencyFormatter.formatFromVnd(
        amountVnd: value,
        currency: currency,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('groups')
          .doc(initialGroupId)
          .snapshots(),
      builder: (context, snapshot) {
        final latestData = snapshot.data?.data();

        final groupData = latestData == null
            ? widget.groupData
            : {
          ...widget.groupData,
          ...latestData,
          'id': initialGroupId,
        };

        final groupName = (groupData['name'] ?? 'Nhóm').toString();
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

        final memberContributions = Map<String, dynamic>.from(
          groupData['memberContributions'] ?? {},
        );

        final progress = goalAmount <= 0
            ? 0.0
            : (currentAmount / goalAmount).clamp(0.0, 1.0).toDouble();

        final ownerUid = (groupData['ownerUid'] ?? '').toString();
        final groupId = (groupData['id'] ?? '').toString();
        final isOwner = myUid == ownerUid;

        final groupColor = _parseHexColor(colorHex);

        return Scaffold(
          backgroundColor: AppColors.background(context),
          body: SafeArea(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadMembersByIds(memberIds),
              builder: (context, membersSnapshot) {
                final isLoadingMembers =
                    membersSnapshot.connectionState == ConnectionState.waiting;

                final members = membersSnapshot.data ?? [];

                return ListView(
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
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Chi tiết nhóm',
                            style: AppTextStyles.pageTitle(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _GroupHeroCard(
                      groupName: groupName,
                      memberCount: memberCount,
                      groupColor: groupColor,
                      createdAtText: _formatCreatedAt(createdAt),
                      isOwner: isOwner,
                    ),

                    const SizedBox(height: 18),

                    _GoalProgressCard(
                      groupColor: groupColor,
                      currentAmountText: money(currentAmount),
                      goalAmountText: money(goalAmount),
                      progress: progress,
                      onAddContribution: () => _showAddContributionSheet(
                        context: context,
                        members: members,
                        groupId: groupId,
                        myUid: myUid,
                        isOwner: isOwner,
                        groupColor: groupColor,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _MembersContributionCard(
                      members: members,
                      isLoadingMembers: isLoadingMembers,
                      goalAmount: goalAmount,
                      memberContributions: memberContributions,
                      groupColor: groupColor,
                      money: money,
                      toDouble: _toDouble,
                    ),

                    const SizedBox(height: 18),

                    _GroupOptionsCard(
                      isOwner: isOwner,
                      groupColor: groupColor,
                      onEdit: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditGroupScreen(
                              groupData: groupData,
                            ),
                          ),
                        );
                      },
                      onDeleteOrLeave: () async {
                        if (groupId.isEmpty) return;

                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(
                              isOwner ? 'Xoá nhóm' : 'Rời nhóm',
                            ),
                            content: Text(
                              isOwner
                                  ? 'Bạn có chắc muốn xoá nhóm này không? Hành động này sẽ xoá nhóm khỏi tất cả thành viên.'
                                  : 'Bạn có chắc muốn rời khỏi nhóm này không?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Huỷ'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.expense,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  isOwner ? 'Xoá nhóm' : 'Rời nhóm',
                                ),
                              ),
                            ],
                          ),
                        );

                        if (ok != true) return;

                        try {
                          if (isOwner) {
                            await context.read<UserRepository>().deleteGroup(
                              myUid: myUid,
                              groupId: groupId,
                            );
                          } else {
                            await context.read<UserRepository>().leaveGroup(
                              myUid: myUid,
                              groupId: groupId,
                            );
                          }

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isOwner ? 'Đã xoá nhóm' : 'Bạn đã rời nhóm',
                              ),
                            ),
                          );

                          Navigator.pop(context, true);
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isOwner
                                    ? 'Không thể xoá nhóm: $e'
                                    : 'Không thể rời nhóm: $e',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _GroupHeroCard extends StatelessWidget {
  final String groupName;
  final int memberCount;
  final Color groupColor;
  final String createdAtText;
  final bool isOwner;

  const _GroupHeroCard({
    required this.groupName,
    required this.memberCount,
    required this.groupColor,
    required this.createdAtText,
    required this.isOwner,
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
              color: groupColor.withOpacity(0.18),
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
            '$memberCount thành viên',
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
                color: AppColors.primaryBlue.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.20),
                ),
              ),
              child: const Text(
                'Chủ nhóm',
                style: TextStyle(
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
                text: 'Màu nhóm',
                color: groupColor,
              ),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                text: createdAtText,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final Color groupColor;
  final String currentAmountText;
  final String goalAmountText;
  final double progress;
  final VoidCallback onAddContribution;

  const _GoalProgressCard({
    required this.groupColor,
    required this.currentAmountText,
    required this.goalAmountText,
    required this.progress,
    required this.onAddContribution,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: groupColor.withOpacity(0.16),
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: groupColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mục tiêu đóng góp',
                  style: AppTextStyles.sectionTitle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentAmountText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.pageTitle(context).copyWith(
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'trên $goalAmountText',
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.innerBorder(context),
              valueColor: AlwaysStoppedAnimation<Color>(groupColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Đã đạt ${(progress * 100).round()}%',
            style: AppTextStyles.caption(context).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddContribution,
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Thêm tiền đóng góp'),
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

class _MembersContributionCard extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final bool isLoadingMembers;
  final double goalAmount;
  final Map<String, dynamic> memberContributions;
  final Color groupColor;
  final String Function(double value) money;
  final double Function(dynamic value) toDouble;

  const _MembersContributionCard({
    required this.members,
    required this.isLoadingMembers,
    required this.goalAmount,
    required this.memberContributions,
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
            'Thành viên đóng góp',
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
                'Chưa có thành viên nào',
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

              final paidProgress = goalAmount <= 0
                  ? 0.0
                  : (paidAmount / goalAmount).clamp(0.0, 1.0).toDouble();

              final avatarUrl = (member['avatarUrl'] ?? '').toString();
              final username = (member['username'] ?? '').toString();
              final name = (member['name'] ?? 'Người dùng').toString();

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
                      const SizedBox(height: 6),
                      Text(
                        'Đã đóng ${money(paidAmount)}',
                        style: TextStyle(
                          color: groupColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
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
            'Tuỳ chọn nhóm',
            style: AppTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: 14),
          _ActionTile(
            icon: Icons.edit_outlined,
            title: 'Chỉnh sửa nhóm',
            subtitle: 'Đổi tên, màu, mục tiêu hoặc thành viên',
            color: AppColors.primaryBlue,
            onTap: onEdit,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: isOwner ? Icons.delete_outline_rounded : Icons.exit_to_app_rounded,
            title: isOwner ? 'Xoá nhóm' : 'Rời nhóm',
            subtitle: isOwner
                ? 'Xoá nhóm này cho tất cả thành viên'
                : 'Rời khỏi nhóm này',
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
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
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
                color: color.withOpacity(0.16),
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