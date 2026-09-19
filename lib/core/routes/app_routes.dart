import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../extensions/localization_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/budget/screens/create_budget_screen.dart';
import '../../features/budget/controllers/budget_controller.dart';
import '../../features/capture/screens/camera_screen.dart';
import '../../features/capture/widgets/quick_voice_expense_sheet.dart';
import '../../features/feed/controllers/feed_controller.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/home/controllers/home_controller.dart';
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
import '../../features/splash/screens/preloader_screen.dart';
import '../../features/chat/controllers/chat_controller.dart';
import '../../features/rewind/screens/rewind_screen.dart';
import '../../features/rewind/models/rewind_period.dart';
import '../../data/models/user_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../services/notification_service.dart';
import 'route_names.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

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
        final args = settings.arguments;
        RewindPeriod? period;
        if (args is RewindPeriod) {
          period = args;
        } else if (args is Map<String, dynamic>) {
          final periodType = args['period']?.toString();
          if (periodType == 'thisMonth' || periodType == 'monthly') {
            period = RewindPeriod.thisMonth();
          } else {
            period = RewindPeriod.thisWeek();
          }
        }
        return MaterialPageRoute(
          builder: (_) => RewindScreen(initialPeriod: period),
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

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _preloaderDone = false;

  void _onPreloaderComplete() {
    if (mounted) {
      setState(() => _preloaderDone = true);
    }
  }

  Future<void> _preloadAppData() async {
    if (!mounted) return;
    final auth = context.read<AuthController>();
    final uid = auth.user?.uid ?? FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final homeCtrl = context.read<HomeController>();
      final budgetCtrl = context.read<BudgetController>();
      final profileCtrl = context.read<ProfileController>();
      final userCatCtrl = context.read<UserCategoryController>();
      final chatCtrl = context.read<ChatController>();

      try {
        // Kích hoạt nạp dữ liệu song song cho trang chủ và các dịch vụ nền
        budgetCtrl.load(uid);
        userCatCtrl.load(uid);
        chatCtrl.initIncomingMessageListener(uid);

        await Future.wait<dynamic>([
          homeCtrl.load(uid),
          profileCtrl.loadUser(uid),
        ]).timeout(
          const Duration(milliseconds: 3200),
          onTimeout: () {
            debugPrint('Preloading data timeout reached, continuing to main shell');
            return const [];
          },
        );
      } catch (e) {
        debugPrint('Error preloading home data during splash: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _buildCurrentState(context),
    );
  }

  Widget _buildCurrentState(BuildContext context) {
    // Bước 1: Chạy animation preloader + load data
    if (!_preloaderDone) {
      return PreloaderScreen(
        key: const ValueKey('preloader_screen'),
        minDisplayDuration: const Duration(milliseconds: 2200),
        preloadAction: _preloadAppData,
        onComplete: _onPreloaderComplete,
      );
    }

    // Bước 2: Sau khi preloader xong → điều hướng sang MainShell (Home) nếu đã đăng nhập, hoặc LoginScreen nếu chưa đăng nhập
    final auth = context.watch<AuthController>();
    if (auth.user == null) {
      return const LoginScreen(key: ValueKey('login_screen'));
    }
    return const MainShell(key: ValueKey('main_shell'));
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
  bool isFabMenuOpen = false;

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
        context.read<HomeController>().load(uid);
        context.read<BudgetController>().load(uid);
        context.read<ProfileController>().loadUser(uid);
        context.read<UserCategoryController>().load(uid);
        context.read<ChatController>().initIncomingMessageListener(uid);
        _updatePresence(true);
        _startPresenceHeartbeat();
        NotificationService.instance.checkAndShowInAppRewindNotification();
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
      NotificationService.instance.checkAndShowInAppRewindNotification();
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
    if (isFabMenuOpen) {
      setState(() {
        isFabMenuOpen = false;
      });
    }

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
        isFabMenuOpen = false;
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
    final isDark = AppColors.isDark(context);

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

          // Backdrop barrier when FAB menu is open
          if (index == 0 && isFabMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    isFabMenuOpen = false;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.20),
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
                    child: _GenZExpandableFab(
                      isOpen: isFabMenuOpen,
                      onToggle: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          isFabMenuOpen = !isFabMenuOpen;
                        });
                      },
                      onVoiceTap: () {
                        setState(() => isFabMenuOpen = false);
                        QuickVoiceExpenseSheet.show(context);
                      },
                      onCameraTap: () {
                        setState(() => isFabMenuOpen = false);
                        Navigator.pushNamed(context, RouteNames.addTransaction);
                      },
                      onChatTap: () {
                        if (isFabMenuOpen) {
                          setState(() => isFabMenuOpen = false);
                        }
                        Navigator.pushNamed(context, RouteNames.chatList);
                      },
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

class _GenZExpandableFab extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onVoiceTap;
  final VoidCallback onCameraTap;
  final VoidCallback onChatTap;

  const _GenZExpandableFab({
    required this.isOpen,
    required this.onToggle,
    required this.onVoiceTap,
    required this.onCameraTap,
    required this.onChatTap,
  });

  @override
  State<_GenZExpandableFab> createState() => _GenZExpandableFabState();
}

class _GenZExpandableFabState extends State<_GenZExpandableFab>
    with SingleTickerProviderStateMixin {
  // ===========================================================================
  // ⚙️ CẤU HÌNH KÍCH THƯỚC & TỌA ĐỘ CÁC NÚT
  // ===========================================================================
  static const double mainFabSize = 62.0;  // Kích thước nút chính (+ / ×)
  static const double subFabSize = 42.0;   // Kích thước nút phụ (Camera, Mic)
  static const double chatFabSize = 46.0;  // Kích thước nút Nhắn tin
  static const double borderWidth = 1.5;   // Độ mỏng của viền nút

  // Tọa độ đích khi bung ra (X: âm là sang trái, Y: âm là lên trên)
  static const Offset cameraOffset = Offset(-16.0, -70.0); // Nút Camera ở trên
  static const Offset micOffset = Offset(-70.0, -16.0);    // Nút Mic ở ngoài/trái

  // Vị trí nút Nhắn tin (Chat)
  static const double chatClosedY = -72.0;   // Khoảng cách nút Chat khi ĐÓNG (xa nút + hơn)
  static const double chatOpenedY = -125.0;  // Vị trí nút Chat khi MỞ menu
  // ===========================================================================

  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _voiceAnimation;
  late Animation<double> _cameraAnimation;
  late Animation<double> _chatSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 240),
    );

    // Xoay 45 độ (0.125 turns) khi mở và xoay ngược lại khi đóng
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInOutCubic,
      ),
    );

    // Nút Mic: bung ra ngay và thu hồi ngược lại
    _voiceAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.82, curve: Curves.easeOutBack),
      reverseCurve: const Interval(0.18, 1.0, curve: Curves.easeInOutCubic),
    );

    // Nút Camera: bung ra lệch sau 50ms và thu hồi ngược lại
    _cameraAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.16, 1.0, curve: Curves.easeOutBack),
      reverseCurve: const Interval(0.0, 0.82, curve: Curves.easeInOutCubic),
    );

    // Nút Chat trượt lên / xuống đồng bộ
    _chatSlideAnimation = Tween<double>(begin: chatClosedY, end: chatOpenedY).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInOutCubic,
      ),
    );

    if (widget.isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _GenZExpandableFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSubItem({
    required Animation<double> animation,
    required Offset targetOffset,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        if (progress <= 0.001) {
          return const SizedBox.shrink();
        }

        final currentOffset = Offset(
          targetOffset.dx * progress,
          targetOffset.dy * progress,
        );
        final scale = progress.clamp(0.0, 1.0);
        final opacity = progress.clamp(0.0, 1.0);

        return Transform.translate(
          offset: currentOffset,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
                child: Container(
                  width: subFabSize,
                  height: subFabSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue,
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.35 : 0.90,
                      ),
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Stream<int>? _unreadStream;
  String? _lastListeningUid;
  int _lastKnownUnreadCount = 0;

  @override
  void reassemble() {
    super.reassemble();
    _unreadStream = null;
    _lastListeningUid = null;
  }

  void _ensureUnreadStream(String uid, ChatRepository chatRepo) {
    if (uid.isEmpty) {
      _unreadStream = null;
      _lastListeningUid = null;
      _lastKnownUnreadCount = 0;
      return;
    }
    if (_lastListeningUid != uid || _unreadStream == null) {
      _lastListeningUid = uid;
      _unreadStream = chatRepo.streamTotalUnreadCount(uid).distinct();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final myUid = context.watch<AuthController>().user?.uid ?? '';
    final chatRepo = context.read<ChatRepository>();
    _ensureUnreadStream(myUid, chatRepo);

    return SizedBox(
      width: 170,
      height: 250,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // 1. Nút Chat (Trượt lên cao khi mở menu và hạ xuống khi đóng)
          AnimatedBuilder(
            animation: _chatSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _chatSlideAnimation.value),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onChatTap();
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: chatFabSize,
                        height: chatFabSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF262938)
                              : Colors.white,
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.20)
                                : AppColors.primaryBlue.withValues(alpha: 0.25),
                            width: borderWidth,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.28 : 0.10,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chat_bubble_rounded,
                          color: isDark
                              ? Colors.white
                              : AppColors.primaryBlue,
                          size: 21,
                        ),
                      ),
                      // Realtime Unread Count Badge (filters out muted chats, max 99+)
                      if (_unreadStream != null)
                        StreamBuilder<int>(
                          stream: _unreadStream,
                          initialData: _lastKnownUnreadCount,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              _lastKnownUnreadCount = snapshot.data!;
                            }
                            final unreadCount =
                                snapshot.data ?? _lastKnownUnreadCount;
                            if (unreadCount <= 0) {
                              return const SizedBox.shrink();
                            }

                            final String badgeText =
                                unreadCount > 99 ? '99+' : '$unreadCount';

                            return Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF1E212B)
                                        : Colors.white,
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF3B30)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    badgeText,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Nút Camera (Bung ra phía trên theo cánh cung)
          _buildSubItem(
            animation: _cameraAnimation,
            targetOffset: cameraOffset,
            icon: Icons.photo_camera_rounded,
            onTap: widget.onCameraTap,
            isDark: isDark,
          ),

          // 3. Nút Mic (Bung ra bên trái/ngoài theo cánh cung)
          _buildSubItem(
            animation: _voiceAnimation,
            targetOffset: micOffset,
            icon: Icons.mic_rounded,
            onTap: widget.onVoiceTap,
            isDark: isDark,
          ),

          // 4. Nút chính + (Xoay 45° thành × khi mở, xoay ngược lại khi đóng)
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              width: mainFabSize,
              height: mainFabSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isOpen
                    ? (isDark ? const Color(0xFF384050) : const Color(0xFF374151))
                    : AppColors.primaryBlue,
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: isDark ? 0.25 : 0.90,
                  ),
                  width: borderWidth + 0.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isOpen
                            ? Colors.black
                            : AppColors.primaryBlue)
                        .withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * math.pi,
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  );
                },
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

    final selectedColor = isDark
        ? AppColors.primaryBlue
        : const Color(0xFF1D4ED8);
    final unselectedColor = isDark
        ? Colors.white.withValues(alpha: 0.82)
        : const Color(0xFF334155);

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
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
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
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.24)
                    : Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 6),
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