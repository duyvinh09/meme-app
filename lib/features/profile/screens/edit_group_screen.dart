import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class EditGroupScreen extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const EditGroupScreen({
    super.key,
    required this.groupData,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  static const int kMaxGroupNameLength = 50;

  late final TextEditingController nameController;
  late final TextEditingController goalController;
  late Color selectedColor;

  String originalName = '';
  String originalGoalText = '';
  String originalColorHex = '';
  Set<String> originalMemberIds = {};

  bool didFormatInitialGoal = false;

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

  Set<String> selectedMemberIds = {};
  bool isSaving = false;
  bool isLoadingMembers = true;

  List<Map<String, dynamic>> currentMemberProfiles = [];

  @override
  void initState() {
    super.initState();

    originalName = (widget.groupData['name'] ?? '').toString().trim();

    nameController = TextEditingController(
      text: originalName,
    );

    final goalAmount = _toDouble(widget.groupData['goalAmount']);

    goalController = TextEditingController(
      text: goalAmount <= 0 ? '' : goalAmount.round().toString(),
    );

    originalColorHex = (widget.groupData['color'] ?? '#79AFFF').toString();
    selectedColor = _parseHexColor(originalColorHex);

    final memberIds = (widget.groupData['memberIds'] as List?)
        ?.map((e) => e.toString())
        .toSet() ??
        <String>{};

    selectedMemberIds = memberIds;
    originalMemberIds = {...memberIds};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentMembers();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    goalController.dispose();
    super.dispose();
  }

  String get groupId {
    return (widget.groupData['id'] ?? '').toString();
  }

  String get ownerUid {
    return (widget.groupData['ownerUid'] ?? '').toString();
  }

  bool _isOwner(BuildContext context) {
    final myUid = context.read<AuthController>().user?.uid;
    return myUid != null && myUid == ownerUid;
  }

  Future<void> _loadCurrentMembers() async {
    final repo = context.read<UserRepository>();

    final ids = (widget.groupData['memberIds'] as List?)
        ?.map((e) => e.toString())
        .where((id) => id.isNotEmpty)
        .toList() ??
        [];

    final result = <Map<String, dynamic>>[];

    for (final uid in ids) {
      final user = await repo.getUserProfile(uid);

      if (user != null) {
        result.add({
          'uid': user.uid,
          'name': user.name,
          'username': user.username,
          'email': user.email,
          'avatarUrl': user.avatarUrl,
          'isCurrentMember': true,
        });
      }
    }

    if (!mounted) return;

    setState(() {
      currentMemberProfiles = result;
      isLoadingMembers = false;
    });
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

  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '');

    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }

    return AppColors.primaryBlue;
  }

  String _toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  List<Map<String, dynamic>> _mergeMembersAndFriends({
    required List<Map<String, dynamic>> currentMembers,
    required List<Map<String, dynamic>> friends,
  }) {
    final map = <String, Map<String, dynamic>>{};

    for (final member in currentMembers) {
      final uid = (member['uid'] ?? '').toString();
      if (uid.isEmpty) continue;

      map[uid] = {
        ...member,
        'source': 'member',
      };
    }

    for (final friend in friends) {
      final uid = (friend['uid'] ?? '').toString();
      if (uid.isEmpty) continue;

      map[uid] = {
        ...?map[uid],
        ...friend,
        'source': map.containsKey(uid) ? 'member_friend' : 'friend',
      };
    }

    final items = map.values.toList();

    items.sort((a, b) {
      final aIsOwner = (a['uid'] ?? '').toString() == ownerUid;
      final bIsOwner = (b['uid'] ?? '').toString() == ownerUid;

      if (aIsOwner && !bIsOwner) return -1;
      if (!aIsOwner && bIsOwner) return 1;

      final aSelected = selectedMemberIds.contains((a['uid'] ?? '').toString());
      final bSelected = selectedMemberIds.contains((b['uid'] ?? '').toString());

      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;

      final aName = (a['name'] ?? a['username'] ?? '').toString();
      final bName = (b['name'] ?? b['username'] ?? '').toString();

      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return items;
  }

  void _toggleMember(String uid) {
    if (uid == ownerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chủ nhóm luôn phải ở trong nhóm'),
        ),
      );
      return;
    }

    setState(() {
      if (selectedMemberIds.contains(uid)) {
        selectedMemberIds.remove(uid);
      } else {
        selectedMemberIds.add(uid);
      }

      selectedMemberIds.add(ownerUid);
    });
  }

  Future<void> _save() async {
    if (isSaving) return;

    final myUid = context.read<AuthController>().user?.uid;
    final currency = context.read<ProfileController>().currency;

    if (myUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy người dùng hiện tại'),
        ),
      );
      return;
    }

    if (myUid != ownerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ chủ nhóm mới có thể chỉnh sửa nhóm'),
        ),
      );
      return;
    }

    if (groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin nhóm'),
        ),
      );
      return;
    }

    final name = nameController.text.trim();
    final inputAmount = _parseMoney(goalController.text, currency);

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

    final finalMemberIds = {
      ...selectedMemberIds,
      ownerUid,
    }.toList();

    setState(() {
      isSaving = true;
    });

    try {
      await context.read<UserRepository>().updateGroup(
        myUid: myUid,
        groupId: groupId,
        name: name,
        memberIds: finalMemberIds,
        colorHex: _toHex(selectedColor),
        goalAmount: goalAmount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật nhóm'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật nhóm thất bại: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthController>().user?.uid;
    final currency = context.watch<ProfileController>().currency;
    final isOwner = myUid != null && myUid == ownerUid;

    if (!isOwner) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
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
                        'Chỉnh sửa nhóm',
                        style: AppTextStyles.pageTitle(context),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 74,
                  color: AppColors.textSecondary(context),
                ),
                const SizedBox(height: 18),
                Text(
                  'Bạn không có quyền chỉnh sửa nhóm này',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle(context).copyWith(
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chỉ chủ nhóm mới có thể đổi thông tin, mời thành viên hoặc xoá thành viên khỏi nhóm.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    height: 1.45,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
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
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Chỉnh sửa nhóm',
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
                    controller: nameController,
                    label: 'Tên nhóm',
                    hintText: 'Nhập tên nhóm',
                    icon: Icons.groups_2_outlined,
                    cursorColor: selectedColor,
                    maxLength: kMaxGroupNameLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(kMaxGroupNameLength),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 14),

                  _EditInputField(
                    controller: goalController,
                    label: 'Số tiền mục tiêu',
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
                      'Màu nhóm',
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
                        final selected = selectedColor.value == color.value;

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
                                color:
                                selected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: selected
                                  ? [
                                BoxShadow(
                                  color: color.withOpacity(0.28),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                                  : null,
                            ),
                            child: selected
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
              stream: myUid == null
                  ? const Stream.empty()
                  : context.read<UserRepository>().streamFriends(myUid),
              builder: (context, snapshot) {
                final friends = snapshot.data ?? [];

                final mergedItems = _mergeMembersAndFriends(
                  currentMembers: currentMemberProfiles,
                  friends: friends,
                );

                if (isLoadingMembers) {
                  return _SectionCard(
                    padding: const EdgeInsets.all(22),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return _SectionCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thành viên nhóm',
                        style: AppTextStyles.sectionTitle(context),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Chọn bạn bè để mời vào nhóm. Thành viên cũ vẫn được giữ lại dù không còn là bạn bè.',
                        style: AppTextStyles.bodySecondary(context).copyWith(
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (mergedItems.isEmpty)
                        Text(
                          'Chưa có thành viên hoặc bạn bè để hiển thị',
                          style: AppTextStyles.bodySecondary(context),
                        )
                      else
                        ...mergedItems.map((item) {
                          final uid = (item['uid'] ?? '').toString();
                          final name = (item['name'] ?? 'Người dùng').toString();
                          final username = (item['username'] ?? '').toString();
                          final avatarUrl = (item['avatarUrl'] ?? '').toString();

                          final selected = selectedMemberIds.contains(uid);
                          final itemIsOwner = uid == ownerUid;

                          final source = (item['source'] ?? '').toString();
                          final isOldMember = source.contains('member');
                          final isFriend = source.contains('friend');

                          return _MemberSelectTile(
                            uid: uid,
                            name: name,
                            username: username,
                            avatarUrl: avatarUrl,
                            selected: selected,
                            isOwner: itemIsOwner,
                            isOldMember: isOldMember,
                            isFriend: isFriend,
                            color: selectedColor,
                            onTap: () => _toggleMember(uid),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            _InfoNoteCard(
              selectedColor: selectedColor,
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 58,
              child: FilledButton(
                onPressed: isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: selectedColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: selectedColor.withOpacity(0.45),
                  disabledForegroundColor: Colors.white.withOpacity(0.82),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isSaving
                      ? const SizedBox(
                    key: ValueKey('saving'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    key: ValueKey('save_text'),
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
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
    final subtitleParts = <String>[];

    if (isOwner) {
      subtitleParts.add('Chủ nhóm');
    } else if (isOldMember) {
      subtitleParts.add('Thành viên hiện tại');
    }

    if (isFriend) {
      subtitleParts.add('Bạn bè');
    } else if (isOldMember) {
      subtitleParts.add('Không còn là bạn bè');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? color.withOpacity(AppColors.isDark(context) ? 0.16 : 0.10)
            : AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? color.withOpacity(0.45) : AppColors.innerBorder(context),
        ),
      ),
      child: ListTile(
        onTap: isOwner ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: AppColors.card(context),
          backgroundImage: avatarUrl.trim().isNotEmpty
              ? NetworkImage(avatarUrl.trim())
              : null,
          child: avatarUrl.trim().isEmpty
              ? Icon(
            Icons.person_rounded,
            color: AppColors.textSecondary(context),
          )
              : null,
        ),
        title: Text(
          name.trim().isEmpty ? 'Người dùng' : name.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          [
            if (username.trim().isNotEmpty) '@${username.trim()}',
            ...subtitleParts,
          ].join(' • '),
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

class _InfoNoteCard extends StatelessWidget {
  final Color selectedColor;

  const _InfoNoteCard({
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selectedColor.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: selectedColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Khi thêm thành viên mới, nhóm sẽ xuất hiện trong tài khoản của họ. Khi bỏ chọn thành viên, nhóm sẽ bị xoá khỏi danh sách nhóm của người đó.',
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
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
    this.onChanged,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        cursorColor: cursorColor,
        style: AppTextStyles.body(context).copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          suffixText: suffixText,
          counterText: maxLength == null
              ? null
              : '${controller.text.length}/$maxLength',
          prefixIcon: Icon(
            icon,
            color: AppColors.textSecondary(context),
          ),
          labelStyle: AppTextStyles.caption(context).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: AppTextStyles.caption(context).copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context).withOpacity(0.65),
          ),
          suffixStyle: AppTextStyles.caption(context).copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
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