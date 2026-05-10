import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/feed_controller.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool loaded = false;
  String selectedUserId = 'all';

  final PageController _pageController = PageController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null) {
        context.read<FeedController>().load(uid);
      }

      loaded = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openGallery({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required _FeedPalette palette,
  }) async {
    final selectedIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => FeedGalleryScreen(
          transactions: transactions,
          palette: palette,
        ),
      ),
    );

    if (selectedIndex != null && _pageController.hasClients) {
      _pageController.jumpToPage(selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();
    final auth = context.read<AuthController>();
    final myUid = auth.user?.uid;
    final palette = _FeedPalette.of(context);

    if (myUid == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: Text(context.l10n.noUser),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: FutureBuilder<UserModel?>(
          future: context.read<UserRepository>().getUserProfile(myUid),
          builder: (context, myProfileSnapshot) {
            final myProfile = myProfileSnapshot.data;

            return StreamBuilder<List<String>>(
              stream: context.read<UserRepository>().streamFriendIds(myUid),
              builder: (context, friendIdSnapshot) {
                final friendIds = friendIdSnapshot.data ?? [];

                return FutureBuilder<List<UserModel>>(
                  future: _loadFriendProfiles(context, friendIds),
                  builder: (context, friendProfileSnapshot) {
                    final friendProfiles = friendProfileSnapshot.data ?? [];

                    final validSelectableIds = <String>{
                      'all',
                      'me',
                      ...friendProfiles.map((e) => e.uid),
                    };

                    if (!validSelectableIds.contains(selectedUserId)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            selectedUserId = 'all';
                          });
                        }
                      });
                    }

                    final filteredTransactions = _filterTransactions(
                      allTransactions: feed.feedTransactions,
                      myUid: myUid,
                      selectedUserId: selectedUserId,
                    );

                    if (feed.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (feed.errorMessage != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            context.l10n.loadFeedError(feed.errorMessage!),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(context).copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }

                    if (feed.feedTransactions.isEmpty) {
                      return _FeedEmptyState(
                        palette: palette,
                      );
                    }

                    if (filteredTransactions.isEmpty) {
                      return _FilteredEmptyFeed(
                        selectedUserId: selectedUserId,
                        friendProfiles: friendProfiles,
                        myProfile: myProfile,
                        selectedUserIdValue: selectedUserId,
                        feedTransactions: filteredTransactions,
                        palette: palette,
                        onSelected: (value) {
                          setState(() {
                            selectedUserId = value;
                          });
                        },
                      );
                    }

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: PageView.builder(
                            controller: _pageController,
                            scrollDirection: Axis.vertical,
                            allowImplicitScrolling: true,
                            itemCount: filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final tx = filteredTransactions[index];

                              return _FeedPostPage(
                                transaction: tx,
                                palette: palette,
                              );
                            },
                          ),
                        ),

                        Positioned(
                          top: 8,
                          left: 14,
                          right: 14,
                          child: SafeArea(
                            bottom: false,
                            child: _FeedHeader(
                              myProfile: myProfile,
                              friendProfiles: friendProfiles,
                              selectedUserId: selectedUserId,
                              feedTransactions: filteredTransactions,
                              onOpenGallery: () {
                                _openGallery(
                                  context: context,
                                  transactions: filteredTransactions,
                                  palette: palette,
                                );
                              },
                              onCaptureTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.addTransaction,
                                );
                              },
                              onSelected: (value) {
                                setState(() {
                                  selectedUserId = value;
                                });
                              },
                              palette: palette,
                            ),
                          ),
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

  Future<List<UserModel>> _loadFriendProfiles(
      BuildContext context,
      List<String> friendIds,
      ) async {
    final repo = context.read<UserRepository>();
    final futures = friendIds.map((id) => repo.getUserProfile(id)).toList();
    final results = await Future.wait(futures);

    return results.whereType<UserModel>().toList();
  }

  List<TransactionModel> _filterTransactions({
    required List<TransactionModel> allTransactions,
    required String myUid,
    required String selectedUserId,
  }) {
    if (selectedUserId == 'all') {
      return allTransactions;
    }

    if (selectedUserId == 'me') {
      return allTransactions.where((e) => e.userId == myUid).toList();
    }

    return allTransactions.where((e) => e.userId == selectedUserId).toList();
  }
}

class _FilteredEmptyFeed extends StatelessWidget {
  final String selectedUserId;
  final List<UserModel> friendProfiles;
  final UserModel? myProfile;
  final String selectedUserIdValue;
  final List<TransactionModel> feedTransactions;
  final _FeedPalette palette;
  final ValueChanged<String> onSelected;

  const _FilteredEmptyFeed({
    required this.selectedUserId,
    required this.friendProfiles,
    required this.myProfile,
    required this.selectedUserIdValue,
    required this.feedTransactions,
    required this.palette,
    required this.onSelected,
  });

  String _emptyFilterText(BuildContext context) {
    if (selectedUserId == 'me') {
      return context.l10n.youHaveNoPosts;
    }

    if (selectedUserId == 'all') {
      return context.l10n.noPostsYet;
    }

    UserModel? selectedFriend;

    for (final friend in friendProfiles) {
      if (friend.uid == selectedUserId) {
        selectedFriend = friend;
        break;
      }
    }

    final name = selectedFriend?.name.trim().isNotEmpty == true
        ? selectedFriend!.name.trim()
        : context.l10n.someone;

    return context.l10n.userHasNoPosts(name);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dynamic_feed_outlined,
                    size: 56,
                    color: palette.accent.withOpacity(0.8),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _emptyFilterText(context),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle(context).copyWith(
                      color: palette.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 14,
          right: 14,
          child: SafeArea(
            bottom: false,
            child: _FeedHeader(
              myProfile: myProfile,
              friendProfiles: friendProfiles,
              selectedUserId: selectedUserIdValue,
              feedTransactions: feedTransactions,
              onOpenGallery: () {},
              onCaptureTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.addTransaction,
                );
              },
              onSelected: onSelected,
              palette: palette,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  final _FeedPalette palette;

  const _FeedEmptyState({
    required this.palette,
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
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent.withOpacity(0.16),
              ),
              child: Icon(
                Icons.dynamic_feed_outlined,
                size: 54,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.emptyFeedFriends,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context).copyWith(
                color: palette.textPrimary,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.emptyFeedFriendsSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: palette.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedPostPage extends StatelessWidget {
  final TransactionModel transaction;
  final _FeedPalette palette;

  const _FeedPostPage({
    required this.transaction,
    required this.palette,
  });

  String _localizedCategoryLabel(BuildContext context, String category) {
    final l10n = context.l10n;
    switch (category.trim()) {
      case 'Ăn uống':
      case 'Food':
        return l10n.food;
      case 'Mua sắm':
      case 'Shopping':
        return l10n.shopping;
      case 'Đi lại':
      case 'Transport':
        return l10n.transport;
      case 'Giải trí':
      case 'Entertainment':
        return l10n.entertainment;
      case 'Học tập':
      case 'Education':
        return l10n.education;
      case 'Lương':
      case 'Salary':
        return l10n.salary;
      case 'Quà tặng':
      case 'Gift':
        return l10n.gift;
      case 'Khác':
      case 'Other':
        return l10n.other;
      default:
        return BudgetNameLocalizer.display(context, category);
    }
  }

  String _formatFeedTime(BuildContext context, DateTime createdAt) {
    final now = DateTime.now();

    final safeCreatedAt = createdAt.isAfter(now) ? now : createdAt;
    final diff = now.difference(safeCreatedAt);

    if (diff.inSeconds < 60) {
      return context.l10n.justNow;
    }

    if (diff.inMinutes < 60) {
      return context.l10n.minutesAgo(diff.inMinutes);
    }

    if (diff.inHours < 24) {
      return context.l10n.hoursAgo(diff.inHours);
    }

    if (diff.inDays <= 7) {
      return context.l10n.daysAgo(diff.inDays);
    }

    if (now.year == createdAt.year) {
      return context.l10n.dateAt('${createdAt.day} thg ${createdAt.month}');
    }

    return context.l10n.dateAt(
        '${createdAt.day} thg ${createdAt.month}, ${createdAt.year}');
  }

  @override
  Widget build(BuildContext context) {
    final viewerUid = context.read<AuthController>().user?.uid;
    final isOwner = viewerUid == transaction.userId;
    final currency = context.watch<ProfileController>().currency;
    final localizedCategory =
        _localizedCategoryLabel(context, transaction.category);

    final amountText = AppCurrencyFormatter.formatFromVnd(
      amountVnd: transaction.amount,
      currency: currency,
    );

    return FutureBuilder<UserModel?>(
      future: context.read<UserRepository>().getUserProfile(transaction.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final imageSize = maxWidth - 28;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.topGradient,
                    palette.bottomGradient,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 108),
                child: Column(
                  children: [
                    const SizedBox(height: 160),
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: _MainSquarePost(
                        transaction: transaction,
                        palette: palette,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _UploaderInfo(
                      user: user,
                      timeText: _formatFeedTime(context, transaction.createdAt),
                      palette: palette,
                      isPrivate: transaction.privacy == 'private',
                      isOwner: isOwner,
                    ),
                    if (transaction.note.trim().isNotEmpty && isOwner) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          transaction.note.trim(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySecondary(context).copyWith(
                            color: palette.textSecondary,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    if (isOwner) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '${transaction.type == 'expense' ? '-' : '+'}$amountText • $localizedCategory',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: transaction.type == 'expense'
                                ? AppColors.expense
                                : AppColors.income,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FeedHeader extends StatefulWidget {
  final UserModel? myProfile;
  final List<UserModel> friendProfiles;
  final String selectedUserId;
  final List<TransactionModel> feedTransactions;
  final VoidCallback onOpenGallery;
  final VoidCallback onCaptureTap;
  final ValueChanged<String> onSelected;
  final _FeedPalette palette;

  const _FeedHeader({
    super.key,
    required this.myProfile,
    required this.friendProfiles,
    required this.selectedUserId,
    required this.feedTransactions,
    required this.onOpenGallery,
    required this.onCaptureTap,
    required this.onSelected,
    required this.palette,
  });

  @override
  State<_FeedHeader> createState() => _FeedHeaderState();
}

class _FeedHeaderState extends State<_FeedHeader> {
  bool _menuOpen = false;

  String _shortName(
      BuildContext context,
      String value, {
        int maxLength = 12,
      }) {
    final name = value.trim();

    if (name.isEmpty) return context.l10n.friendsTitle;

    if (name.length <= maxLength) {
      return name;
    }

    return '${name.substring(0, maxLength).trimRight()}...';
  }

  String _displayName(UserModel user) {
    return user.name.isNotEmpty ? user.name : user.username;
  }

  String _selectedLabel(BuildContext context) {
    if (widget.selectedUserId == 'all') return context.l10n.everyone;
    if (widget.selectedUserId == 'me') return context.l10n.you;

    UserModel? selectedFriend;

    for (final friend in widget.friendProfiles) {
      if (friend.uid == widget.selectedUserId) {
        selectedFriend = friend;
        break;
      }
    }

    if (selectedFriend == null) return context.l10n.everyone;

    return _shortName(
      context,
      _displayName(selectedFriend),
      maxLength: 10,
    );
  }

  List<Widget> _buildSelectedLeading() {
    if (widget.selectedUserId == 'all') {
      return [
        Icon(
          Icons.groups_2_outlined,
          color: widget.palette.textPrimary,
          size: 18,
        ),
      ];
    }

    if (widget.selectedUserId == 'me') {
      return [
        Icon(
          Icons.person_outline_rounded,
          color: widget.palette.textPrimary,
          size: 18,
        ),
      ];
    }

    UserModel? selectedFriend;

    for (final friend in widget.friendProfiles) {
      if (friend.uid == widget.selectedUserId) {
        selectedFriend = friend;
        break;
      }
    }

    if (selectedFriend == null) {
      return [
        Icon(
          Icons.groups_2_outlined,
          color: widget.palette.textPrimary,
          size: 18,
        ),
      ];
    }

    return [
      CircleAvatar(
        radius: 10,
        backgroundColor: widget.palette.avatarBackground,
        backgroundImage: selectedFriend.avatarUrl.isNotEmpty
            ? NetworkImage(selectedFriend.avatarUrl)
            : null,
        child: selectedFriend.avatarUrl.isEmpty
            ? const Icon(Icons.person, size: 12)
            : null,
      ),
    ];
  }

  Widget _menuRow({
    required Widget leading,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Center(child: leading),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: widget.palette.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: widget.palette.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: widget.palette.pillBorder,
    );
  }

  void _selectUser(String value) {
    setState(() {
      _menuOpen = false;
    });

    widget.onSelected(value);
  }

  Widget _buildDropdownMenu(List<UserModel> sortedFriends) {
    final screenSize = MediaQuery.of(context).size;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: screenSize.width * 0.68,
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.42,
            ),
            decoration: BoxDecoration(
              color: widget.palette.pillBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.palette.pillBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    AppColors.isDark(context) ? 0.24 : 0.10,
                  ),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuRow(
                    leading: Icon(
                      Icons.groups_2_outlined,
                      size: 17,
                      color: widget.palette.textPrimary,
                    ),
                    label: context.l10n.everyone,
                    onTap: () => _selectUser('all'),
                  ),
                  _menuDivider(),
                  _menuRow(
                    leading: Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: widget.palette.textPrimary,
                    ),
                    label: context.l10n.you,
                    onTap: () => _selectUser('me'),
                  ),
                  if (sortedFriends.isNotEmpty) _menuDivider(),
                  ...List.generate(sortedFriends.length, (index) {
                    final friend = sortedFriends[index];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _menuRow(
                          leading: CircleAvatar(
                            radius: 11,
                            backgroundColor: widget.palette.avatarBackground,
                            backgroundImage: friend.avatarUrl.isNotEmpty
                                ? NetworkImage(friend.avatarUrl)
                                : null,
                            child: friend.avatarUrl.isEmpty
                                ? const Icon(Icons.person, size: 11)
                                : null,
                          ),
                          label: _shortName(
                            context,
                            _displayName(friend),
                            maxLength: 14,
                          ),
                          onTap: () => _selectUser(friend.uid),
                        ),
                        if (index != sortedFriends.length - 1) _menuDivider(),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedFriends = [...widget.friendProfiles]
      ..sort((a, b) {
        final aName = a.name.isNotEmpty ? a.name : a.username;
        final bName = b.name.isNotEmpty ? b.name : b.username;
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _HeaderCircleButton(
                icon: Icons.grid_view_rounded,
                palette: widget.palette,
                onTap:
                widget.feedTransactions.isEmpty ? null : widget.onOpenGallery,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _menuOpen = !_menuOpen;
                  });
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.46,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.palette.pillBackground,
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      border: Border.all(
                        color: widget.palette.pillBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._buildSelectedLeading(),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _selectedLabel(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              color: widget.palette.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _menuOpen ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: widget.palette.textPrimary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              _HeaderCircleButton(
                icon: Icons.add_a_photo_rounded,
                palette: widget.palette,
                onTap: widget.onCaptureTap,
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            );
          },
          child: _menuOpen
              ? Padding(
            key: const ValueKey('feed-dropdown-open'),
            padding: const EdgeInsets.only(top: 12),
            child: _buildDropdownMenu(sortedFriends),
          )
              : const SizedBox(
            key: ValueKey('feed-dropdown-closed'),
          ),
        ),
      ],
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final _FeedPalette palette;

  const _HeaderCircleButton({
    required this.icon,
    required this.palette,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: disabled ? 0.45 : 1,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.glassButton,
            border: Border.all(
              color: palette.glassBorder,
            ),
          ),
          child: Icon(
            icon,
            color: palette.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _MainSquarePost extends StatelessWidget {
  final TransactionModel transaction;
  final _FeedPalette palette;

  const _MainSquarePost({
    required this.transaction,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final captionText = transaction.caption.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(38),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (transaction.isVideo && transaction.playableVideoUrl.isNotEmpty)
            _FeedMutedVideoPlayer(
              videoUrl: transaction.playableVideoUrl,
              thumbnailUrl: transaction.displayImageUrl,
              category: transaction.category,
              categoryIconCodePoint: transaction.categoryIconCodePoint,
              categoryColorHex: transaction.categoryColorHex,
            )
          else
            TransactionMomentImage(
              imageUrl: transaction.displayImageUrl,
              category: transaction.category,
              categoryIconCodePoint: transaction.categoryIconCodePoint,
              categoryColorHex: transaction.categoryColorHex,
              caption: null,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(38),
              // isVideo: transaction.isVideo,
              // showVideoBadge: false,
            ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.34),
                  ],
                ),
              ),
            ),
          ),

          if (captionText.isNotEmpty)
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 315,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.34),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.14),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    captionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedMutedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final String category;
  final int? categoryIconCodePoint;
  final String? categoryColorHex;

  const _FeedMutedVideoPlayer({
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.category,
    this.categoryIconCodePoint,
    this.categoryColorHex,
  });

  @override
  State<_FeedMutedVideoPlayer> createState() => _FeedMutedVideoPlayerState();
}

class _FeedMutedVideoPlayerState extends State<_FeedMutedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupVideo();
  }

  @override
  void didUpdateWidget(covariant _FeedMutedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeVideo();
      _setupVideo();
    }
  }

  Future<void> _setupVideo() async {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );

    _controller = controller;

    try {
      await controller.setLooping(true);
      await controller.setVolume(0);

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isReady = true;
      });

      await controller.play();
    } catch (e) {
      debugPrint('Feed video init error: $e');
    }
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
    _isReady = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        TransactionMomentImage(
          imageUrl: widget.thumbnailUrl,
          category: widget.category,
          categoryIconCodePoint: widget.categoryIconCodePoint,
          categoryColorHex: widget.categoryColorHex,
          caption: null,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(38),
          isVideo: true,
          showVideoBadge: false,
        ),

        if (_isReady && controller != null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),

        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.02),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploaderInfo extends StatelessWidget {
  final UserModel? user;
  final String timeText;
  final _FeedPalette palette;
  final bool isPrivate;
  final bool isOwner;

  const _UploaderInfo({
    required this.user,
    required this.timeText,
    required this.palette,
    required this.isPrivate,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarUrl ?? '';

    final username = isOwner
        ? context.l10n.you
        : (user?.username.isNotEmpty == true
        ? user!.username
        : (user?.name ?? context.l10n.friendsTitle));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isOwner) ...[
          CircleAvatar(
            radius: 18,
            backgroundColor: palette.avatarBackground,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Icon(
              Icons.person,
              color: palette.textPrimary,
              size: 18,
            )
                : null,
          ),
          const SizedBox(width: 10),
        ],
        Text(
          username,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          timeText,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isPrivate) ...[
          const SizedBox(width: 10),
          Icon(
            Icons.lock_rounded,
            size: 17,
            color: palette.textSecondary,
          ),
        ],
      ],
    );
  }
}

class FeedGalleryScreen extends StatelessWidget {
  final List<TransactionModel> transactions;
  final _FeedPalette palette;

  const FeedGalleryScreen({
    super.key,
    required this.transactions,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final imageEntries = transactions.asMap().entries.toList();

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: imageEntries.isEmpty
                  ? Center(
                child: Text(
                  context.l10n.noPhotosInFeed,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
                  : GridView.builder(
                cacheExtent: 700,
                padding: const EdgeInsets.fromLTRB(10, 86, 10, 24),
                itemCount: imageEntries.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 7,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, gridIndex) {
                  final originalIndex = imageEntries[gridIndex].key;
                  final tx = imageEntries[gridIndex].value;

                  return RepaintBoundary(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context, originalIndex);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final size = constraints.maxWidth;

                                  return TransactionMomentImage(
                                    imageUrl: tx.displayImageUrl,
                                    category: tx.category,
                                    categoryIconCodePoint: tx.categoryIconCodePoint,
                                    categoryColorHex: tx.categoryColorHex,
                                    caption: null,
                                    width: size,
                                    height: size,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(18),
                                    isVideo: tx.isVideo,
                                    showVideoBadge: false,
                                  );
                                },
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.02),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.42),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (tx.caption.trim().isNotEmpty)
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Text(
                                  tx.caption.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
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
                },
              ),
            ),
            Positioned(
              top: 8,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  _HeaderCircleButton(
                    icon: Icons.chevron_left_rounded,
                    palette: palette,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: palette.pillBackground,
                          borderRadius:
                          BorderRadius.circular(AppSizes.radiusPill),
                          border: Border.all(color: palette.pillBorder),
                        ),
                        child: Text(
                          context.l10n.allPhotos,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 56),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedPalette {
  final Color background;
  final Color topGradient;
  final Color bottomGradient;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color pillBackground;
  final Color pillBorder;
  final Color glassButton;
  final Color glassBorder;
  final Color imageFallback;
  final Color captionBackground;
  final Color avatarBackground;

  const _FeedPalette({
    required this.background,
    required this.topGradient,
    required this.bottomGradient,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.pillBackground,
    required this.pillBorder,
    required this.glassButton,
    required this.glassBorder,
    required this.imageFallback,
    required this.captionBackground,
    required this.avatarBackground,
  });

  factory _FeedPalette.of(BuildContext context) {
    final isDark = AppColors.isDark(context);

    if (isDark) {
      return _FeedPalette(
        background: AppColors.darkBackground,
        topGradient: const Color(0xFF141722),
        bottomGradient: AppColors.darkBackground,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        accent: AppColors.primaryBlue,
        pillBackground: Colors.white.withOpacity(0.08),
        pillBorder: Colors.white.withOpacity(0.05),
        glassButton: Colors.white.withOpacity(0.08),
        glassBorder: Colors.white.withOpacity(0.05),
        imageFallback: AppColors.darkSurface,
        captionBackground: const Color(0xFF8A4D16).withOpacity(0.90),
        avatarBackground: Colors.white.withOpacity(0.10),
      );
    }

    return _FeedPalette(
      background: AppColors.lightBackground,
      topGradient: const Color(0xFFF5F2F6),
      bottomGradient: AppColors.lightBackground,
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      accent: AppColors.primaryBlue,
      pillBackground: Colors.white.withOpacity(0.92),
      pillBorder: Colors.black.withOpacity(0.06),
      glassButton: Colors.white.withOpacity(0.92),
      glassBorder: Colors.black.withOpacity(0.06),
      imageFallback: AppColors.lightSurface,
      captionBackground: const Color(0xFF8A4D16).withOpacity(0.90),
      avatarBackground: Colors.black.withOpacity(0.06),
    );
  }
}