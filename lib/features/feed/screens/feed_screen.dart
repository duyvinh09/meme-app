import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/post_reaction_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/widgets/avatar_with_frame.dart';
import '../../chat/controllers/chat_controller.dart';
import '../widgets/reaction_flying_animator.dart';
import '../widgets/feed_reaction_input_bar.dart';
import '../widgets/post_activity_bar.dart';
import '../widgets/new_post_floating_banner.dart';
import '../controllers/feed_controller.dart';

class FeedScreen extends StatefulWidget {
  final bool isActive;

  const FeedScreen({
    super.key,
    this.isActive = true,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool loaded = false;
  String selectedUserId = 'all';
  bool _isFilterMenuOpen = false;
  int _currentPageIndex = 0;
  String? _topPostId;
  int _newPostsCount = 0;

  final PageController _pageController = PageController();
  final GlobalKey<ReactionFlyingOverlayState> _flyingOverlayKey =
      GlobalKey<ReactionFlyingOverlayState>();

  final Set<String> _viewedPostIds = {};
  final Set<String> _animatedOwnerPostIds = {};
  final Set<String> _knownReactionIds = {};
  final math.Random _random = math.Random();

  StreamSubscription<List<PostReactionModel>>? _currentPostReactionsSub;
  String? _subscribedPostId;
  Size _screenSize = Size.zero;

  @override
  void didUpdateWidget(covariant FeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_isFilterMenuOpen) {
        setState(() {
          _isFilterMenuOpen = false;
        });
      }
    }
  }

  void _recordViewIfNeeded(TransactionModel tx) {
    final authUser = context.read<AuthController>().user;
    final myUid = authUser?.uid;

    if (myUid == null) return;

    if (tx.userId != myUid) {
      if (!_viewedPostIds.contains(tx.id)) {
        _viewedPostIds.add(tx.id);

        final profile = context.read<ProfileController>().user;
        final myName = (profile?.name.trim().isNotEmpty == true)
            ? profile!.name.trim()
            : (profile?.username.trim().isNotEmpty == true
                ? profile!.username.trim()
                : (authUser?.displayName?.trim().isNotEmpty == true
                    ? authUser!.displayName!.trim()
                    : 'Bạn'));
        final myAvatar = profile?.avatarUrl ?? '';
        final myFrame = profile?.avatarFrame ?? 'default';

        context.read<ChatController>().recordPostView(
          postId: tx.id,
          userId: myUid,
          userName: myName,
          userAvatar: myAvatar,
          userFrame: myFrame,
        );
      }
    }
  }

  void _updateActivePostReactionSubscription(TransactionModel? currentTx, String myUid) {
    if (currentTx == null || currentTx.userId != myUid) {
      _currentPostReactionsSub?.cancel();
      _currentPostReactionsSub = null;
      _subscribedPostId = null;
      return;
    }

    if (_subscribedPostId == currentTx.id) return;
    _subscribedPostId = currentTx.id;

    _currentPostReactionsSub?.cancel();
    final bool isFirstViewOfThisPost = !_animatedOwnerPostIds.contains(currentTx.id);

    _currentPostReactionsSub = context
        .read<ChatController>()
        .postReactionsStream(currentTx.id)
        .listen((reactions) {
      if (!mounted || reactions.isEmpty) return;

      final screenSize = _screenSize;

      if (isFirstViewOfThisPost && !_animatedOwnerPostIds.contains(currentTx.id)) {
        _animatedOwnerPostIds.add(currentTx.id);

        for (final r in reactions) {
          _knownReactionIds.add(r.id);
        }

        // Animate up to the 3 most recent unique emojis falling down
        final recentEmojis = reactions.reversed.map((r) => r.emoji).toSet().take(3).toList();
        for (int i = 0; i < recentEmojis.length; i++) {
          Future.delayed(Duration(milliseconds: 200 + i * 350), () {
            if (mounted) {
              _flyingOverlayKey.currentState?.triggerReaction(
                recentEmojis[i],
                originOffset: Offset(screenSize.width / 2 + (i - 1) * 45, 75),
                isFalling: true,
                particleCount: 12,
              );
            }
          });
        }
      } else {
        // Real-time reactions arriving while user is looking at their post
        final newReactions = reactions.where((r) => !_knownReactionIds.contains(r.id)).toList();
        for (final r in newReactions) {
          _knownReactionIds.add(r.id);
          _flyingOverlayKey.currentState?.triggerReaction(
            r.emoji,
            originOffset: Offset(screenSize.width / 2 + (_random.nextDouble() - 0.5) * 80, 75),
            isFalling: true,
            particleCount: 14,
          );
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.sizeOf(context);

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
    _currentPostReactionsSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openGallery({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required _FeedPalette palette,
  }) async {
    if (_isFilterMenuOpen) {
      setState(() {
        _isFilterMenuOpen = false;
      });
    }

    final selectedIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => FeedGalleryScreen(
          transactions: transactions,
          palette: palette,
        ),
      ),
    );

    if (mounted && _isFilterMenuOpen) {
      setState(() {
        _isFilterMenuOpen = false;
      });
    }

    if (selectedIndex != null && _pageController.hasClients) {
      _pageController.jumpToPage(selectedIndex);
    }
  }

  void _changeFilter(String value) {
    setState(() {
      selectedUserId = value;
      _currentPageIndex = 0;
      _newPostsCount = 0;
      _topPostId = null;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.sizeOf(context);
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
      body: ReactionFlyingOverlay(
        key: _flyingOverlayKey,
        child: SafeArea(
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
                        onSelected: _changeFilter,
                      );
                    }

                    final safeIndex = _currentPageIndex.clamp(
                      0,
                      filteredTransactions.isEmpty ? 0 : filteredTransactions.length - 1,
                    );
                    final currentTransaction = filteredTransactions.isNotEmpty
                        ? filteredTransactions[safeIndex]
                        : null;
                    final isCurrentPostOwner = currentTransaction != null &&
                        currentTransaction.userId == myUid;

                    // Handle jump to tagged post if opened via mention notification
                    final targetPostId = feed.targetPostId;
                    if (targetPostId != null && targetPostId.isNotEmpty) {
                      if (selectedUserId != 'all') {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              selectedUserId = 'all';
                            });
                          }
                        });
                      }
                      if (filteredTransactions.isNotEmpty) {
                        final targetIdx = filteredTransactions.indexWhere((tx) => tx.id == targetPostId);
                        if (targetIdx != -1) {
                          feed.targetPostId = null;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            if (_pageController.hasClients) {
                              _pageController.jumpToPage(targetIdx);
                              setState(() {
                                _currentPageIndex = targetIdx;
                              });
                            } else {
                              Future.delayed(const Duration(milliseconds: 150), () {
                                if (mounted && _pageController.hasClients) {
                                  _pageController.jumpToPage(targetIdx);
                                  setState(() {
                                    _currentPageIndex = targetIdx;
                                  });
                                }
                              });
                            }
                          });
                        }
                      }
                    }

                    if (filteredTransactions.isNotEmpty) {
                      final currentTopId = filteredTransactions.first.id;
                      final isTopPostMine = filteredTransactions.first.userId == myUid;

                      if (_topPostId == null) {
                        _topPostId = currentTopId;
                      } else if (_topPostId != currentTopId) {
                        if (isTopPostMine) {
                          // When user uploads a post themselves, do NOT show popup,
                          // update top post and immediately jump to page 0 to show it
                          _topPostId = currentTopId;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              if (_newPostsCount != 0) {
                                setState(() {
                                  _newPostsCount = 0;
                                });
                              }
                              if (_currentPageIndex != 0 && _pageController.hasClients) {
                                _pageController.jumpToPage(0);
                                setState(() {
                                  _currentPageIndex = 0;
                                });
                              }
                            }
                          });
                        } else if (_currentPageIndex > 0) {
                          final oldTopIndex = filteredTransactions.indexWhere(
                            (tx) => tx.id == _topPostId,
                          );
                          final count = oldTopIndex > 0 ? oldTopIndex : 1;
                          if (count != _newPostsCount) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _newPostsCount = count;
                                });
                              }
                            });
                          }
                        } else {
                          _topPostId = currentTopId;
                          if (_newPostsCount != 0) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _newPostsCount = 0;
                                });
                              }
                            });
                          }
                        }
                      }
                    }

                    if (currentTransaction != null &&
                        _subscribedPostId != currentTransaction.id) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _recordViewIfNeeded(currentTransaction);
                          _updateActivePostReactionSubscription(currentTransaction, myUid);
                        }
                      });
                    }

                    final barBottomOffset =
                        (_screenSize.height < 740) ? 104.0 : 106.0;

                    return Stack(
                      children: [
                          Positioned.fill(
                            child: PageView.builder(
                              key: ValueKey('feed_pageview_$selectedUserId'),
                              controller: _pageController,
                              scrollDirection: Axis.vertical,
                              allowImplicitScrolling: true,
                              itemCount: filteredTransactions.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPageIndex = index;
                                  if (index == 0) {
                                    _newPostsCount = 0;
                                    _topPostId = filteredTransactions.isNotEmpty
                                        ? filteredTransactions.first.id
                                        : null;
                                  }
                                });
                                if (index >= 0 && index < filteredTransactions.length) {
                                  final activeTx = filteredTransactions[index];
                                  _recordViewIfNeeded(activeTx);
                                  _updateActivePostReactionSubscription(activeTx, myUid);
                                }
                              },
                              itemBuilder: (context, index) {
                                final tx = filteredTransactions[index];

                                return _FeedPostPage(
                                  transaction: tx,
                                  palette: palette,
                                );
                              },
                            ),
                          ),

                          // Floating Dropdown Banner for New Posts (Slide-down under dropdown header)
                          Positioned(
                            top: 72.0,
                            left: 0,
                            right: 0,
                            child: SafeArea(
                              bottom: false,
                              child: NewPostFloatingBanner(
                                newPostsCount: _newPostsCount,
                                onTap: () {
                                  _pageController.animateToPage(
                                    0,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                  );
                                  setState(() {
                                    _newPostsCount = 0;
                                    _topPostId = filteredTransactions.isNotEmpty
                                        ? filteredTransactions.first.id
                                        : null;
                                  });
                                },
                              ),
                            ),
                          ),

                          // Fixed Global Floating Bar (Own Post: PostActivityBar | Friend Post: FeedReactionInputBar)
                          if (currentTransaction != null)
                            Positioned(
                              bottom: barBottomOffset,
                              left: 16,
                              right: 16,
                              child: SafeArea(
                                top: false,
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 480),
                                    child: isCurrentPostOwner
                                        ? (currentTransaction.privacy != 'private'
                                            ? PostActivityBar(
                                                key: ValueKey('activity_bar_${currentTransaction.id}'),
                                                transaction: currentTransaction,
                                                isDark: AppColors.isDark(context),
                                              )
                                            : const SizedBox.shrink())
                                        : FeedReactionInputBar(
                                            key: ValueKey('feed_bar_${currentTransaction.id}'),
                                            isDark: AppColors.isDark(context),
                                            onOpenChat: () async {
                                              if (_isFilterMenuOpen) {
                                                setState(() {
                                                  _isFilterMenuOpen = false;
                                                });
                                              }
                                              UserModel? targetUser = friendProfiles
                                                  .where((u) => u.uid == currentTransaction.userId)
                                                  .firstOrNull;
                                              targetUser ??= await context
                                                  .read<UserRepository>()
                                                  .getUserProfile(currentTransaction.userId);
                                              if (targetUser != null && context.mounted) {
                                                Navigator.pushNamed(
                                                  context,
                                                  RouteNames.chatConversation,
                                                  arguments: {
                                                    'friend': targetUser,
                                                    'initialPostReply': currentTransaction,
                                                  },
                                                );
                                              }
                                            },
                                            onSelectEmoji: (emoji) {
                                              final authUser = context.read<AuthController>().user;
                                              final myUid = authUser?.uid ?? '';
                                              final profile = context.read<ProfileController>().user;
                                              final myName = (profile?.name.trim().isNotEmpty == true)
                                                  ? profile!.name.trim()
                                                  : (profile?.username.trim().isNotEmpty == true
                                                      ? profile!.username.trim()
                                                      : (authUser?.displayName?.trim().isNotEmpty == true
                                                          ? authUser!.displayName!.trim()
                                                          : 'Bạn'));
                                              final myAvatar = profile?.avatarUrl ?? '';

                                              final screenSize = _screenSize;
                                              final originY = screenSize.height - barBottomOffset - 27.0;

                                              HapticFeedback.mediumImpact();
                                              _flyingOverlayKey.currentState?.triggerReaction(
                                                emoji,
                                                originOffset: Offset(
                                                  screenSize.width / 2,
                                                  originY,
                                                ),
                                              );

                                              context.read<ChatController>().sendPostReaction(
                                                postId: currentTransaction.id,
                                                postOwnerId: currentTransaction.userId,
                                                myUid: myUid,
                                                userName: myName,
                                                userAvatar: myAvatar,
                                                emoji: emoji,
                                                postImageUrl: currentTransaction.displayImageUrl,
                                                postCaption: currentTransaction.caption,
                                                postCreatedAt: currentTransaction.createdAt,
                                              );
                                            },
                                          ),
                                  ),
                                ),
                              ),
                            ),

                          // Blurred Backdrop Barrier when dropdown is open (covers posts, activity bar & message input bar)
                          if (_isFilterMenuOpen)
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _isFilterMenuOpen = false;
                                  });
                                },
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  builder: (context, val, child) {
                                    return ClipRect(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10 * val,
                                          sigmaY: 10 * val,
                                        ),
                                        child: Container(
                                          color: Colors.black.withValues(
                                            alpha: 0.35 * val,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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
                                selectedUserId: selectedUserId,
                                feedTransactions: filteredTransactions,
                                isMenuOpen: _isFilterMenuOpen,
                                onMenuOpenChanged: (open) {
                                  setState(() {
                                    _isFilterMenuOpen = open;
                                  });
                                },
                                onOpenGallery: () {
                                  _openGallery(
                                    context: context,
                                    transactions: filteredTransactions,
                                    palette: palette,
                                  );
                                },
                                onCaptureTap: () {
                                  if (_isFilterMenuOpen) {
                                    setState(() {
                                      _isFilterMenuOpen = false;
                                    });
                                  }
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.addTransaction,
                                  );
                                },
                                onSelected: _changeFilter,
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

class _FilteredEmptyFeed extends StatefulWidget {
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

  @override
  State<_FilteredEmptyFeed> createState() => _FilteredEmptyFeedState();
}

class _FilteredEmptyFeedState extends State<_FilteredEmptyFeed> {
  bool _isMenuOpen = false;

  String _emptyFilterText(BuildContext context) {
    if (widget.selectedUserId == 'me') {
      return context.l10n.youHaveNoPosts;
    }

    if (widget.selectedUserId == 'all') {
      return context.l10n.noPostsYet;
    }

    UserModel? selectedFriend;

    for (final friend in widget.friendProfiles) {
      if (friend.uid == widget.selectedUserId) {
        selectedFriend = friend;
        break;
      }
    }

    final name = selectedFriend?.name.trim().isNotEmpty == true
        ? selectedFriend!.name.trim()
        : selectedFriend?.username.trim().isNotEmpty == true
            ? selectedFriend!.username.trim()
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
                    color: widget.palette.accent.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _emptyFilterText(context),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle(context).copyWith(
                      color: widget.palette.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Blurred Backdrop Barrier when dropdown is open in empty state
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _isMenuOpen = false;
                });
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                builder: (context, val, child) {
                  return ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10 * val,
                        sigmaY: 10 * val,
                      ),
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: 0.35 * val,
                        ),
                      ),
                    ),
                  );
                },
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
              myProfile: widget.myProfile,
              friendProfiles: widget.friendProfiles,
              selectedUserId: widget.selectedUserIdValue,
              feedTransactions: widget.feedTransactions,
              isMenuOpen: _isMenuOpen,
              onMenuOpenChanged: (open) {
                setState(() {
                  _isMenuOpen = open;
                });
              },
              onOpenGallery: () {},
              onCaptureTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.addTransaction,
                );
              },
              onSelected: widget.onSelected,
              palette: widget.palette,
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

    final locale = Localizations.localeOf(context).languageCode;
    final isVietnamese = locale == 'vi';

    if (now.year == createdAt.year) {
      if (isVietnamese) {
        return '${createdAt.day} thg ${createdAt.month}';
      }
      return DateFormat('d MMM', 'en').format(createdAt);
    }

    if (isVietnamese) {
      return '${createdAt.day} thg ${createdAt.month}, ${createdAt.year}';
    }
    return DateFormat('d MMM, y', 'en').format(createdAt);
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
            final maxHeight = constraints.maxHeight;

            final isShort = maxHeight < 740;
            final hasNote = transaction.note.trim().isNotEmpty && isOwner;
            final hasAmount = isOwner || transaction.privacy == 'group';

            final topSpacing = isShort
                ? ((maxHeight < 660) ? 84.0 : 96.0)
                : ((maxHeight < 800) ? 120.0 : 140.0);
            final itemGap = isShort ? 8.0 : 12.0;
            final bottomPadding = isShort ? 72.0 : 80.0;

            final infoOverhead = 32.0 +
                (hasNote ? (itemGap * 0.6 + 22.0) : 0.0) +
                (hasAmount ? (itemGap * 0.6 + 22.0) : 0.0) +
                itemGap;

            final totalOverhead = topSpacing + bottomPadding + infoOverhead;
            final maxAvailableImageHeight = maxHeight - totalOverhead;
            final imageSize = math
                .min(maxWidth, maxAvailableImageHeight)
                .clamp(160.0, maxWidth);

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
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Column(
                  children: [
                    SizedBox(height: topSpacing),
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: _MainSquarePost(
                        transaction: transaction,
                        palette: palette,
                      ),
                    ),
                    SizedBox(height: itemGap),
                    _UploaderInfo(
                      user: user,
                      timeText: _formatFeedTime(context, transaction.createdAt),
                      palette: palette,
                      isPrivate: transaction.privacy == 'private',
                      isOwner: isOwner,
                      groupName: transaction.privacy == 'group'
                          ? (transaction.groupName ?? 'Nhóm')
                          : null,
                    ),
                    if (hasNote) ...[
                      SizedBox(height: itemGap * 0.6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          transaction.note.trim(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySecondary(context).copyWith(
                            color: palette.textSecondary,
                            fontSize: isShort ? 13 : 14,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    if (hasAmount) ...[
                      SizedBox(height: itemGap * 0.6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '${transaction.type == 'expense' ? '-' : '+'}$amountText • $localizedCategory',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: transaction.type == 'expense'
                                ? AppColors.expense
                                : AppColors.income,
                            fontWeight: FontWeight.w800,
                            fontSize: isShort ? 14 : 15,
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
  final bool isMenuOpen;
  final ValueChanged<bool> onMenuOpenChanged;
  final VoidCallback onOpenGallery;
  final VoidCallback onCaptureTap;
  final ValueChanged<String> onSelected;
  final _FeedPalette palette;

  const _FeedHeader({
    required this.myProfile,
    required this.friendProfiles,
    required this.selectedUserId,
    required this.feedTransactions,
    required this.isMenuOpen,
    required this.onMenuOpenChanged,
    required this.onOpenGallery,
    required this.onCaptureTap,
    required this.onSelected,
    required this.palette,
  });

  @override
  State<_FeedHeader> createState() => _FeedHeaderState();
}

class _FeedHeaderState extends State<_FeedHeader> {

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
    widget.onMenuOpenChanged(false);
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
                  widget.onMenuOpenChanged(!widget.isMenuOpen);
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
                          turns: widget.isMenuOpen ? 0.5 : 0.0,
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
          child: widget.isMenuOpen
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
      borderRadius: BorderRadius.circular(56),
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
              borderRadius: BorderRadius.circular(56),
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
              left: 14,
              right: 14,
              bottom: 14,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                      width: 1,
                    ),
                  ),
                  child: _buildCaptionWithMentions(context, captionText, transaction),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCaptionWithMentions(
    BuildContext context,
    String text,
    TransactionModel transaction,
  ) {
    final mentionRegex = RegExp(r'(@[a-zA-Z0-9_.]+)');
    final matches = mentionRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
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
      );
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.18,
          ),
        ));
      }

      final mentionToken = match.group(0)!;
      final cleanUsername = mentionToken.substring(1).toLowerCase();

      // Check if this mention is active:
      // - If post is private: NEVER active (plain normal text).
      // - If transaction has taggedUsernames: active ONLY if cleanUsername is in taggedUsernames.
      // - Legacy fallback for older transactions: active if friends post.
      final isMentionActive = transaction.privacy != 'private' &&
          (transaction.taggedUsernames.isNotEmpty
              ? transaction.taggedUsernames.contains(cleanUsername)
              : (transaction.privacy == 'friends'));

      if (isMentionActive) {
        spans.add(
          TextSpan(
            text: mentionToken,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                HapticFeedback.lightImpact();
                _openMentionedUserProfile(context, cleanUsername);
              },
          ),
        );
      } else {
        // Plain text: NOT cyan, NOT bold, NOT clickable
        spans.add(
          TextSpan(
            text: mentionToken,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.18,
            ),
          ),
        );
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.18,
        ),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      softWrap: true,
    );
  }

  void _openMentionedUserProfile(BuildContext context, String username) async {
    final userRepo = context.read<UserRepository>();
    final user = await userRepo.findUserByUsername(username);

    if (!context.mounted) return;

    if (user != null) {
      _showMentionedUserSheet(context, user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('@$username: ${context.l10n.noMatchingFriends}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMentionedUserSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return _MentionedUserProfileSheet(user: user);
      },
    );
  }
}

class _MentionedUserProfileSheet extends StatefulWidget {
  final UserModel user;

  const _MentionedUserProfileSheet({
    required this.user,
  });

  @override
  State<_MentionedUserProfileSheet> createState() =>
      _MentionedUserProfileSheetState();
}

class _MentionedUserProfileSheetState
    extends State<_MentionedUserProfileSheet> {
  bool _isLoading = true;
  bool _isFriend = false;
  bool _requestSent = false;
  bool _isActionBusy = false;

  @override
  void initState() {
    super.initState();
    _checkFriendship();
  }

  Future<void> _checkFriendship() async {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null || myUid == widget.user.uid) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final userRepo = context.read<UserRepository>();
    final isFriend = await userRepo.isFriendWith(myUid, widget.user.uid);
    final requestSent =
        isFriend ? false : await userRepo.hasSentFriendRequestTo(myUid, widget.user.uid);

    if (mounted) {
      setState(() {
        _isFriend = isFriend;
        _requestSent = requestSent;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSendFriendRequest() async {
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid == null || _isActionBusy) return;

    setState(() {
      _isActionBusy = true;
    });

    final userRepo = context.read<UserRepository>();
    final result = await userRepo.sendFriendRequest(
      myUid: myUid,
      targetUser: widget.user,
    );

    if (mounted) {
      setState(() {
        _isActionBusy = false;
        if (result == 'auto_accepted') {
          _isFriend = true;
        } else {
          _requestSent = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = context.read<AuthController>().user?.uid;
    final isMe = myUid != null && myUid == widget.user.uid;
    final user = widget.user;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E212B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Avatar with Frame
            AvatarWithFrame(
              avatarUrl: user.avatarUrl,
              frameId: user.avatarFrame,
              size: 76,
            ),
            const SizedBox(height: 14),

            // Name
            Text(
              user.name.isNotEmpty ? user.name : user.username,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),

            // @username
            Text(
              '@${user.username}',
              style: const TextStyle(
                color: Color(0xFF0099FF),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Streak badge if > 0
            if (user.currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF9500),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.streakDayCount(user.currentStreak),
                      style: const TextStyle(
                        color: Color(0xFFFF9500),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // 3 CASES OF ACTION BUTTONS:
            // Case 1: If user is ME -> Show "(Bạn)" pill button
            if (isMe)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      child: Text(
                        context.l10n.you,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF0099FF),
                    ),
                  ),
                ),
              )
            // Case 3: If user IS FRIEND -> Show Message Button
            else if (_isFriend)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          RouteNames.chatConversation,
                          arguments: {'friend': user},
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: Text(
                        context.l10n.messageFriend,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0099FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              )
            // Case 2: If user IS NOT FRIEND -> Show Add Friend button (or Request Sent if pending)
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _requestSent || _isActionBusy
                          ? null
                          : _handleSendFriendRequest,
                      icon: _isActionBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _requestSent
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.person_add_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _requestSent
                            ? context.l10n.friendRequestSent
                            : context.l10n.addFriend,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _requestSent
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.08))
                            : const Color(0xFF0099FF),
                        foregroundColor: _requestSent
                            ? (isDark ? Colors.white70 : Colors.black54)
                            : Colors.white,
                        disabledBackgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                        disabledForegroundColor:
                            isDark ? Colors.white70 : Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        elevation: 0,
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
          borderRadius: BorderRadius.circular(56),
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
  final String? groupName;

  const _UploaderInfo({
    required this.user,
    required this.timeText,
    required this.palette,
    required this.isPrivate,
    required this.isOwner,
    this.groupName,
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
          AvatarWithFrame(
            avatarUrl: avatarUrl,
            frameId: user?.avatarFrame,
            size: 36,
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
        if (groupName != null && groupName!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.groups_2_rounded,
                  size: 13,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  groupName!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                    icon: Icons.arrow_back_ios_new_rounded,
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