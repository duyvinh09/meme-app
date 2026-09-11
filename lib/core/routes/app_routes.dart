import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../extensions/localization_extension.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/budget/screens/create_budget_screen.dart';
import '../../features/capture/screens/camera_screen.dart';
import '../../features/feed/controllers/feed_controller.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/home/screens/calendar_screen.dart';
import '../../features/home/screens/day_detail_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/transaction_browse_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/feedback_screen.dart';
import '../../features/profile/screens/friend_requests_screen.dart';
import '../../features/profile/screens/friends_screen.dart';
import '../../features/profile/screens/groups_screen.dart';
import '../../features/profile/screens/manage_categories_screen.dart';
import '../../features/profile/controllers/user_category_controller.dart';
import '../../features/profile/screens/app_icon_picker_screen.dart';
import '../../features/profile/screens/camera_theme_picker_screen.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/chat/screens/chat_conversation_screen.dart';
import '../../features/chat/screens/group_chat_conversation_screen.dart';
import '../../features/chat/screens/chat_bubble_theme_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/controllers/chat_controller.dart';
import '../../features/rewind/screens/rewind_screen.dart';
import '../../data/models/user_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/user_repository.dart';
import 'route_names.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashGate(),
        );

      case RouteNames.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case RouteNames.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case RouteNames.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
        );

      case RouteNames.mainShell:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialIndex = args?['initialIndex'] as int? ?? 0;
        final targetPostId = args?['targetPostId'] as String?;
        return MaterialPageRoute(
          builder: (_) => MainShell(
            initialIndex: initialIndex,
            initialTargetPostId: targetPostId,
          ),
        );

      case RouteNames.addTransaction:
        return MaterialPageRoute(
          builder: (_) => const CameraScreen(),
        );

      case RouteNames.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );

      case RouteNames.createBudget:
        return MaterialPageRoute(
          builder: (_) => const CreateBudgetScreen(),
        );

      case RouteNames.calendar:
        return MaterialPageRoute(
          builder: (_) => const CalendarScreen(),
        );

      case RouteNames.dayDetail:
        final args = settings.arguments;

        if (args is DateTime) {
          return MaterialPageRoute(
            builder: (_) => DayDetailScreen(selectedDate: args),
          );
        }

        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Thiếu dữ liệu ngày để mở chi tiết'),
            ),
          ),
        );

      case RouteNames.editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        );

      case RouteNames.friends:
        return MaterialPageRoute(
          builder: (_) => const FriendsScreen(),
        );

      case RouteNames.groups:
        return MaterialPageRoute(
          builder: (_) => const GroupsScreen(),
        );

      case RouteNames.feedback:
        return MaterialPageRoute(
          builder: (_) => const FeedbackScreen(),
        );

      case RouteNames.friendRequests:
        return MaterialPageRoute(
          builder: (_) => const FriendRequestsScreen(),
        );

      case RouteNames.manageCategories:
        return MaterialPageRoute(
          builder: (_) => const ManageCategoriesScreen(),
        );

      case RouteNames.appIcon:
        return MaterialPageRoute(
          builder: (_) => const AppIconPickerScreen(),
        );

      case RouteNames.cameraTheme:
        return MaterialPageRoute(
          builder: (_) => const CameraThemePickerScreen(),
        );

      case RouteNames.chatConversation:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          final friend = args['friend'] as UserModel;
          final initialPostReply = args['initialPostReply'] as TransactionModel?;
          return MaterialPageRoute(
            builder: (_) => ChatConversationScreen(
              friend: friend,
              initialPostReply: initialPostReply,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Invalid chat arguments')),
          ),
        );

      case RouteNames.groupChatConversation:
        final args = settings.arguments;
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => GroupChatConversationScreen(
              groupId: args['groupId'] as String,
              groupName: (args['groupName'] as String?) ?? 'Nhóm',
              groupColor: args['groupColor'] as String?,
              memberUids: (args['memberUids'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList(),
              initialPostReply: args['initialPostReply'] as TransactionModel?,
              initialPostAuthor: args['initialPostAuthor'] as UserModel?,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Invalid group chat arguments')),
          ),
        );

      case RouteNames.chatBubbleTheme:
        return MaterialPageRoute(
          builder: (_) => const ChatBubbleThemeScreen(),
        );

      case RouteNames.chatList:
        return MaterialPageRoute(
          builder: (_) => const ChatListScreen(),
        );

      case RouteNames.rewind:
        return MaterialPageRoute(
          builder: (_) => const RewindScreen(),
        );

      case RouteNames.browseTransactions:
        final transactions = settings.arguments as List<TransactionModel>?;
        return MaterialPageRoute(
          builder: (_) => TransactionBrowseScreen(
            initialTransactions: transactions,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }
}

class SplashGate extends StatelessWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.user == null) {
      return const LoginScreen();
    }

    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  final int initialIndex;
  final String? initialTargetPostId;

  const MainShell({
    super.key,
    this.initialIndex = 0,
    this.initialTargetPostId,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  late int index;
  bool isRefreshingFeed = false;

  bool showCaptureFab = true;

  Timer? _captureFabTimer;
  Timer? _presenceHeartbeatTimer;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    showCaptureFab = index == 0;
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.initialTargetPostId != null && widget.initialTargetPostId!.isNotEmpty) {
        context.read<FeedController>().setTargetPostId(widget.initialTargetPostId);
      }

      final uid = context.read<AuthController>().user?.uid;
      if (uid != null) {
        context.read<ProfileController>().loadUser(uid);
        context.read<UserCategoryController>().load(uid);
        context.read<ChatController>().initIncomingMessageListener(uid);
        _updatePresence(true);
        _startPresenceHeartbeat();
      }

      if (index == 0) {
        _showCaptureFabNow();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence(true);
      _startPresenceHeartbeat();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _stopPresenceHeartbeat();
      _updatePresence(false);
    }
  }

  void _updatePresence(bool isOnline) {
    final uid = context.read<AuthController>().user?.uid;
    if (uid != null) {
      context.read<UserRepository>().updateUserPresence(uid, isOnline: isOnline);
    }
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      _updatePresence(true);
    });
  }

  void _stopPresenceHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
  }



  Future<void> _reloadFeed(BuildContext context) async {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null || isRefreshingFeed) return;

    context.read<FeedController>().triggerScrollToTop();

    setState(() {
      isRefreshingFeed = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      await context.read<FeedController>().load(uid);
    } finally {
      final remaining = 900 - stopwatch.elapsedMilliseconds;

      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      }

      if (mounted) {
        setState(() {
          isRefreshingFeed = false;
        });
      }
    }
  }

  Future<void> _onNavTap(BuildContext context, int value) async {
    // Nếu bấm lại tab Bạn bè thì refresh feed.
    if (value == 2) {
      if (index == 2) {
        await _reloadFeed(context);
        return;
      }

      context.read<FeedController>().triggerScrollToTop();

      setState(() {
        index = value;
        showCaptureFab = false;
      });

      _captureFabTimer?.cancel();
      return;
    }

    if (index != value) {
      setState(() {
        index = value;
        showCaptureFab = value == 0;
      });
      if (value == 0) {
        _showCaptureFabNow();
      } else {
        _captureFabTimer?.cancel();
      }
      if (value == 4) {
        final uid = context.read<AuthController>().user?.uid;
        if (uid != null) {
          context.read<ProfileController>().refreshUser(uid);
        }
      }
    }
  }

  void _showCaptureFabNow() {
    _captureFabTimer?.cancel();
    if (!showCaptureFab && mounted) {
      setState(() {
        showCaptureFab = true;
      });
    }
  }

  void _hideCaptureFabNow() {
    _captureFabTimer?.cancel();
    if (showCaptureFab && mounted) {
      setState(() {
        showCaptureFab = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPresenceHeartbeat();
    _updatePresence(false);
    _captureFabTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (index != 0 || notification.depth != 0) {
                  return false;
                }

                if (notification is UserScrollNotification) {
                  final direction = notification.direction;
                  if (direction == ScrollDirection.reverse) {
                    // Scrolling DOWN: Slide down & hide FAB group
                    _hideCaptureFabNow();
                  } else if (direction == ScrollDirection.forward) {
                    // Scrolling UP: Slide up & restore FAB group immediately
                    _showCaptureFabNow();
                  }
                }
                return false;
              },
              child: IndexedStack(
                index: index,
                children: [
                  const HomeScreen(),
                  const StatsScreen(),
                  FeedScreen(isActive: index == 2),
                  const BudgetScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSizes.pagePadding,
            right: AppSizes.pagePadding,
            bottom: 24,
            child: _FloatingGlassNavbar(
              currentIndex: index,
              isRefreshingFeed: isRefreshingFeed,
              onTap: (value) => _onNavTap(context, value),
            ),
          ),
          if (index == 0)
            Positioned(
              right: 20,
              bottom: 104,
              child: IgnorePointer(
                ignoring: !showCaptureFab,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  offset: showCaptureFab ? Offset.zero : const Offset(0, 0.40),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    opacity: showCaptureFab ? 1.0 : 0.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. TOP: CHAT / NHẮN TIN BUTTON
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(context, RouteNames.chatList);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.isDark(context)
                                  ? const Color(0xFF262938)
                                  : Colors.white,
                              border: Border.all(
                                color: AppColors.isDark(context)
                                    ? Colors.white.withValues(alpha: 0.16)
                                    : AppColors.primaryBlue.withValues(alpha: 0.20),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: AppColors.isDark(context) ? 0.28 : 0.10,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chat_bubble_rounded,
                              color: AppColors.isDark(context)
                                  ? Colors.white
                                  : AppColors.primaryBlue,
                              size: 22,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 2. BOTTOM: CAMERA BUTTON
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(context, RouteNames.addTransaction);
                          },
                          child: Container(
                            width: AppSizes.captureFabSize,
                            height: AppSizes.captureFabSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryBlue,
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: AppColors.isDark(context) ? 0.14 : 0.90,
                                ),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_a_photo_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
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

class _FloatingGlassNavbar extends StatelessWidget {
  final int currentIndex;
  final bool isRefreshingFeed;
  final ValueChanged<int> onTap;

  const _FloatingGlassNavbar({
    required this.currentIndex,
    required this.isRefreshingFeed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final selectedColor = AppColors.primaryBlue;
    final unselectedColor = isDark
        ? Colors.white.withValues(alpha: 0.82)
        : Colors.black.withValues(alpha: 0.62);

    final l10n = context.l10n;
    final items = <_NavBarItemData>[
      _NavBarItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.tabHome,
      ),
      _NavBarItemData(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.analytics_rounded,
        label: l10n.tabStats,
      ),
      _NavBarItemData(
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome_rounded,
        label: l10n.tabFriends,
      ),
      _NavBarItemData(
        icon: Icons.savings_outlined,
        activeIcon: Icons.savings_rounded,
        label: l10n.tabBudget,
      ),
      _NavBarItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: l10n.profile,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: AppSizes.navbarHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
            color: AppColors.glassBackground(context),
            border: Border.all(
              color: AppColors.glassBorder(context),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: SizedBox(
                      width: 72,
                      height: 68,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          width: selected ? 80 : 58,
                          height: selected ? 78 : 56,
                          decoration: BoxDecoration(
                            color: selected
                                ? selectedColor.withValues(
                                    alpha: isDark ? 0.18 : 0.14,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLarge,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (i == 2)
                                _SpinningFeedIcon(
                                  spinning:
                                  isRefreshingFeed && currentIndex == 2,
                                  icon: selected
                                      ? item.activeIcon
                                      : item.icon,
                                  size: selected ? 33 : 29,
                                  color: selected
                                      ? selectedColor
                                      : unselectedColor,
                                )
                              else
                                Icon(
                                  selected ? item.activeIcon : item.icon,
                                  size: selected ? 33 : 29,
                                  color: selected
                                      ? selectedColor
                                      : unselectedColor,
                                ),
                              const SizedBox(height: 3),
                              Flexible(
                                child: Text(
                                  i == 2 && isRefreshingFeed
                                      ? l10n.tabLoading
                                      : item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.navLabel(
                                    selected: selected,
                                    color: selected
                                        ? selectedColor
                                        : unselectedColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavBarItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _SpinningFeedIcon extends StatefulWidget {
  final bool spinning;
  final IconData icon;
  final double size;
  final Color color;

  const _SpinningFeedIcon({
    required this.spinning,
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  State<_SpinningFeedIcon> createState() => _SpinningFeedIconState();
}

class _SpinningFeedIconState extends State<_SpinningFeedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    if (widget.spinning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _SpinningFeedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.spinning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.spinning && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.spinning) {
      return Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      );
    }

    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.refresh_rounded,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}