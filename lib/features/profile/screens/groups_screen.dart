import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../core/widgets/custom_button.dart';
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
      return Scaffold(
        body: Center(
          child: Text(context.l10n.user),
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
                        icon: Icons.arrow_back_ios_new_rounded,
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
                      context.l10n.groupsTitle,
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

                      final spentAmount =
                      _toDouble(item['spentAmount']);

                      final remainingBalance = currentAmount - spentAmount;

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
                        spentAmount: spentAmount,
                        spentAmountText: money(spentAmount),
                        remainingBalance: remainingBalance,
                        remainingBalanceText: money(remainingBalance),
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
  final double spentAmount;
  final String spentAmountText;
  final double remainingBalance;
  final String remainingBalanceText;
  final String goalAmountText;
  final double progress;
  final VoidCallback onTap;

  const _GroupTile({
    required this.groupName,
    required this.groupColor,
    required this.memberCount,
    required this.currentAmountText,
    required this.spentAmount,
    required this.spentAmountText,
    required this.remainingBalance,
    required this.remainingBalanceText,
    required this.goalAmountText,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: groupColor.withValues(alpha: 0.18),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  memberCount > 0
                      ? context.l10n.membersCount(memberCount)
                      : context.l10n.noFriends,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 13,
                  ),
                ),
                Text(
                  context.l10n.groupBalanceShort(remainingBalanceText),
                  style: TextStyle(
                    color: remainingBalance >= 0
                        ? AppColors.income
                        : AppColors.expense,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$currentAmountText / $goalAmountText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: groupColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (spentAmount > 0)
                  Text(
                    context.l10n.groupSpentShort(spentAmountText),
                    style: TextStyle(
                      color: AppColors.expense,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
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
  static const int kMaxGroupNameLength = UserRepository.maxGroupNameLength;

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
  late final Stream<List<Map<String, dynamic>>> _friendsStream;

  @override
  void initState() {
    super.initState();
    _friendsStream = widget.repo.streamFriends(widget.myUid);
  }

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
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.pleaseEnterGroupName),
        ),
      );
      return;
    }

    if (name.length > kMaxGroupNameLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupNameTooLong),
        ),
      );
      return;
    }

    final currency = context.read<ProfileController>().currency;
    final inputAmount = _parseMoney(goalAmountController.text, currency);

    if (inputAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.pleaseEnterGoalAmount),
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
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupCreated),
        ),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.profileUpdateFailed),
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

  static String _removeVietnameseDiacritics(String str) {
    const withDia =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđĐ';
    const withoutDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydD';
    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
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
                      context.l10n.createGroup,
                      style: AppTextStyles.pageTitle(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionCard(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: selectedColor.withOpacity(0.18),
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: selectedColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _EditInputField(
                      controller: groupNameController,
                      label: context.l10n.groupName,
                      hintText: context.l10n.groupNameHint,
                      icon: Icons.groups_2_outlined,
                      cursorColor: selectedColor,
                      maxLength: kMaxGroupNameLength,
                    ),
                    const SizedBox(height: 14),
                    _EditInputField(
                      controller: goalAmountController,
                      label: context.l10n.goalAmount,
                      hintText: AppCurrencyFormatter.formatInputHint(currency),
                      icon: Icons.flag_rounded,
                      suffixText: AppCurrencyFormatter.symbol(currency),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters:
                          currency == 'VND' ? [MoneyInputFormatter()] : [],
                      cursorColor: selectedColor,
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.l10n.groupColor,
                        style: AppTextStyles.sectionTitle(context).copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.innerBorder(context),
                        ),
                      ),
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: groupColors.map((color) {
                          final isSelected = selectedColor.value == color.value;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 48,
                              height: 48,
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
                                          color: color.withOpacity(0.28),
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
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _friendsStream,
                builder: (context, snapshot) {
                  final friends = snapshot.data ?? [];

                  final filteredFriends = friends.where((friend) {
                    if (searchKeyword.trim().isEmpty) return true;

                    final name = (friend['name'] ?? '').toString().toLowerCase();
                    final username =
                        (friend['username'] ?? '').toString().toLowerCase();
                    final keyword = searchKeyword.trim().toLowerCase();
                    final cleanKeyword = _removeVietnameseDiacritics(keyword);
                    final cleanName = _removeVietnameseDiacritics(name);
                    final cleanUsername = _removeVietnameseDiacritics(username);

                    return name.contains(keyword) ||
                        username.contains(keyword) ||
                        cleanName.contains(cleanKeyword) ||
                        cleanUsername.contains(cleanKeyword);
                  }).toList();

                  return _SectionCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.addMembers,
                                style: AppTextStyles.sectionTitle(context),
                              ),
                            ),
                            Text(
                              context.l10n.selectedCount(selectedFriendIds.length),
                              style: TextStyle(
                                color: selectedColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.groupMembersNote,
                          style: AppTextStyles.bodySecondary(context).copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SearchMemberBox(
                          controller: searchController,
                          color: selectedColor,
                          onChanged: (value) {
                            setState(() {
                              searchKeyword = value;
                            });
                          },
                          onClear: () {
                            setState(() {
                              searchController.clear();
                              searchKeyword = '';
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        if (friends.isEmpty)
                          const _NoFriendState()
                        else if (filteredFriends.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                context.l10n.noUsersFound,
                                style:
                                    AppTextStyles.bodySecondary(context).copyWith(
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          )
                        else
                          ...filteredFriends.map((friend) {
                            final friendUid = (friend['uid'] ?? '').toString();
                            final friendName =
                                (friend['name'] ?? context.l10n.user).toString();
                            final friendUsername =
                                (friend['username'] ?? '').toString();
                            final avatarUrl =
                                (friend['avatarUrl'] ?? '').toString();

                            final isSelected =
                                selectedFriendIds.contains(friendUid);

                            return _MemberSelectTile(
                              uid: friendUid,
                              name: friendName,
                              username: friendUsername,
                              avatarUrl: avatarUrl,
                              selected: isSelected,
                              isOwner: false,
                              isOldMember: false,
                              isFriend: true,
                              color: selectedColor,
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
                          }),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                height: 58,
                borderRadius: AppSizes.radiusPill,
                text: context.l10n.createGroup,
                backgroundColor: selectedColor,
                foregroundColor: AppColors.foregroundOnAccent(selectedColor),
                isLoading: isCreating,
                onPressedAsync: _createGroup,
              ),
            ],
          ),
        ),
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

class _EditInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Color cursorColor;

  const _EditInputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.cursorColor,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  State<_EditInputField> createState() => _EditInputFieldState();
}

class _EditInputFieldState extends State<_EditInputField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counterLimit = widget.maxLength;
    final hasFocus = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasFocus ? widget.cursorColor : AppColors.innerBorder(context),
          width: hasFocus ? 1.4 : 1.0,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        cursorColor: widget.cursorColor,
        maxLength: counterLimit,
        buildCounter:
            counterLimit == null || counterLimit <= 0
                ? null
                : (_, {required currentLength, required isFocused, required maxLength}) {
                    final lim = maxLength ?? counterLimit;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10, bottom: 6),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$currentLength/$lim',
                          style: AppTextStyles.caption(context).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    );
                  },
        style: AppTextStyles.body(context).copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          suffixText: widget.suffixText,
          counterText: counterLimit != null ? '' : null,
          prefixIcon: Icon(
            widget.icon,
            color: hasFocus ? widget.cursorColor : AppColors.textSecondary(context),
          ),
          labelStyle: AppTextStyles.caption(context).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasFocus ? widget.cursorColor : null,
          ),
          hintStyle: AppTextStyles.caption(context).copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context).withValues(alpha: 0.65),
          ),
          suffixStyle: AppTextStyles.caption(context).copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _SearchMemberBox extends StatefulWidget {
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchMemberBox({
    required this.controller,
    required this.color,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchMemberBox> createState() => _SearchMemberBoxState();
}

class _SearchMemberBoxState extends State<_SearchMemberBox> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;

    return GestureDetector(
      onTap: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasFocus ? widget.color : AppColors.innerBorder(context),
            width: hasFocus ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: hasFocus ? widget.color : AppColors.textSecondary(context),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                cursorColor: widget.color,
                style: AppTextStyles.body(context).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.friendsSearchHint,
                  hintStyle: AppTextStyles.bodySecondary(context).copyWith(
                    color: AppColors.textSecondary(context).withValues(alpha: 0.7),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (widget.controller.text.isNotEmpty)
              GestureDetector(
                onTap: widget.onClear,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.cancel_rounded,
                    color: AppColors.textSecondary(context),
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberSelectTile extends StatelessWidget {
  final String uid;
  final String name;
  final String username;
  final String avatarUrl;
  final bool selected;
  final bool isOwner;
  final bool isOldMember;
  final bool isFriend;
  final Color color;
  final VoidCallback onTap;

  const _MemberSelectTile({
    required this.uid,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.selected,
    required this.isOwner,
    required this.isOldMember,
    required this.isFriend,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: AppColors.isDark(context) ? 0.16 : 0.10)
            : AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.45) : AppColors.innerBorder(context),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        onTap: isOwner ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: AppColors.card(context),
          backgroundImage: avatarUrl.trim().isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl.trim())
              : null,
          child: avatarUrl.trim().isEmpty
              ? Icon(
                  Icons.person_rounded,
                  color: AppColors.textSecondary(context),
                )
              : null,
        ),
        title: Text(
          name.trim().isEmpty ? context.l10n.user : name.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          username.trim().isNotEmpty ? '@${username.trim()}' : '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: 12.5,
          ),
        ),
        trailing: isOwner
            ? Icon(
                Icons.lock_rounded,
                color: color,
              )
            : AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : Colors.transparent,
                  border: Border.all(
                    color: selected ? color : AppColors.textSecondary(context),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
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
            context.l10n.noFriends,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 17,
            ),
          ),
        ],
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
              context.l10n.noGroups,
              style: AppTextStyles.pageTitle(context).copyWith(
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.noGroupsSubtitle,
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
                label: Text(
                  context.l10n.createGroup,
                  style: const TextStyle(
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
          size: 20,
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