import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  static const int kMaxGroupNameLength = UserRepository.maxGroupNameLength;

  late final TextEditingController nameController;
  late final TextEditingController goalController;
  late Color selectedColor;

  String originalName = '';
  late final double _storedGoalAmountVnd;
  late final String _originalColorCanonical;
  Set<String> originalMemberIds = {};

  bool _didSeedGoalField = false;

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
  bool isLoadingMembers = true;

  List<Map<String, dynamic>> currentMemberProfiles = [];

  @override
  void initState() {
    super.initState();

    originalName = (widget.groupData['name'] ?? '').toString().trim();
    _storedGoalAmountVnd = _toDouble(widget.groupData['goalAmount']);

    nameController = TextEditingController(
      text: originalName,
    );

    goalController = TextEditingController();

    final colorRaw = (widget.groupData['color'] ?? '#79AFFF').toString();
    _originalColorCanonical = _normalizeStoredHex(colorRaw);
    selectedColor = _parseHexColor(colorRaw);

    final memberIds = (widget.groupData['memberIds'] as List?)
        ?.map((e) => e.toString())
        .toSet() ??
        <String>{};

    selectedMemberIds = memberIds;
    originalMemberIds = {...memberIds};

    nameController.addListener(_scheduleRebuildForDirty);
    goalController.addListener(_scheduleRebuildForDirty);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentMembers();
      _seedGoalFieldDisplay();
    });
  }

  void _scheduleRebuildForDirty() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    nameController.removeListener(_scheduleRebuildForDirty);
    goalController.removeListener(_scheduleRebuildForDirty);
    nameController.dispose();
    goalController.dispose();
    super.dispose();
  }

  String _normalizeStoredHex(String hex) {
    final raw = hex.replaceAll('#', '').trim().toUpperCase();
    return raw.length == 6 ? '#$raw' : '#79AFFF';
  }

  void _seedGoalFieldDisplay() {
    if (!mounted) return;

    final currency = context.read<ProfileController>().currency;

    if (_storedGoalAmountVnd <= 0) {
      goalController.clear();
      setState(() {
        _didSeedGoalField = true;
      });
      return;
    }

    switch (AppCurrencyFormatter.normalizeCurrency(currency)) {
      case 'USD':
        final amount = AppCurrencyFormatter.fromVnd(
          amountVnd: _storedGoalAmountVnd,
          currency: 'USD',
        );
        goalController.text = NumberFormat.currency(
          locale: 'en_US',
          decimalDigits: 2,
          symbol: '',
        ).format(amount).trim();
        break;
      default:
        goalController.text = NumberFormat.decimalPattern(
          'vi_VN',
        ).format(_storedGoalAmountVnd.round());
        break;
    }

    setState(() {
      _didSeedGoalField = true;
    });
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  bool _membersChanged() {
    if (selectedMemberIds.length != originalMemberIds.length) return true;
    for (final id in selectedMemberIds) {
      if (!originalMemberIds.contains(id)) return true;
    }
    return false;
  }

  bool _goalChanged(String? currency) {
    if (!_didSeedGoalField) return false;

    final c = AppCurrencyFormatter.normalizeCurrency(currency);
    final raw = goalController.text.trim();

    if (raw.isEmpty) {
      return _storedGoalAmountVnd.round() != 0;
    }

    final parsed = _parseMoney(raw, c);
    if (parsed <= 0) {
      return _storedGoalAmountVnd.round() != 0;
    }

    final editedVnd = AppCurrencyFormatter.toVnd(
      inputAmount: parsed,
      currency: currency,
    );
    return editedVnd.round() != _storedGoalAmountVnd.round();
  }

  bool _hasPendingEdits(String? currency) {
    if (nameController.text.trim() != originalName) return true;
    if (_colorToHex(selectedColor) != _originalColorCanonical) return true;
    if (_membersChanged()) return true;
    return _goalChanged(currency);
  }

  String get groupId {
    return (widget.groupData['id'] ?? '').toString();
  }

  String get ownerUid {
    return (widget.groupData['ownerUid'] ?? '').toString();
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
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.ownerMustBeInGroup),
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
    final myUid = context.read<AuthController>().user?.uid;
    final currency = context.read<ProfileController>().currency;

    if (myUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.currentUserNotFound),
        ),
      );
      return;
    }

    if (myUid != ownerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.onlyOwnerCanEditGroup),
        ),
      );
      return;
    }

    if (groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupInfoNotFound),
        ),
      );
      return;
    }

    final name = nameController.text.trim();
    final inputAmount = _parseMoney(goalController.text, currency);

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

    final finalMemberIds = {
      ...selectedMemberIds,
      ownerUid,
    }.toList();

    try {
      await context.read<UserRepository>().updateGroup(
        myUid: myUid,
        groupId: groupId,
        name: name,
        memberIds: finalMemberIds,
        colorHex: _colorToHex(selectedColor),
        goalAmount: goalAmount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupUpdated),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupUpdateFailedWithError(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthController>().user?.uid;
    final currency = context.watch<ProfileController>().currency;
    final isOwner = myUid != null && myUid == ownerUid;
    final pendingEdits = isOwner ? _hasPendingEdits(currency) : false;

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
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.l10n.editGroup,
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
                  context.l10n.noPermissionToEditGroup,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle(context).copyWith(
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.onlyOwnerCanEditNote,
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
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.l10n.editGroup,
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
                    label: context.l10n.groupName,
                    hintText: context.l10n.groupNameHint,
                    icon: Icons.groups_2_outlined,
                    cursorColor: selectedColor,
                    maxLength: kMaxGroupNameLength,
                  ),

                  const SizedBox(height: 14),

                  _EditInputField(
                    controller: goalController,
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
              stream: context.read<UserRepository>().streamFriends(myUid),
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
                        context.l10n.groupMembers,
                        style: AppTextStyles.sectionTitle(context),
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

                      if (mergedItems.isEmpty)
                        Text(
                          context.l10n.noMembersOrFriends,
                          style: AppTextStyles.bodySecondary(context),
                        )
                      else
                        ...mergedItems.map((item) {
                          final uid = (item['uid'] ?? '').toString();
                          final name = (item['name'] ?? context.l10n.user).toString();
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

            CustomButton(
              height: 58,
              borderRadius: AppSizes.radiusPill,
              text: context.l10n.saveChanges,
              backgroundColor: selectedColor,
              foregroundColor: AppColors.foregroundOnAccent(selectedColor),
              onPressedAsync: pendingEdits ? _save : null,
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
      subtitleParts.add(context.l10n.groupOwner);
    } else if (isOldMember) {
      subtitleParts.add(context.l10n.currentMember);
    }

    if (isFriend) {
      subtitleParts.add(context.l10n.friendsTitle);
    } else if (isOldMember) {
      subtitleParts.add(context.l10n.notFriendsAnymore);
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
          name.trim().isEmpty ? context.l10n.user : name.trim(),
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
              context.l10n.groupMemberManagementNote,
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
  Widget build(BuildContext context) {
    final counterLimit = maxLength;

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
        cursorColor: cursorColor,
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
          labelText: label,
          hintText: hintText,
          suffixText: suffixText,
          counterText: counterLimit != null ? '' : null,
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
            color: AppColors.textSecondary(context).withValues(alpha: 0.65),
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