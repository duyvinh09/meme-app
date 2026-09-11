import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/services/local_settings_service.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/widgets/async_filled_button.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/avatar_with_frame.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeTab = 'all'; // 'all', 'close', 'requests'
  String _requestSortOrder = 'default'; // 'default', 'newest', 'oldest'

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
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _toggleCloseFriend({
    required String myUid,
    required String friendUid,
    required bool currentStatus,
    required String friendName,
  }) async {
    HapticFeedback.selectionClick();
    final newStatus = !currentStatus;

    await context.read<UserRepository>().toggleCloseFriend(
          myUid: myUid,
          friendUid: friendUid,
          isCloseFriend: newStatus,
        );

    if (mounted) {
      AppToast.show(
        context,
        newStatus
            ? context.l10n.addedToCloseFriends(friendName)
            : context.l10n.removedFromCloseFriends(friendName),
        icon: newStatus ? Icons.star_rounded : Icons.star_outline_rounded,
      );
    }
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
        backgroundColor: AppColors.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          context.l10n.deleteFriendQuestion,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.deleteFriendWarning(friendName),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
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
          Row(
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    context.l10n.delete,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await repo.removeFriend(
      myUid: myUid,
      friendUid: friendUid,
    );

    if (context.mounted) {
      AppToast.show(
        context,
        context.l10n.friendDeleted(friendName),
        icon: Icons.person_remove_rounded,
      );
    }
  }

  void _showFriendOptionsModal({
    required BuildContext context,
    required String myUid,
    required String friendUid,
    required String friendName,
    required String friendUsername,
    required String avatarUrl,
    required String avatarFrame,
    required bool isCloseFriend,
  }) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F2B) : AppColors.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AvatarWithFrame(
                    avatarUrl: avatarUrl,
                    frameId: avatarFrame,
                    size: 46,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friendName,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        if (friendUsername.isNotEmpty)
                          Text(
                            '@$friendUsername',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryBlue,
                ),
                title: Text(
                  context.l10n.sendMessageAction,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    RouteNames.chatConversation,
                    arguments: {
                      'friend': UserModel.fromMap({
                        'uid': friendUid,
                        'name': friendName,
                        'username': friendUsername,
                        'avatarUrl': avatarUrl,
                        'avatarFrame': avatarFrame,
                      }),
                    },
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isCloseFriend
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: isCloseFriend
                      ? const Color(0xFFF59E0B)
                      : textPrimary,
                ),
                title: Text(
                  isCloseFriend
                      ? context.l10n.removeFromCloseFriends
                      : context.l10n.addToCloseFriends,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleCloseFriend(
                    myUid: myUid,
                    friendUid: friendUid,
                    currentStatus: isCloseFriend,
                    friendName: friendName,
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.expense,
                ),
                title: Text(
                  context.l10n.delete,
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveFriend(
                    context: context,
                    myUid: myUid,
                    friendUid: friendUid,
                    friendName: friendName,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSentRequestsModal(BuildContext context, String uid) {
    HapticFeedback.lightImpact();
    final isDark = AppColors.isDark(context);
    final repo = context.read<UserRepository>();
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: repo.streamSentFriendRequests(uid),
          builder: (context, snapshot) {
            final sentList = snapshot.data ?? [];
            final isLoading = snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E212B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                ),
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
                    Container(
                      width: 38,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              size: 17,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.l10n.sentRequestsTitle,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (!isLoading) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    context.l10n.sentRequestsCount(sentList.length),
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: textSecondary,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    Flexible(
                      child: Builder(
                        builder: (context) {
                          if (isLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            );
                          }

                          if (sentList.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 48,
                                horizontal: 24,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.outbox_rounded,
                                      size: 48,
                                      color: isDark
                                          ? Colors.white30
                                          : Colors.black26,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      context.l10n.noSentRequestsYet,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            shrinkWrap: true,
                            itemCount: sentList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = sentList[index];
                              final toUid = (item['toUid'] ?? '').toString();
                              final avatarUrl =
                                  (item['toAvatarUrl'] ?? '').toString();
                              final avatarFrame =
                                  (item['toAvatarFrame'] ?? 'plain').toString();
                              final name =
                                  (item['toName'] ?? '').toString().trim();
                              final username =
                                  (item['toUsername'] ?? '').toString().trim();

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AvatarWithFrame(
                                      avatarUrl: avatarUrl,
                                      frameId: avatarFrame,
                                      size: 42,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            name.isEmpty
                                                ? context.l10n.user
                                                : name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (username.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '@$username',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Pending Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFA23D)
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        context.l10n.requestPending,
                                        style: const TextStyle(
                                          color: Color(0xFFFFA23D),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // Cancel Button
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            Theme.of(context).colorScheme.error,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () async {
                                        HapticFeedback.mediumImpact();
                                        await repo.cancelSentFriendRequest(
                                          myUid: uid,
                                          toUid: toUid,
                                        );
                                        if (context.mounted) {
                                          AppToast.show(
                                            context,
                                            context.l10n.requestCancelled,
                                            icon: Icons
                                                .check_circle_outline_rounded,
                                          );
                                        }
                                      },
                                      child: Text(
                                        context.l10n.cancelRequest,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

  Widget _buildSortRequestsButton(BuildContext context) {
    final isDark = AppColors.isDark(context);

    String sortLabel;
    switch (_requestSortOrder) {
      case 'newest':
        sortLabel = context.l10n.sortNewestFirst;
        break;
      case 'oldest':
        sortLabel = context.l10n.sortOldestFirst;
        break;
      default:
        sortLabel = context.l10n.sortDefault;
    }

    return PopupMenuButton<String>(
      initialValue: _requestSortOrder,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.border(context),
        ),
      ),
      color: isDark ? const Color(0xFF1E212B) : Colors.white,
      onSelected: (val) {
        HapticFeedback.selectionClick();
        setState(() {
          _requestSortOrder = val;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'default',
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: _requestSortOrder == 'default'
                    ? AppColors.primaryBlue
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.sortDefault,
                style: TextStyle(
                  fontWeight: _requestSortOrder == 'default'
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: _requestSortOrder == 'default'
                      ? AppColors.primaryBlue
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'newest',
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward_rounded,
                size: 16,
                color: _requestSortOrder == 'newest'
                    ? AppColors.primaryBlue
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.sortNewestFirst,
                style: TextStyle(
                  fontWeight: _requestSortOrder == 'newest'
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: _requestSortOrder == 'newest'
                      ? AppColors.primaryBlue
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'oldest',
          child: Row(
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: _requestSortOrder == 'oldest'
                    ? AppColors.primaryBlue
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.sortOldestFirst,
                style: TextStyle(
                  fontWeight: _requestSortOrder == 'oldest'
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: _requestSortOrder == 'oldest'
                      ? AppColors.primaryBlue
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E2B) : AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border(context),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              sortLabel,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().user?.uid;
    final repo = context.read<UserRepository>();
    final myShowActiveStatus = context.watch<LocalSettingsService>().showActiveStatus;
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

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
          stream: repo.streamFriends(uid),
          builder: (context, friendsSnapshot) {
            final allFriends = friendsSnapshot.data ?? [];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: repo.streamFriendRequests(uid),
              builder: (context, receivedSnapshot) {
                final receivedRequests = receivedSnapshot.data ?? [];
                final pendingCount = receivedRequests.length;

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: repo.streamSentFriendRequests(uid),
                  builder: (context, sentSnapshot) {
                    final sentRequests = sentSnapshot.data ?? [];

                    // Accurate search filter: Name & Username (Vietnamese normalized)
                    final filteredFriends = allFriends.where((item) {
                      final rawName = (item['name'] ?? '').toString();
                      final rawUsername = (item['username'] ?? '').toString();

                      if (_searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        final qNoDia = _removeVietnameseDiacritics(q);
                        final cleanQ = q.startsWith('@') ? q.substring(1) : q;
                        final cleanQNoDia = _removeVietnameseDiacritics(cleanQ);

                        final nameLower = rawName.toLowerCase();
                        final nameNoDia = _removeVietnameseDiacritics(rawName);

                        final userLower = rawUsername.toLowerCase();
                        final userNoDia =
                            _removeVietnameseDiacritics(rawUsername);

                        final matchName =
                            nameLower.contains(q) || nameNoDia.contains(qNoDia);
                        final matchUser = userLower.contains(cleanQ) ||
                            userNoDia.contains(cleanQNoDia);

                        if (!matchName && !matchUser) {
                          return false;
                        }
                      }

                      if (_activeTab == 'close') {
                        return item['isCloseFriend'] == true;
                      }

                      return true;
                    }).toList();

                    // Filter & Sort received requests when active tab is requests
                    List<Map<String, dynamic>> filteredRequests =
                        List.from(receivedRequests);

                    if (_searchQuery.isNotEmpty) {
                      final cleanQ =
                          _removeVietnameseDiacritics(_searchQuery);
                      filteredRequests = filteredRequests.where((req) {
                        final name = _removeVietnameseDiacritics(
                            (req['fromName'] ?? '').toString());
                        final username = _removeVietnameseDiacritics(
                            (req['fromUsername'] ?? '').toString());
                        return name.contains(cleanQ) ||
                            username.contains(cleanQ);
                      }).toList();
                    }

                    if (_requestSortOrder == 'newest') {
                      filteredRequests.sort((a, b) {
                        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        return bTime.compareTo(aTime);
                      });
                    } else if (_requestSortOrder == 'oldest') {
                      filteredRequests.sort((a, b) {
                        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        return aTime.compareTo(bTime);
                      });
                    }

                    String screenTitle;
                    if (_activeTab == 'requests') {
                      screenTitle =
                          '${context.l10n.friendRequests} ($pendingCount)';
                    } else if (_activeTab == 'close') {
                      final closeCount = allFriends
                          .where((f) => f['isCloseFriend'] == true)
                          .length;
                      screenTitle =
                          '${context.l10n.friendsTabClose} ($closeCount)';
                    } else {
                      screenTitle =
                          context.l10n.friendsCountTitle(allFriends.length);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Bar: Back Circle Button & + Tìm người mới
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
                              GestureDetector(
                                onTap: () => _openAddFriendScreen(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusPill,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryBlue
                                            .withValues(alpha: 0.30),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        context.l10n.findNewFriends,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
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

                        const SizedBox(height: 18),

                        // Title Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            screenTitle,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1B1E2B)
                                  : AppColors.card(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.border(context),
                                width: 1.2,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: context.l10n.searchInFriends,
                                hintStyle: TextStyle(
                                  color:
                                      textSecondary.withValues(alpha: 0.65),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: textSecondary.withValues(alpha: 0.70),
                                  size: 22,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: textSecondary,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Filter Tabs: Tất cả | ⭐ Bạn thân | Lời mời (N)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _buildFilterPill(
                                label: context.l10n.friendsTabAll,
                                isSelected: _activeTab == 'all',
                                onTap: () =>
                                    setState(() => _activeTab = 'all'),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterPill(
                                label: context.l10n.friendsTabClose,
                                leadingIcon: Icons.star_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                isSelected: _activeTab == 'close',
                                onTap: () =>
                                    setState(() => _activeTab = 'close'),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterPill(
                                label: context.l10n.friendsTabRequests,
                                badgeCount: pendingCount,
                                isSelected: _activeTab == 'requests',
                                onTap: () =>
                                    setState(() => _activeTab = 'requests'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // When in Requests Tab: Show Sub-Bar (View Sent Requests & Sort Menu)
                        if (_activeTab == 'requests')
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                // "Xem lời mời đã gửi" Button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showSentRequestsModal(context, uid),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E2235)
                                            : const Color(0xFFEFF6FF),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF2E3856)
                                              : const Color(0xFFBFDBFE),
                                          width: 1.1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.send_rounded,
                                            size: 15,
                                            color: isDark
                                                ? const Color(0xFF60A5FA)
                                                : const Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              context.l10n.viewSentRequests,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? const Color(0xFF93C5FD)
                                                    : const Color(0xFF1D4ED8),
                                              ),
                                            ),
                                          ),
                                          if (sentRequests.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF3B82F6)
                                                    : const Color(0xFF2563EB),
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                              ),
                                              child: Text(
                                                '${sentRequests.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Sort Menu Button
                                _buildSortRequestsButton(context),
                              ],
                            ),
                          ),

                        const SizedBox(height: 6),

                        // Content List: Requests or Friends
                        Expanded(
                          child: _activeTab == 'requests'
                              ? (filteredRequests.isEmpty
                                  ? _buildEmptyState(context)
                                  : ListView.separated(
                                      cacheExtent: 800,
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        4,
                                        20,
                                        24,
                                      ),
                                      itemCount: filteredRequests.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final req = filteredRequests[index];
                                        return _ReceivedRequestItemCard(
                                          item: req,
                                          onReject: () async {
                                            await repo.rejectFriendRequest(
                                              myUid: uid,
                                              fromUid: req['fromUid'],
                                            );
                                          },
                                          onAccept: () async {
                                            await repo.acceptFriendRequest(
                                              myUid: uid,
                                              requestData: req,
                                            );
                                          },
                                        );
                                      },
                                    ))
                              : (filteredFriends.isEmpty
                                  ? _buildEmptyState(context)
                                  : ListView.separated(
                                      cacheExtent: 800,
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        4,
                                        20,
                                        24,
                                      ),
                                      itemCount: filteredFriends.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final item = filteredFriends[index];

                                        final friendUid =
                                            (item['uid'] ?? '').toString();
                                        final friendName =
                                            (item['name'] ?? '').toString();
                                        final friendUsername =
                                            (item['username'] ?? '').toString();
                                        final avatarUrl =
                                            (item['avatarUrl'] ?? '').toString();
                                        final avatarFrame =
                                            (item['avatarFrame'] ?? 'plain')
                                                .toString();
                                        final isCloseFriend =
                                            item['isCloseFriend'] == true;
                                        final isOnline = myShowActiveStatus &&
                                            item['isOnline'] == true &&
                                            item['showActiveStatus'] != false;

                                        return _FriendCardItem(
                                          friendUid: friendUid,
                                          friendName: friendName.isEmpty
                                              ? 'Người dùng'
                                              : friendName,
                                          friendUsername: friendUsername,
                                          avatarUrl: avatarUrl,
                                          avatarFrame: avatarFrame,
                                          isCloseFriend: isCloseFriend,
                                          isOnline: isOnline,
                                          onOpenChat: () =>
                                              Navigator.pushNamed(
                                            context,
                                            RouteNames.chatConversation,
                                            arguments: {
                                              'friend':
                                                  UserModel.fromMap(item),
                                            },
                                          ),
                                          onToggleClose: () =>
                                              _toggleCloseFriend(
                                            myUid: uid,
                                            friendUid: friendUid,
                                            currentStatus: isCloseFriend,
                                            friendName: friendName,
                                          ),
                                          onOpenOptions: () =>
                                              _showFriendOptionsModal(
                                            context: context,
                                            myUid: uid,
                                            friendUid: friendUid,
                                            friendName: friendName,
                                            friendUsername: friendUsername,
                                            avatarUrl: avatarUrl,
                                            avatarFrame: avatarFrame,
                                            isCloseFriend: isCloseFriend,
                                          ),
                                        );
                                      },
                                    )),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? leadingIcon,
    Color? iconColor,
    int badgeCount = 0,
  }) {
    final isDark = AppColors.isDark(context);
    final selectedBg = AppColors.primaryBlue;
    final unselectedBg =
        isDark ? const Color(0xFF1B1E2B) : AppColors.card(context);
    final borderColor =
        isSelected ? Colors.transparent : AppColors.border(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 16,
                color: isSelected ? Colors.white : (iconColor ?? Colors.white),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : AppColors.textPrimary(context),
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark
                          ? const Color(0xFF162544)
                          : const Color(0xFFDBEAFE)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF1D4ED8)),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textSecondary = AppColors.textSecondary(context);

    Widget content;

    if (_searchQuery.isNotEmpty) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.noMatchingFriends,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
        ],
      );
    } else if (_activeTab == 'requests') {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 38,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.noFriendRequestsYet,
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle(context).copyWith(fontSize: 18.5),
          ),
        ],
      );
    } else if (_activeTab == 'close') {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star_outline_rounded,
            size: 46,
            color: Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.noCloseFriendsYet,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            context.l10n.noCloseFriendsSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBlue.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.group_outlined,
              size: 38,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.noFriends,
            style: AppTextStyles.pageTitle(context).copyWith(fontSize: 19),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.noFriendsSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: textSecondary,
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReceivedRequestItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Future<void> Function() onReject;
  final Future<void> Function() onAccept;

  const _ReceivedRequestItemCard({
    required this.item,
    required this.onReject,
    required this.onAccept,
  });

  @override
  State<_ReceivedRequestItemCard> createState() =>
      _ReceivedRequestItemCardState();
}

class _ReceivedRequestItemCardState extends State<_ReceivedRequestItemCard> {
  bool _rejectRunning = false;
  bool _acceptRunning = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    final item = widget.item;
    final avatarUrl = (item['fromAvatarUrl'] ?? '').toString();
    final avatarFrame = (item['fromAvatarFrame'] ?? 'plain').toString();
    final name = (item['fromName'] ?? '').toString().trim();
    final username = (item['fromUsername'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2B) : AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border(context),
          width: 1.1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AvatarWithFrame(
                avatarUrl: avatarUrl,
                frameId: avatarFrame,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name.isEmpty ? context.l10n.user : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: AsyncOutlinedButton(
                    locked: _acceptRunning,
                    onPressedAsync: widget.onReject,
                    onBusyChanged: (v) => setState(() => _rejectRunning = v),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF3F4F6),
                      side: BorderSide(
                        color: AppColors.border(context),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      context.l10n.decline,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: AsyncFilledButton(
                    locked: _rejectRunning,
                    onPressedAsync: widget.onAccept,
                    onBusyChanged: (v) => setState(() => _acceptRunning = v),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      context.l10n.accept,
                      style: const TextStyle(
                        fontSize: 14,
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
    );
  }
}

class _FriendCardItem extends StatelessWidget {
  final String friendUid;
  final String friendName;
  final String friendUsername;
  final String avatarUrl;
  final String avatarFrame;
  final bool isCloseFriend;
  final bool isOnline;
  final VoidCallback onOpenChat;
  final VoidCallback onToggleClose;
  final VoidCallback onOpenOptions;

  const _FriendCardItem({
    required this.friendUid,
    required this.friendName,
    required this.friendUsername,
    required this.avatarUrl,
    required this.avatarFrame,
    required this.isCloseFriend,
    required this.isOnline,
    required this.onOpenChat,
    required this.onToggleClose,
    required this.onOpenOptions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    final displayHandle = friendUsername.isNotEmpty
        ? '@$friendUsername'
        : '#${friendUid.length >= 8 ? friendUid.substring(0, 8).toUpperCase() : friendUid}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2B) : AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border(context),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          // Avatar with Frame & Conditional Online Status
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWithFrame(
                avatarUrl: avatarUrl,
                frameId: avatarFrame,
                size: 48,
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1B1E2B)
                            : AppColors.card(context),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF22C55E).withValues(alpha: 0.45),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Friend Name & Tag / Close Friend Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (friendUsername.isNotEmpty)
                      Flexible(
                        child: Text(
                          '@$friendUsername',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: Text(
                          displayHandle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    if (isCloseFriend) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2210)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(
                              alpha: isDark ? 0.35 : 0.50,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              context.l10n.closeFriendBadge,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFF92400E),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 2),

          // Direct Chat Button
          IconButton(
            onPressed: onOpenChat,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            padding: const EdgeInsets.all(5),
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),

          // Star Toggle Button
          IconButton(
            onPressed: onToggleClose,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            padding: const EdgeInsets.all(5),
            icon: Icon(
              isCloseFriend
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: isCloseFriend
                  ? const Color(0xFFF59E0B)
                  : textSecondary.withValues(alpha: 0.5),
              size: 22,
            ),
          ),

          // Menu Options Button (☰)
          IconButton(
            onPressed: onOpenOptions,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            padding: const EdgeInsets.all(5),
            icon: Icon(
              Icons.menu_rounded,
              color: textSecondary.withValues(alpha: 0.8),
              size: 22,
            ),
          ),
        ],
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