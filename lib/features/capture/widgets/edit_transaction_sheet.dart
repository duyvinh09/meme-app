import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/services/fcm_push_service.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../profile/widgets/avatar_with_frame.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../budget/controllers/budget_controller.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/controllers/user_category_controller.dart';
import 'transaction_moment_image.dart';

class EditTransactionSheet extends StatefulWidget {
  final TransactionModel transaction;
  final ValueChanged<TransactionModel>? onUpdated;

  const EditTransactionSheet({
    super.key,
    required this.transaction,
    this.onUpdated,
  });

  static Future<TransactionModel?> show(
    BuildContext context, {
    required TransactionModel transaction,
    ValueChanged<TransactionModel>? onUpdated,
  }) {
    return showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTransactionSheet(
        transaction: transaction,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _captionController;
  late final TextEditingController _noteController;

  late final FocusNode _amountFocusNode;
  late final FocusNode _captionFocusNode;
  late final FocusNode _noteFocusNode;

  late String _type;
  late String _category;
  late String _privacy;
  late DateTime _createdAt;
  String? _groupId;
  String? _groupName;
  List<String> _groupMemberIds = [];
  List<String> _closeFriendUids = [];

  int? _categoryIconCodePoint;
  String? _categoryColorHex;

  bool _isSaving = false;
  bool _isCategoryExpanded = false;

  final Map<String, Map<String, dynamic>> _defaultCategoryMeta = {
    'Ăn uống': {
      'icon': Icons.restaurant_rounded,
      'color': AppColors.income,
    },
    'Mua sắm': {
      'icon': Icons.shopping_bag_outlined,
      'color': AppColors.primaryPink,
    },
    'Đi lại': {
      'icon': Icons.directions_bus_outlined,
      'color': AppColors.primaryBlue,
    },
    'Giải trí': {
      'icon': Icons.movie_outlined,
      'color': AppColors.warning,
    },
    'Học tập': {
      'icon': Icons.menu_book_outlined,
      'color': AppColors.primaryPurple,
    },
    'Lương': {
      'icon': Icons.payments_outlined,
      'color': AppColors.income,
    },
    'Quà tặng': {
      'icon': Icons.card_giftcard_rounded,
      'color': AppColors.expense,
    },
    'Khác': {
      'icon': Icons.more_horiz_rounded,
      'color': const Color(0xFFAAAAAA),
    },
    'Quỹ nhóm': {
      'icon': Icons.savings_rounded,
      'color': const Color(0xFF10B981),
    },
  };

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    _type = tx.type;
    _category = tx.category;
    _privacy = tx.privacy;
    _createdAt = tx.createdAt;
    _groupId = tx.groupId;
    _groupName = tx.groupName;
    _groupMemberIds = List.from(tx.groupMemberIds);
    _closeFriendUids = List.from(tx.closeFriendUids);
    _categoryIconCodePoint = tx.categoryIconCodePoint;
    _categoryColorHex = tx.categoryColorHex;

    final initialAmountStr = tx.amount > 0
        ? NumberFormat('#,###', 'vi_VN').format(tx.amount.toInt())
        : '';
    _amountController = TextEditingController(text: initialAmountStr);
    _captionController = TextEditingController(text: tx.caption);
    _noteController = TextEditingController(
      text: tx.isVoiceExpense ? '' : tx.note,
    );

    _amountFocusNode = FocusNode()..addListener(_onFocusChanged);
    _captionFocusNode = FocusNode()..addListener(_onFocusChanged);
    _noteFocusNode = FocusNode()..addListener(_onFocusChanged);

    _captionController.addListener(_checkMentionQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().user?.uid;
      if (uid != null) {
        context.read<BudgetController>().load(uid);
        context.read<UserCategoryController>().load(uid);
      }
    });
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String? _activeMentionQuery;

  void _checkMentionQuery() {
    final text = _captionController.text;
    final selection = _captionController.selection;
    final cursor = selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    if (cursor > text.length) {
      if (_activeMentionQuery != null) setState(() => _activeMentionQuery = null);
      return;
    }

    final prefix = text.substring(0, cursor);
    final lastAt = prefix.lastIndexOf('@');
    if (lastAt == -1) {
      if (_activeMentionQuery != null) setState(() => _activeMentionQuery = null);
      return;
    }

    final query = prefix.substring(lastAt + 1);
    if (query.contains(' ') || query.contains('\n')) {
      if (_activeMentionQuery != null) setState(() => _activeMentionQuery = null);
      return;
    }

    final normalized = query.toLowerCase();
    if (_activeMentionQuery != normalized) {
      setState(() {
        _activeMentionQuery = normalized;
      });
    }
  }

  void _selectMentionFriend(String username) {
    HapticFeedback.selectionClick();
    final text = _captionController.text;
    final selection = _captionController.selection;
    final cursor = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
    final prefix = text.substring(0, cursor);
    final lastAt = prefix.lastIndexOf('@');

    final cleanUsername = username.replaceAll('@', '').trim();
    final insertText = '@$cleanUsername ';

    String newText;
    int newCursor;

    if (lastAt != -1 && lastAt < cursor) {
      final beforeAt = text.substring(0, lastAt);
      final afterCursor = text.substring(cursor);
      newText = '$beforeAt$insertText$afterCursor';
      newCursor = beforeAt.length + insertText.length;
    } else {
      newText = text.isEmpty
          ? insertText
          : (text.endsWith(' ') ? '$text$insertText' : '$text $insertText');
      newCursor = newText.length;
    }

    _captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );

    setState(() {
      _activeMentionQuery = null;
    });
  }

  void _removeMentionFriend(String username) {
    HapticFeedback.selectionClick();
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    final regex = RegExp('@$clean(\\s)?', caseSensitive: false);
    final newText = _captionController.text.replaceAll(regex, '').trim();
    _captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    setState(() {});
  }

  List<String> _extractTaggedUsernames(String text) {
    final mentionRegex = RegExp(r'(@[a-zA-Z0-9_.]+)');
    final matches = mentionRegex.allMatches(text);
    final set = <String>{};
    for (final m in matches) {
      final raw = m.group(0)!;
      if (raw.length > 1) {
        set.add(raw.substring(1).trim().toLowerCase());
      }
    }
    return set.toList();
  }

  /// Evaluates tagged usernames in caption against audience/privacy rules
  Future<List<String>> _getValidTaggedUsernames({
    required String myUid,
    required String caption,
    required String privacy,
    required List<String> closeFriendUids,
    required List<String> groupMemberIds,
    required UserRepository userRepo,
  }) async {
    final validTaggedUsernames = <String>[];
    final mentionRegex = RegExp(r'@([a-zA-Z0-9_.]+)');
    final matches = mentionRegex.allMatches(caption);

    if (caption.trim().isNotEmpty && privacy != 'private' && matches.isNotEmpty) {
      final checkedUsernames = <String>{};
      for (final m in matches) {
        final uName = m.group(1)?.toLowerCase();
        if (uName == null || uName.isEmpty || checkedUsernames.contains(uName)) continue;
        checkedUsernames.add(uName);

        final taggedUser = await userRepo.findUserByUsername(uName);
        if (taggedUser == null || taggedUser.uid == myUid) continue;

        if (privacy == 'friends') {
          final isFriend = await userRepo.isFriendWith(myUid, taggedUser.uid);
          if (isFriend) validTaggedUsernames.add(uName);
        } else if (privacy == 'close_friends') {
          final isFriend = await userRepo.isFriendWith(myUid, taggedUser.uid);
          final isClose = closeFriendUids.contains(taggedUser.uid);
          if (isFriend && isClose) validTaggedUsernames.add(uName);
        } else if (privacy == 'group') {
          final inGroup = groupMemberIds.contains(taggedUser.uid);
          final isFriend = await userRepo.isFriendWith(myUid, taggedUser.uid);
          if (inGroup && isFriend) validTaggedUsernames.add(uName);
        }
      }
    }
    return validTaggedUsernames;
  }

  void _showFriendPickerSheet(BuildContext context) {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null) return;
    final userRepo = context.read<UserRepository>();
    final isDark = AppColors.isDark(context);
    final l10n = context.l10n;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E212B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 38,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            l10n.tagFriends,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        onChanged: (val) {
                          setSheetState(() {
                            searchQuery = val.trim().toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: l10n.friendsSearchHint,
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF282C3A) : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _privacy == 'private'
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              child: Center(
                                child: Text(
                                  l10n.privateCannotTagFriends,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          : StreamBuilder<List<Map<String, dynamic>>>(
                              stream: userRepo.streamFriends(myUid),
                              builder: (ctx, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final friends = snapshot.data ?? [];
                                final currentTagged = _extractTaggedUsernames(_captionController.text);

                                final filtered = friends.where((f) {
                                  final friendUid = (f['uid'] ?? '').toString();
                                  if (_privacy == 'private') return false;
                                  if (_privacy == 'close_friends' && !_closeFriendUids.contains(friendUid)) return false;
                                  if (_privacy == 'group' && !_groupMemberIds.contains(friendUid)) return false;

                                  final name = (f['name'] ?? '').toString().toLowerCase();
                                  final username = (f['username'] ?? '').toString().toLowerCase();
                                  if (searchQuery.isNotEmpty) {
                                    return name.contains(searchQuery) || username.contains(searchQuery);
                                  }
                                  return true;
                                }).toList();

                                if (filtered.isEmpty) {
                                  final String emptyMessage;
                                  if (_privacy == 'private') {
                                    emptyMessage = isEn
                                        ? 'Private mode does not tag friends'
                                        : 'Chế độ riêng tư không gắn thẻ bạn bè';
                                  } else if (_privacy == 'close_friends' && searchQuery.isEmpty) {
                                    emptyMessage = l10n.closeFriendsTagOnly;
                                  } else if (_privacy == 'group' && searchQuery.isEmpty) {
                                    emptyMessage = isEn
                                        ? 'Only group members who are your friends can be tagged'
                                        : 'Chỉ gắn thẻ thành viên nhóm là bạn bè';
                                  } else {
                                    emptyMessage = l10n.noMatchingFriends;
                                  }

                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        emptyMessage,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark ? Colors.white60 : Colors.black54,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (ctx, index) {
                                    final f = filtered[index];
                                    final name = (f['name'] ?? '').toString().trim();
                                    final username = (f['username'] ?? '').toString().trim();
                                    final avatarUrl = (f['avatarUrl'] ?? '').toString();
                                    final avatarFrame = (f['avatarFrame'] ?? 'plain').toString();
                                    final displayName = name.isNotEmpty ? name : (username.isNotEmpty ? username : 'User');
                                    final handle = username.isNotEmpty ? username : displayName.replaceAll(' ', '_');
                                    final isAlreadyTagged = currentTagged.contains(handle.toLowerCase());

                                    return ListTile(
                                      leading: AvatarWithFrame(
                                        avatarUrl: avatarUrl,
                                        frameId: avatarFrame,
                                        size: 38,
                                      ),
                                      title: Text(
                                        displayName,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: username.isNotEmpty
                                          ? Text(
                                              '@$username',
                                              style: const TextStyle(
                                                color: AppColors.primaryBlue,
                                                fontSize: 12.5,
                                              ),
                                            )
                                          : null,
                                      trailing: isAlreadyTagged
                                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue)
                                          : const Icon(Icons.add_circle_outline_rounded, color: Colors.grey),
                                      onTap: () {
                                        if (isAlreadyTagged) {
                                          _removeMentionFriend(handle);
                                        } else {
                                          _selectMentionFriend(handle);
                                        }
                                        Navigator.pop(sheetContext);
                                      },
                                    );
                                  },
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

  Future<void> _notifyNewlyMentionedUsers({
    required String authorUid,
    required String caption,
    required String postId,
    required String postImageUrl,
    required List<String> newlyTaggedUsernames,
  }) async {
    if (newlyTaggedUsernames.isEmpty) return;

    try {
      final userRepo = context.read<UserRepository>();
      final author = await userRepo.getUserProfile(authorUid);
      final authorName = author?.name.isNotEmpty == true
          ? author!.name
          : (author?.username.isNotEmpty == true ? '@${author!.username}' : 'Bạn bè');

      for (final username in newlyTaggedUsernames) {
        final taggedUser = await userRepo.findUserByUsername(username);
        if (taggedUser == null || taggedUser.uid == authorUid) {
          continue;
        }

        final notifDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(taggedUser.uid)
            .collection('notifications')
            .doc();

        await notifDoc.set({
          'id': notifDoc.id,
          'type': 'mention',
          'senderUid': authorUid,
          'senderName': authorName,
          'senderAvatar': author?.avatarUrl ?? '',
          'senderAvatarFrame': author?.avatarFrame ?? 'plain',
          'postId': postId,
          'postImageUrl': postImageUrl,
          'caption': caption,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        unawaited(() async {
          try {
            await FcmPushService.instance.sendMentionNotification(
              targetUserId: taggedUser.uid,
              senderUid: authorUid,
              senderName: authorName,
              senderAvatar: author?.avatarUrl,
              postId: postId,
              caption: caption,
            );
          } catch (_) {}
        }());
      }
    } catch (e) {
      debugPrint('Error notifying newly mentioned users: $e');
    }
  }

  @override
  void dispose() {
    _captionController.removeListener(_checkMentionQuery);
    _amountFocusNode.removeListener(_onFocusChanged);
    _captionFocusNode.removeListener(_onFocusChanged);
    _noteFocusNode.removeListener(_onFocusChanged);
    _amountFocusNode.dispose();
    _captionFocusNode.dispose();
    _noteFocusNode.dispose();

    _amountController.dispose();
    _captionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _parseCurrentAmount() {
    final raw = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    return double.tryParse(raw) ?? 0.0;
  }

  String _toCanonicalCategory(String label) {
    final trimmed = label.trim().toLowerCase();
    switch (trimmed) {
      case 'ăn uống':
      case 'food':
        return 'Ăn uống';
      case 'mua sắm':
      case 'shopping':
        return 'Mua sắm';
      case 'đi lại':
      case 'transport':
        return 'Đi lại';
      case 'học tập':
      case 'education':
        return 'Học tập';
      case 'giải trí':
      case 'entertainment':
        return 'Giải trí';
      case 'lương':
      case 'salary':
        return 'Lương';
      case 'quà tặng':
      case 'gift':
        return 'Quà tặng';
      case 'khác':
      case 'other':
        return 'Khác';
      case 'quỹ nhóm':
      case 'group fund':
        return 'Quỹ nhóm';
      default:
        return label.trim();
    }
  }

  IconData _iconForCategory(String name) {
    final canonical = _toCanonicalCategory(name);
    final isCurrentSelected = canonical == _toCanonicalCategory(_category);

    if (isCurrentSelected && _categoryIconCodePoint != null && _categoryIconCodePoint! > 0) {
      return AppIconRegistry.fromCodePoint(_categoryIconCodePoint!);
    }

    try {
      final userCat = context.read<UserCategoryController>().findByName(name);
      if (userCat != null && userCat.iconCodePoint > 0) {
        return AppIconRegistry.fromCodePoint(userCat.iconCodePoint);
      }
    } catch (_) {}

    try {
      final budgets = context.read<BudgetController>().budgets;
      final budget = budgets.firstWhere(
        (b) => b.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );
      if (budget.iconCodePoint > 0) {
        return AppIconRegistry.fromCodePoint(budget.iconCodePoint);
      }
    } catch (_) {}

    final meta = _defaultCategoryMeta[canonical];
    if (meta != null && meta['icon'] is IconData) {
      return meta['icon'] as IconData;
    }
    return Icons.local_offer_outlined;
  }

  Color _colorForCategory(String name) {
    final canonical = _toCanonicalCategory(name);
    final isCurrentSelected = canonical == _toCanonicalCategory(_category);

    if (isCurrentSelected && _categoryColorHex != null && _categoryColorHex!.trim().isNotEmpty) {
      final hex = _categoryColorHex!.replaceAll('#', '').replaceAll('0x', '');
      try {
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
    }

    try {
      final userCat = context.read<UserCategoryController>().findByName(name);
      if (userCat != null && userCat.colorHex.isNotEmpty) {
        final hex = userCat.colorHex.replaceAll('#', '').replaceAll('0x', '');
        if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
        if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}

    try {
      final budgets = context.read<BudgetController>().budgets;
      final budget = budgets.firstWhere(
        (b) => b.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );
      if (budget.colorHex.isNotEmpty) {
        final hex = budget.colorHex.replaceAll('#', '').replaceAll('0x', '');
        if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
        if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}

    final meta = _defaultCategoryMeta[canonical];
    if (meta != null && meta['color'] is Color) {
      return meta['color'] as Color;
    }
    return AppColors.primaryBlue;
  }

  List<String> _getAvailableCategories() {
    final userCategoriesCtrl = context.watch<UserCategoryController>();
    final budgetCtrl = context.watch<BudgetController>();

    final isExpense = _type == 'expense';
    final categories = <String>[];
    final seen = <String>{};

    void addCat(String c) {
      final trimmed = c.trim();
      if (trimmed.isEmpty) return;
      final key = _toCanonicalCategory(trimmed).toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        categories.add(trimmed);
      }
    }

    if (_privacy == 'group' || widget.transaction.isGroupContribution) {
      addCat('Quỹ nhóm');
    }

    if (isExpense) {
      addCat('Ăn uống');
      addCat('Mua sắm');
      addCat('Đi lại');
      addCat('Giải trí');
      addCat('Học tập');

      for (final cat in userCategoriesCtrl.categoriesForExpense()) {
        addCat(cat.name);
      }
      for (final b in budgetCtrl.budgets) {
        addCat(b.name);
      }
      addCat('Khác');
    } else {
      addCat('Lương');
      addCat('Quà tặng');
      for (final cat in userCategoriesCtrl.categoriesForIncome()) {
        addCat(cat.name);
      }
      addCat('Khác');
    }

    return categories;
  }

  Future<void> _dismissKeyboardAndPop([TransactionModel? result]) async {
    _amountFocusNode.unfocus();
    _captionFocusNode.unfocus();
    _noteFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    await SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (mounted && MediaQuery.of(context).viewInsets.bottom > 0) {
      await Future.delayed(const Duration(milliseconds: 120));
    }

    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    _amountFocusNode.unfocus();
    _captionFocusNode.unfocus();
    _noteFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod('TextInput.hide'));

    final parsedAmount = _parseCurrentAmount();
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.enterValidAmount),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final oldTx = widget.transaction;
      final isGroupFund = _category == 'Quỹ nhóm' || _category == 'Group Fund' || oldTx.isGroupContribution;
      final effectiveType = isGroupFund ? 'expense' : _type;
      final userRepo = context.read<UserRepository>();
      final txRepo = context.read<TransactionRepository>();
      final feedCtrl = context.read<FeedController>();
      final l10n = context.l10n;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      final validNewTagged = await _getValidTaggedUsernames(
        myUid: oldTx.userId,
        caption: _captionController.text,
        privacy: _privacy,
        closeFriendUids: _closeFriendUids,
        groupMemberIds: _groupMemberIds,
        userRepo: userRepo,
      );

      final updatedTx = oldTx.copyWith(
        amount: parsedAmount,
        type: effectiveType,
        category: _category,
        caption: _captionController.text.trim(),
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : (oldTx.isVoiceExpense ? oldTx.note : ''),
        privacy: _privacy,
        createdAt: _createdAt,
        categoryIconCodePoint: _categoryIconCodePoint,
        categoryColorHex: _categoryColorHex,
        groupId: _groupId,
        groupName: _groupName,
        groupMemberIds: _groupMemberIds,
        closeFriendUids: _closeFriendUids,
        taggedUsernames: validNewTagged,
        isGroupContribution: isGroupFund,
      );

      await txRepo.updateTransaction(
        oldTransaction: oldTx,
        newTransaction: updatedTx,
      );

      if (!mounted) return;

      // Diffing mentions: Only send notification to newly tagged friends
      final oldTagged = oldTx.taggedUsernames.isNotEmpty
          ? oldTx.taggedUsernames.map((u) => u.toLowerCase()).toList()
          : _extractTaggedUsernames(oldTx.caption);
      final newlyTagged = validNewTagged
          .where((u) => !oldTagged.contains(u.toLowerCase()))
          .toList();

      if (newlyTagged.isNotEmpty && updatedTx.privacy != 'private' && updatedTx.sharedToFeed) {
        _notifyNewlyMentionedUsers(
          authorUid: oldTx.userId,
          caption: updatedTx.caption.trim(),
          postId: updatedTx.id,
          postImageUrl: updatedTx.thumbnailUrl.isNotEmpty
              ? updatedTx.thumbnailUrl
              : updatedTx.imageUrl,
          newlyTaggedUsernames: newlyTagged,
        );
      }

      // Update in memory feed controller
      feedCtrl.updateExistingTransaction(updatedTx);

      // Callback if provided
      widget.onUpdated?.call(updatedTx);

      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      if (mounted && MediaQuery.of(context).viewInsets.bottom > 0) {
        await Future.delayed(const Duration(milliseconds: 120));
      }

      if (mounted) {
        navigator.pop(updatedTx);
      }

      messenger.showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.editTransactionSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Edit transaction error: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: AppDurations.snackBar,
            content: Text(context.l10n.editTransactionFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final currency = context.watch<ProfileController>().currency;
    final l10n = context.l10n;

    final bgColor = isDark ? const Color(0xFF1E212B) : Colors.white;
    final cardColor = isDark ? const Color(0xFF282C3A) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    final availableCategories = _getAvailableCategories();
    final isExpense = _type == 'expense';
    final accentColor = isExpense ? AppColors.expense : AppColors.income;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _amountFocusNode.unfocus();
          _captionFocusNode.unfocus();
          _noteFocusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderColor),
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
              // Handle bar
              Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 10),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      l10n.editTransaction,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: subtextColor,
                        size: 22,
                      ),
                      onPressed: () => _dismissKeyboardAndPop(),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: borderColor),

              // Form content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media Preview & Amount Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Square thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 68,
                            height: 68,
                            child: TransactionMomentImage(
                              imageUrl: widget.transaction.displayImageUrl,
                              category: _category,
                              categoryIconCodePoint: _categoryIconCodePoint,
                              categoryColorHex: _categoryColorHex,
                              caption: null,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(16),
                              isVideo: widget.transaction.isVideo,
                              showVideoBadge: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Amount Input Box
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _amountFocusNode.requestFocus(),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _amountFocusNode.hasFocus
                                      ? accentColor
                                      : accentColor.withValues(alpha: 0.35),
                                  width: _amountFocusNode.hasFocus ? 2.0 : 1.5,
                                ),
                                boxShadow: _amountFocusNode.hasFocus
                                    ? [
                                        BoxShadow(
                                          color: accentColor.withValues(alpha: 0.22),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    isExpense ? '-' : '+',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      focusNode: _amountFocusNode,
                                      keyboardType: TextInputType.number,
                                      cursorColor: accentColor,
                                      cursorWidth: 2.2,
                                      cursorRadius: const Radius.circular(2),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        MoneyInputFormatter(),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          color: subtextColor,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        filled: false,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    currency == 'USD' ? '\$' : 'đ',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Type Toggle (Expense / Income)
                    if (widget.transaction.privacy != 'group' && !widget.transaction.isGroupContribution) ...[
                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _type = 'expense';
                                    _category = 'Ăn uống';
                                    _categoryIconCodePoint = null;
                                    _categoryColorHex = null;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    color: _type == 'expense'
                                        ? AppColors.expense
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    l10n.expense,
                                    style: TextStyle(
                                      color: _type == 'expense' ? Colors.white : subtextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _type = 'income';
                                    _category = 'Lương';
                                    _categoryIconCodePoint = null;
                                    _categoryColorHex = null;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  decoration: BoxDecoration(
                                    color: _type == 'income'
                                        ? AppColors.income
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    l10n.income,
                                    style: TextStyle(
                                      color: _type == 'income' ? Colors.white : subtextColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Category Section
                    Row(
                      children: [
                        Text(
                          l10n.selectCategory,
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCategoryExpanded = !_isCategoryExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                _isCategoryExpanded ? l10n.collapse : l10n.seeMore,
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Icon(
                                _isCategoryExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Category Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_isCategoryExpanded
                              ? availableCategories
                              : availableCategories.take(6).toList())
                          .map((cat) {
                        final isSelected = _toCanonicalCategory(_category) ==
                            _toCanonicalCategory(cat);
                        final catColor = _colorForCategory(cat);
                        final catIcon = _iconForCategory(cat);
                        final displayName = BudgetNameLocalizer.display(context, cat);

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final userCat = context
                                .read<UserCategoryController>()
                                .findByName(cat);
                            final budgets = context.read<BudgetController>().budgets;
                            BudgetModel? budget;
                            try {
                              budget = budgets.firstWhere(
                                (b) =>
                                    b.name.trim().toLowerCase() ==
                                    cat.trim().toLowerCase(),
                              );
                            } catch (_) {}

                            setState(() {
                              _category = cat;
                              if (userCat != null) {
                                _categoryIconCodePoint = userCat.iconCodePoint;
                                _categoryColorHex = userCat.colorHex;
                              } else if (budget != null) {
                                _categoryIconCodePoint = budget.iconCodePoint;
                                _categoryColorHex = budget.colorHex;
                              } else {
                                _categoryIconCodePoint = null;
                                _categoryColorHex = null;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? catColor.withValues(alpha: isDark ? 0.25 : 0.15)
                                  : cardColor,
                              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                              border: Border.all(
                                color: isSelected
                                    ? catColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  catIcon,
                                  size: 16,
                                  color: isSelected ? catColor : subtextColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: isSelected ? textColor : subtextColor,
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Caption Input Section
                    Row(
                      children: [
                        Icon(
                          Icons.subtitles_outlined,
                          size: 16,
                          color: _captionFocusNode.hasFocus
                              ? AppColors.primaryBlue
                              : subtextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.photoCaption,
                          style: TextStyle(
                            color: _captionFocusNode.hasFocus ? textColor : subtextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.photoCaptionSub,
                      style: TextStyle(
                        color: subtextColor.withValues(alpha: 0.8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Floating mention autocomplete suggestions if typing @
                    if (_activeMentionQuery != null &&
                        context.read<AuthController>().user?.uid != null &&
                        _privacy != 'private') ...[
                      _FriendMentionSuggestionsCard(
                        myUid: context.read<AuthController>().user!.uid,
                        query: _activeMentionQuery!,
                        onSelect: _selectMentionFriend,
                        privacy: _privacy,
                        closeFriendUids: _closeFriendUids,
                        groupMemberIds: _groupMemberIds,
                      ),
                      const SizedBox(height: 8),
                    ],

                    GestureDetector(
                      onTap: () => _captionFocusNode.requestFocus(),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _captionFocusNode.hasFocus
                                ? AppColors.primaryBlue
                                : borderColor,
                            width: _captionFocusNode.hasFocus ? 1.8 : 1.0,
                          ),
                          boxShadow: _captionFocusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: TextField(
                          controller: _captionController,
                          focusNode: _captionFocusNode,
                          maxLength: 70,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                            LengthLimitingTextInputFormatter(70),
                          ],
                          cursorColor: AppColors.primaryBlue,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.photoCaptionHint,
                            hintStyle: TextStyle(
                              color: subtextColor,
                              fontSize: 14,
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),

                    // Tagged Friends List & Action Row
                    if (_privacy != 'private') ...[
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final taggedFriends = _extractTaggedUsernames(_captionController.text);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.alternate_email_rounded,
                                    size: 13.5,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    l10n.taggedFriendsTitle,
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  for (final username in taggedFriends)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue
                                            .withValues(alpha: isDark ? 0.22 : 0.12),
                                        borderRadius:
                                            BorderRadius.circular(AppSizes.radiusPill),
                                        border: Border.all(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '@$username',
                                            style: const TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          GestureDetector(
                                            onTap: () => _removeMentionFriend(username),
                                            behavior: HitTestBehavior.opaque,
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 15,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  GestureDetector(
                                    onTap: () => _showFriendPickerSheet(context),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 5.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius:
                                            BorderRadius.circular(AppSizes.radiusPill),
                                        border: Border.all(
                                          color: borderColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_add_alt_1_rounded,
                                            size: 14,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF374151),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            l10n.tagFriendAction,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF374151),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Note Input Section
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 17,
                          color: _noteFocusNode.hasFocus
                              ? AppColors.primaryBlue
                              : subtextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.expenseNote,
                          style: TextStyle(
                            color: _noteFocusNode.hasFocus ? textColor : subtextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.expenseNoteSub,
                      style: TextStyle(
                        color: subtextColor.withValues(alpha: 0.8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _noteFocusNode.requestFocus(),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _noteFocusNode.hasFocus
                                ? AppColors.primaryBlue
                                : borderColor,
                            width: _noteFocusNode.hasFocus ? 1.8 : 1.0,
                          ),
                          boxShadow: _noteFocusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: TextField(
                          controller: _noteController,
                          focusNode: _noteFocusNode,
                          maxLines: 2,
                          cursorColor: AppColors.primaryBlue,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.expenseNoteHint,
                            hintStyle: TextStyle(
                              color: subtextColor,
                              fontSize: 14,
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0099FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? Colors.white12
                              : Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.saveChanges,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _FriendMentionSuggestionsCard extends StatelessWidget {
  final String myUid;
  final String query;
  final ValueChanged<String> onSelect;
  final String privacy;
  final List<String> closeFriendUids;
  final List<String> groupMemberIds;

  const _FriendMentionSuggestionsCard({
    required this.myUid,
    required this.query,
    required this.onSelect,
    this.privacy = 'friends',
    this.closeFriendUids = const [],
    this.groupMemberIds = const [],
  });

  @override
  Widget build(BuildContext context) {
    final userRepo = context.read<UserRepository>();
    final isDark = AppColors.isDark(context);

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 165,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xEB161922) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
            child: Row(
              children: [
                const Icon(
                  Icons.alternate_email_rounded,
                  color: AppColors.primaryBlue,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  context.l10n.tagFriends,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: userRepo.streamFriends(myUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  );
                }

                final friends = snapshot.data ?? [];
                final filtered = friends.where((f) {
                  if (privacy == 'private') return false;
                  final friendUid = (f['uid'] ?? '').toString();
                  if (privacy == 'close_friends' &&
                      !closeFriendUids.contains(friendUid)) {
                    return false;
                  }
                  if (privacy == 'group' &&
                      !groupMemberIds.contains(friendUid)) {
                    return false;
                  }

                  final name = (f['name'] ?? '').toString().toLowerCase();
                  final username =
                      (f['username'] ?? '').toString().toLowerCase();
                  if (query.isEmpty) return true;
                  return name.contains(query) || username.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  final isEn = Localizations.localeOf(context).languageCode == 'en';
                  final String emptyMessage;
                  if (privacy == 'private') {
                    emptyMessage = isEn
                        ? 'Private mode does not tag friends'
                        : 'Chế độ riêng tư không gắn thẻ bạn bè';
                  } else if (privacy == 'close_friends' && query.isEmpty) {
                    emptyMessage = context.l10n.closeFriendsTagOnly;
                  } else if (privacy == 'group' && query.isEmpty) {
                    emptyMessage = isEn
                        ? 'Only group members who are your friends can be tagged'
                        : 'Chỉ gắn thẻ thành viên nhóm là bạn bè';
                  } else {
                    emptyMessage = context.l10n.noMatchingFriends;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Center(
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  itemBuilder: (context, index) {
                    final friend = filtered[index];
                    final name = (friend['name'] ?? '').toString().trim();
                    final username =
                        (friend['username'] ?? '').toString().trim();
                    final avatarUrl = (friend['avatarUrl'] ?? '').toString();
                    final avatarFrame =
                        (friend['avatarFrame'] ?? 'plain').toString();
                    final displayName = name.isNotEmpty
                        ? name
                        : (username.isNotEmpty ? username : 'User');
                    final mentionHandle = username.isNotEmpty
                        ? username
                        : displayName.replaceAll(' ', '_');

                    return InkWell(
                      onTap: () => onSelect(mentionHandle),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            AvatarWithFrame(
                              avatarUrl: avatarUrl,
                              frameId: avatarFrame,
                              size: 28,
                            ),
                            const SizedBox(width: 9),
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
                                      color:
                                          isDark ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (username.isNotEmpty)
                                    Text(
                                      '@$username',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.north_west_rounded,
                              color: AppColors.primaryBlue,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
