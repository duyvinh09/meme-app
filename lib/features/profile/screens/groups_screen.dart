import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().user?.uid;
    final currency = context.watch<ProfileController>().currency;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('Không có người dùng'),
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
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: context.read<UserRepository>().streamGroups(uid),
          builder: (context, snapshot) {
            final isLoadingGroups =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

            final groups = snapshot.data ?? [];
            final isEmpty = !isLoadingGroups && groups.isEmpty;

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
                              icon: Icons.groups_2_outlined,
                              onTap: () {},
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
                              onTap: () => _openCreateGroupScreen(context),
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
                      'Nhóm',
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                ),
                Expanded(
                  child: isLoadingGroups
                      ? const Center(
                    child: CircularProgressIndicator(),
                  )
                      : isEmpty
                      ? _EmptyGroupsView(
                    onCreateGroup: () =>
                        _openCreateGroupScreen(context),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePadding,
                      24,
                      AppSizes.pagePadding,
                      24,
                    ),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = groups[index];

                      final groupName =
                      (item['name'] ?? 'Nhóm').toString();

                      final colorHex =
                      (item['color'] ?? '#79AFFF').toString();

                      final memberCount =
                      (item['memberCount'] ?? 0) is int
                          ? item['memberCount'] as int
                          : int.tryParse(
                        (item['memberCount'] ?? '0')
                            .toString(),
                      ) ??
                          0;

                      final goalAmount =
                      _toDouble(item['goalAmount']);

                      final currentAmount =
                      _toDouble(item['currentAmount']);

                      final progress = goalAmount <= 0
                          ? 0.0
                          : (currentAmount / goalAmount)
                          .clamp(0.0, 1.0)
                          .toDouble();

                      final groupColor = _parseHexColor(colorHex);

                      return _GroupTile(
                        groupName: groupName,
                        groupColor: groupColor,
                        memberCount: memberCount,
                        currentAmountText: money(currentAmount),
                        goalAmountText: money(goalAmount),
                        progress: progress,
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupDetailScreen(
                                groupData: item,
                              ),
                            ),
                          );

                          if (changed == true && mounted) {
                            setState(() {});
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreateGroupScreen(BuildContext context) async {
    final uid = context.read<AuthController>().user?.uid;
    final repo = context.read<UserRepository>();

    if (uid == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(
          myUid: uid,
          repo: repo,
        ),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '');

    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }

    return AppColors.primaryBlue;
  }
}

class _GroupTile extends StatelessWidget {
  final String groupName;
  final Color groupColor;
  final int memberCount;
  final String currentAmountText;
  final String goalAmountText;
  final double progress;
  final VoidCallback onTap;

  const _GroupTile({
    required this.groupName,
    required this.groupColor,
    required this.memberCount,
    required this.currentAmountText,
    required this.goalAmountText,
    required this.progress,
    required this.onTap,
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
          vertical: 8,
        ),
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: groupColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.groups_2_rounded,
            color: groupColor,
          ),
        ),
        title: Text(
          groupName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              memberCount > 0 ? '$memberCount thành viên' : 'Chưa có thành viên',
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$currentAmountText / $goalAmountText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: groupColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.innerBorder(context),
                valueColor: AlwaysStoppedAnimation<Color>(groupColor),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary(context),
        ),
      ),
    );
  }
}

class CreateGroupScreen extends StatefulWidget {
  final String myUid;
  final UserRepository repo;

  const CreateGroupScreen({
    super.key,
    required this.myUid,
    required this.repo,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  static const int kMaxGroupNameLength = 50;

  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController goalAmountController = TextEditingController();

  final List<Color> groupColors = const [
    AppColors.primaryBlue,
    AppColors.income,
    AppColors.expense,
    AppColors.warning,
    AppColors.primaryPurple,
    AppColors.primaryPink,
    Color(0xFF55B9B2),
    Color(0xFF7B8AD3),
    Color(0xFF4FC3DC),
    Color(0xFFF2D14A),
    Color(0xFFB29B90),
    Color(0xFFA3B3BE),
  ];

  Color selectedColor = AppColors.primaryBlue;
  bool isCreating = false;
  String searchKeyword = '';
  final Set<String> selectedFriendIds = {};

  @override
  void dispose() {
    groupNameController.dispose();
    searchController.dispose();
    goalAmountController.dispose();
    super.dispose();
  }

  double _parseMoney(String value, String currency) {
    final cleaned = currency == 'USD'
        ? value.replaceAll(RegExp(r'[^0-9.]'), '')
        : value.replaceAll(RegExp(r'[^0-9]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> _createGroup() async {
    if (isCreating) return;

    final name = groupNameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên nhóm'),
        ),
      );
      return;
    }

    if (name.length > kMaxGroupNameLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên nhóm tối đa 50 ký tự'),
        ),
      );
      return;
    }

    final currency = context.read<ProfileController>().currency;
    final inputAmount = _parseMoney(goalAmountController.text, currency);

    if (inputAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền mục tiêu'),
        ),
      );
      return;
    }

    final goalAmount = AppCurrencyFormatter.toVnd(
      inputAmount: inputAmount,
      currency: currency,
    );

    setState(() {
      isCreating = true;
    });

    try {
      await widget.repo.createGroup(
        uid: widget.myUid,
        name: name,
        memberIds: selectedFriendIds.toList(),
        colorHex:
        '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
        goalAmount: goalAmount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo nhóm'),
        ),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo nhóm thất bại'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.repo.streamFriends(widget.myUid),
          builder: (context, snapshot) {
            final friends = snapshot.data ?? [];

            final filteredFriends = friends.where((friend) {
              if (searchKeyword.trim().isEmpty) return true;

              final name = (friend['name'] ?? '').toString().toLowerCase();
              final username =
              (friend['username'] ?? '').toString().toLowerCase();
              final keyword = searchKeyword.trim().toLowerCase();

              return name.contains(keyword) || username.contains(keyword);
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(32),
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
                              child: _ActionPillButton(
                                label: 'Huỷ',
                                onTap: () => Navigator.pop(context),
                                textColor: AppColors.textSecondary(context),
                                backgroundColor: AppColors.surface(context),
                                borderColor: AppColors.innerBorder(context),
                              ),
                            ),
                            Center(
                              child: Text(
                                'Tạo nhóm',
                                style: AppTextStyles.pageTitle(context).copyWith(
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _ActionPillButton(
                                label: isCreating ? '...' : 'Tạo',
                                onTap: _createGroup,
                                textColor: AppColors.primaryBlue,
                                backgroundColor: AppColors.surface(context),
                                borderColor: AppColors.innerBorder(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: selectedColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(
                          Icons.groups_2_rounded,
                          size: 54,
                          color: selectedColor,
                        ),
                      ),
                      const SizedBox(height: 22),

                      _LargeInputBox(
                        height: 90,
                        child: TextField(
                          controller: groupNameController,
                          textAlign: TextAlign.center,
                          cursorColor: selectedColor,
                          maxLength: kMaxGroupNameLength,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(kMaxGroupNameLength),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: AppTextStyles.body(context).copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: TextInputDecoration(
                            hintText: 'Tên nhóm',
                            counterText: '${groupNameController.text.length}/$kMaxGroupNameLength',
                            hintStyle:
                            AppTextStyles.bodySecondary(context).copyWith(
                              color: AppColors.textSecondary(context)
                                  .withOpacity(0.75),
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                          ).toInputDecoration(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _LargeInputBox(
                        height: 78,
                        child: TextField(
                          controller: goalAmountController,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters:
                          currency == 'VND' ? [MoneyInputFormatter()] : [],
                          cursorColor: selectedColor,
                          style: AppTextStyles.body(context).copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: TextInputDecoration(
                            hintText:
                            'Mục tiêu tiền, ví dụ ${AppCurrencyFormatter.formatInputHint(currency)}',
                            hintStyle:
                            AppTextStyles.bodySecondary(context).copyWith(
                              color: AppColors.textSecondary(context)
                                  .withOpacity(0.75),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ).toInputDecoration().copyWith(
                            suffixText:
                            AppCurrencyFormatter.symbol(currency),
                            suffixStyle:
                            AppTextStyles.caption(context).copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Màu',
                          style: AppTextStyles.sectionTitle(context).copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.innerBorder(context),
                          ),
                        ),
                        child: Wrap(
                          spacing: 18,
                          runSpacing: 18,
                          children: groupColors.map((color) {
                            final isSelected =
                                selectedColor.value == color.value;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedColor = color;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.25),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Thêm thành viên',
                              style:
                              AppTextStyles.sectionTitle(context).copyWith(
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Text(
                            '${selectedFriendIds.length} đã chọn',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _SearchFriendBox(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchKeyword = value;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      if (friends.isEmpty)
                        const _NoFriendState()
                      else if (filteredFriends.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 30,
                            bottom: 26,
                          ),
                          child: Text(
                            'Không tìm thấy bạn bè phù hợp',
                            style: AppTextStyles.bodySecondary(context).copyWith(
                              fontSize: 16,
                            ),
                          ),
                        )
                      else
                        Column(
                          children: filteredFriends.map((friend) {
                            final friendUid =
                            (friend['uid'] ?? '').toString();
                            final friendName =
                            (friend['name'] ?? 'Người dùng').toString();
                            final friendUsername =
                            (friend['username'] ?? '').toString();
                            final avatarUrl =
                            (friend['avatarUrl'] ?? '').toString();

                            final isSelected =
                            selectedFriendIds.contains(friendUid);

                            return _SelectableFriendTile(
                              friendUid: friendUid,
                              friendName: friendName,
                              friendUsername: friendUsername,
                              avatarUrl: avatarUrl,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedFriendIds.remove(friendUid);
                                  } else {
                                    selectedFriendIds.add(friendUid);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LargeInputBox extends StatelessWidget {
  final double height;
  final Widget child;

  const _LargeInputBox({
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _SearchFriendBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchFriendBox({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary(context),
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AppColors.primaryBlue,
              style: AppTextStyles.body(context).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: TextInputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                hintStyle: AppTextStyles.bodySecondary(context).copyWith(
                  color: AppColors.textSecondary(context).withOpacity(0.75),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ).toInputDecoration(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableFriendTile extends StatelessWidget {
  final String friendUid;
  final String friendName;
  final String friendUsername;
  final String avatarUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableFriendTile({
    required this.friendUid,
    required this.friendName,
    required this.friendUsername,
    required this.avatarUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
          isSelected ? AppColors.primaryBlue : AppColors.innerBorder(context),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.card(context),
          backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? Icon(
            Icons.person,
            color: AppColors.textSecondary(context),
          )
              : null,
        ),
        title: Text(
          friendName,
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
        trailing: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.innerBorder(context),
              width: 1.8,
            ),
          ),
          child: isSelected
              ? const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 16,
          )
              : null,
        ),
      ),
    );
  }
}

class _NoFriendState extends StatelessWidget {
  const _NoFriendState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 26),
      child: Column(
        children: [
          Icon(
            Icons.group_off_rounded,
            size: 62,
            color: AppColors.textSecondary(context).withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có bạn bè liên kết',
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const _ActionPillButton({
    required this.label,
    required this.onTap,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          color: backgroundColor,
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyGroupsView extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const _EmptyGroupsView({
    required this.onCreateGroup,
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
                color: AppColors.primaryBlue.withOpacity(0.18),
              ),
              child: const Icon(
                Icons.groups_2_outlined,
                size: 56,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Chưa có nhóm',
              style: AppTextStyles.pageTitle(context).copyWith(
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tạo nhóm để cùng theo dõi chi tiêu và quản lý hoạt động chung',
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
                onPressed: onCreateGroup,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Tạo nhóm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
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

  const _TopSmallButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
    );
  }
}

class TextInputDecoration {
  final String hintText;
  final TextStyle? hintStyle;
  final String? counterText;

  const TextInputDecoration({
    required this.hintText,
    this.hintStyle,
    this.counterText,
  });

  InputDecoration toInputDecoration() {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: hintStyle,
      counterText: counterText,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      filled: false,
      contentPadding: EdgeInsets.zero,
    );
  }
}