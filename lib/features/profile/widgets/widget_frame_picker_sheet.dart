import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/widget_frames.dart';
import '../../../core/services/app_widget_service.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/profile_controller.dart';

class WidgetFramePickerSheet extends StatefulWidget {
  const WidgetFramePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const WidgetFramePickerSheet(),
    );
  }

  @override
  State<WidgetFramePickerSheet> createState() => _WidgetFramePickerSheetState();
}

class _WidgetFramePickerSheetState extends State<WidgetFramePickerSheet> {
  late String _selectedFrameId;

  @override
  void initState() {
    super.initState();
    final profileCtrl = context.read<ProfileController>();
    _selectedFrameId = profileCtrl.widgetFrame;
  }

  void _onSelectFrame(String frameId) {
    if (_selectedFrameId == frameId) return;
    AppHaptics.selectionClick();
    setState(() {
      _selectedFrameId = frameId;
    });

    final profileCtrl = context.read<ProfileController>();
    final authCtrl = context.read<AuthController>();
    final homeCtrl = context.read<HomeController>();
    FeedController? feedCtrl;
    try {
      feedCtrl = context.read<FeedController>();
    } catch (_) {}

    final uid = authCtrl.user?.uid ?? profileCtrl.user?.uid;

    profileCtrl.setWidgetFrame(frameId, uid);

    // Refresh background native home screen widgets with updated frame
    final currentProfile = profileCtrl.user?.copyWith(widgetFrame: frameId);
    AppWidgetService.instance.updateWidgets(
      profile: currentProfile,
      transactions: homeCtrl.transactions,
      feedTransactions: feedCtrl?.feedTransactions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final profileCtrl = context.watch<ProfileController>();
    final homeCtrl = context.watch<HomeController>();
    FeedController? feedCtrl;
    try {
      feedCtrl = context.watch<FeedController>();
    } catch (_) {}

    final user = profileCtrl.user ?? homeCtrl.profile;
    final isEn = (user?.language ?? profileCtrl.languageCode) == 'en';
    final frameItem = WidgetFrames.getById(_selectedFrameId);

    // Gather all available transactions to find the most recent moment photo
    final allTxs = <TransactionModel>[
      ...homeCtrl.transactions,
      if (feedCtrl != null) ...feedCtrl.feedTransactions,
    ];
    final seenIds = <String>{};
    final uniqueTxs = <TransactionModel>[];
    for (final tx in allTxs) {
      if (seenIds.add(tx.id)) {
        uniqueTxs.add(tx);
      }
    }
    uniqueTxs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    TransactionModel? latestTxWithMedia;
    for (final tx in uniqueTxs) {
      if (tx.displayImageUrl.trim().isNotEmpty ||
          tx.thumbnailUrl.trim().isNotEmpty ||
          tx.mediaUrl.trim().isNotEmpty) {
        latestTxWithMedia = tx;
        break;
      }
    }

    final latestTx = latestTxWithMedia ?? (uniqueTxs.isNotEmpty ? uniqueTxs.first : null);
    final previewImageUrl = latestTx != null
        ? (latestTx.displayImageUrl.isNotEmpty
            ? latestTx.displayImageUrl
            : (latestTx.thumbnailUrl.isNotEmpty
                ? latestTx.thumbnailUrl
                : latestTx.mediaUrl))
        : (user?.avatarUrl ?? '');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Drag Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 2. Live Widget Preview
                    _buildLivePreview(
                      context,
                      frameItem: frameItem,
                      user: user,
                      previewImageUrl: previewImageUrl,
                      isDark: isDark,
                      isEn: isEn,
                    ),

                    const SizedBox(height: 10),

                    // Label under preview (e.g. "Mọi người" / "Everyone" / Group / User Name)
                    Text(
                      latestTx?.groupName?.isNotEmpty == true
                          ? latestTx!.groupName!
                          : (isEn ? 'Everyone' : 'Mọi người'),
                      style: TextStyle(
                        fontFamily: 'ProximaSoft',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. Section Title "Khung widget"
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isEn ? 'Widget frame' : 'Khung widget',
                        style: TextStyle(
                          fontFamily: 'ProximaSoft',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 4. 3-Column Grid Card Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF282A33)
                            : const Color(0xFFF1F3F8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: WidgetFrames.all.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 18,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (context, index) {
                          final item = WidgetFrames.all[index];
                          final isSelected = item.id == _selectedFrameId;
                          return _buildFrameOptionItem(
                            context,
                            item: item,
                            isSelected: isSelected,
                            isDark: isDark,
                            isEn: isEn,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live widget interactive preview (Clean borders without glow blur)
  Widget _buildLivePreview(
    BuildContext context, {
    required WidgetFrameItem frameItem,
    required UserModel? user,
    required String previewImageUrl,
    required bool isDark,
    required bool isEn,
  }) {
    final hasFrame = !frameItem.isNone && frameItem.gradient != null;
    final borderWidth = hasFrame ? frameItem.borderWidth : 1.0;

    return Container(
      width: 150,
      height: 150,
      padding: hasFrame ? EdgeInsets.all(borderWidth) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: hasFrame ? frameItem.gradient : null,
        border: hasFrame
            ? null
            : Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFD8DDE6),
                width: 1.2,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(hasFrame ? (24 - borderWidth) : 23),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image or Default Graphic
            if (previewImageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: previewImageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildFallbackBackground(isDark),
              )
            else
              _buildFallbackBackground(isDark),

            // Dim overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Top-left: Streak Badge (🔥 1)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 12,
                      color: Color(0xFFFF5722),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${user?.currentStreak ?? 1}',
                      style: const TextStyle(
                        fontFamily: 'ProximaSoft',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-left: User Avatar Bubble
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: user?.avatarUrl.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: user!.avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primaryBlue,
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'M',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.primaryBlue,
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'M',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
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

  Widget _buildFallbackBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C3246), const Color(0xFF191B26)]
              : [const Color(0xFFD6E4FF), const Color(0xFFE8EEFA)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo_rounded,
          size: 44,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  /// Single frame item in 3-column grid (Clean border, blue brand tick)
  Widget _buildFrameOptionItem(
    BuildContext context, {
    required WidgetFrameItem item,
    required bool isSelected,
    required bool isDark,
    required bool isEn,
  }) {
    final hasGradient = !item.isNone && item.gradient != null;

    return GestureDetector(
      onTap: () => _onSelectFrame(item.id),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Frame Preview Box (Square)
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: hasGradient
                    ? const EdgeInsets.all(3.5)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: hasGradient ? item.gradient : null,
                  border: hasGradient
                      ? null
                      : Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.black.withValues(alpha: 0.12),
                          width: 1.2,
                        ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF333642)
                        : const Color(0xFFE4E7F0),
                    borderRadius: BorderRadius.circular(
                      hasGradient ? (20 - 3.5) : 19,
                    ),
                  ),
                  child: item.isNone
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              isEn ? 'None' : 'Không có',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'ProximaSoft',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E2235),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Selection Radio / Checkmark Circle (Brand Blue with White Checkmark)
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              border: isSelected
                  ? null
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.28)
                          : Colors.black.withValues(alpha: 0.24),
                      width: 2,
                    ),
            ),
            child: isSelected
                ? const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                      weight: 800,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
