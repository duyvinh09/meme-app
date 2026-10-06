import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/widget_frames.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/widgets/app_back_button.dart';
import '../controllers/profile_controller.dart';
import '../widgets/widget_frame_picker_sheet.dart';

class HomeWidgetsScreen extends StatefulWidget {
  const HomeWidgetsScreen({super.key});

  @override
  State<HomeWidgetsScreen> createState() => _HomeWidgetsScreenState();
}

class _HomeWidgetsScreenState extends State<HomeWidgetsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Scrollable Content
            Positioned.fill(
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  68,
                  AppSizes.pagePadding,
                  32,
                ),
                children: [
                  // Banner giới thiệu
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF1E2235),
                                const Color(0xFF161926),
                              ]
                            : [
                                const Color(0xFFEBF3FF),
                                const Color(0xFFF3EAFF),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFDFE7F8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.widgets_rounded,
                            color: AppColors.primaryBlue,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.homeWidgetsIntroTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.homeWidgetsIntroSubtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary(context),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // PHẦN 1: CÁC LOẠI WIDGET HIỆN CÓ
                  Text(
                    l10n.availableWidgetsSection,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark
                          ? const Color(0xFF7E8499)
                          : const Color(0xFF8A92A6),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. Widget Thống kê chi tiêu (4x2)
                  _buildWidgetCard(
                    context: context,
                    title: l10n.statsWidgetTitle,
                    sizeTag: l10n.statsWidgetSize,
                    tagColor: AppColors.primaryBlue,
                    description: l10n.statsWidgetDesc,
                    deepLinkNote: l10n.statsWidgetTapHint,
                    previewWidget: _buildStatsWidgetPreview(context),
                  ),

                  const SizedBox(height: 20),

                  // 2. Widget Nhật ký Lịch ảnh (4x4)
                  _buildWidgetCard(
                    context: context,
                    title: l10n.calendarWidgetTitle,
                    sizeTag: l10n.calendarWidgetSize,
                    tagColor: const Color(0xFFFF5722),
                    description: l10n.calendarWidgetDesc,
                    deepLinkNote: l10n.calendarWidgetTapHint,
                    previewWidget: _buildCalendarWidgetPreview(context),
                  ),

                  const SizedBox(height: 20),

                  // 3. Widget Khoảnh khắc gần nhất (2x2)
                  _buildWidgetCard(
                    context: context,
                    title: l10n.momentWidgetTitle,
                    sizeTag: l10n.momentWidgetSize,
                    tagColor: const Color(0xFF10B981),
                    description: l10n.momentWidgetDesc,
                    deepLinkNote: l10n.momentWidgetTapHint,
                    actionButton: OutlinedButton.icon(
                      onPressed: () => WidgetFramePickerSheet.show(context),
                      icon: const Icon(Icons.palette_outlined, size: 16),
                      label: Text(
                        l10n.changeWidgetFrame,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    previewWidget: _buildMomentWidgetPreview(context),
                  ),

                  const SizedBox(height: 32),

                  // PHẦN 2: HƯỚNG DẪN CÀI ĐẶT
                  Text(
                    l10n.widgetSetupGuideSection,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark
                          ? const Color(0xFF7E8499)
                          : const Color(0xFF8A92A6),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildGuideStep(
                    context: context,
                    stepNumber: '1',
                    title: l10n.widgetStep1Title,
                    subtitle: l10n.widgetStep1Desc,
                  ),
                  _buildGuideStep(
                    context: context,
                    stepNumber: '2',
                    title: l10n.widgetStep2Title,
                    subtitle: l10n.widgetStep2Desc,
                  ),
                  _buildGuideStep(
                    context: context,
                    stepNumber: '3',
                    title: l10n.widgetStep3Title,
                    subtitle: l10n.widgetStep3Desc,
                  ),
                  _buildGuideStep(
                    context: context,
                    stepNumber: '4',
                    title: l10n.widgetStep4Title,
                    subtitle: l10n.widgetStep4Desc,
                    isLast: true,
                  ),

                  const SizedBox(height: 28),

                  // PHẦN 3: ĐẶC TÍNH TỰ ĐỒNG BỘ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF161822)
                          : const Color(0xFFF3F5FA),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFE4E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.sync_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.widgetSyncTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.widgetSyncDesc,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary(context),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),

            // Floating Transparent Header (Identical to AppIconPickerScreen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  12,
                  AppSizes.pagePadding,
                  12,
                ),
                child: Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, child) {
                          final offset = _scrollController.hasClients
                              ? _scrollController.offset
                              : 0.0;
                          final titleOpacity =
                              (1.0 - (offset / 80.0)).clamp(0.0, 1.0);
                          return Opacity(
                            opacity: titleOpacity,
                            child: child,
                          );
                        },
                        child: Text(
                          l10n.homeWidgets,
                          style: AppTextStyles.pageTitle(context).copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildWidgetCard({
    required BuildContext context,
    required String title,
    required String sizeTag,
    required Color tagColor,
    required String description,
    required String deepLinkNote,
    required Widget previewWidget,
    Widget? actionButton,
  }) {
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A26) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE5E9F2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sizeTag,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 15,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  deepLinkNote,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 12),
            actionButton,
          ],
          const SizedBox(height: 14),

          // Preview Container with FittedBox to prevent any width overflow
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: previewWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsWidgetPreview(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: 310,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Mini Donut preview
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF5B5B),
                      width: 10,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1B1B1E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.thisMonthLabel,
                  style: const TextStyle(
                    fontFamily: 'ProximaSoft',
                    fontSize: 11,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '7.363.897đ',
                  style: TextStyle(
                    fontFamily: 'ProximaSoft',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF5B5B),
                  ),
                ),
                const Text(
                  '↓ 74.8%',
                  style: TextStyle(
                    fontFamily: 'ProximaSoft',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7DDC86),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.previewCategoriesSample,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'ProximaSoft',
                    fontSize: 9.5,
                    color: Color(0xFFD1D1D6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWidgetPreview(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: 310,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.previewMonthSample,
                style: const TextStyle(
                  fontFamily: 'ProximaSoft',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 2),
                    Text(
                      '5',
                      style: TextStyle(
                        fontFamily: 'ProximaSoft',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF26262B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '${l10n.previewExpenseLabel}: 7.4Mđ',
                  style: const TextStyle(
                    fontFamily: 'ProximaSoft',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF5B5B),
                  ),
                ),
                Text(
                  '${l10n.previewTxnCountLabel}: 38',
                  style: const TextStyle(
                    fontFamily: 'ProximaSoft',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7DDC86),
                  ),
                ),
                Text(
                  '${l10n.previewIncomeLabel}: 150Kđ',
                  style: const TextStyle(
                    fontFamily: 'ProximaSoft',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF59D4C8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Sample mini grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isPhoto = i >= 2 && i <= 5;
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isPhoto
                      ? const Color(0xFF4A90E2)
                      : const Color(0xFF28282E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontFamily: 'ProximaSoft',
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isPhoto ? Colors.white : const Color(0xFF8E8E93),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentWidgetPreview(BuildContext context) {
    final profileCtrl = context.watch<ProfileController>();
    final frameItem = WidgetFrames.getById(profileCtrl.widgetFrame);
    final hasFrame = !frameItem.isNone && frameItem.gradient != null;
    final borderWidth = hasFrame ? frameItem.borderWidth : 1.0;

    return Container(
      width: 170,
      height: 170,
      padding: hasFrame ? EdgeInsets.all(borderWidth) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: hasFrame ? frameItem.gradient : null,
        border: hasFrame ? null : Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(hasFrame ? (22 - borderWidth) : 21),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C3140), Color(0xFF1B1D26)],
            ),
          ),
          child: Stack(
            children: [
          // Background subtle camera icon
          Center(
            child: Icon(
              Icons.camera_alt_rounded,
              size: 38,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          // Top Badges
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Streak badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: const Row(
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 10)),
                      SizedBox(width: 2),
                      Text(
                        '5',
                        style: TextStyle(
                          fontFamily: 'ProximaSoft',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expense Badge (Translucent Frosted Red)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF6961).withValues(alpha: 0.65),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    '-45Kđ',
                    style: TextStyle(
                      fontFamily: 'ProximaSoft',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Caption & Group Info
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group_rounded, size: 10, color: Color(0xFFFFD166)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        context.l10n.previewMomentGroupSample,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'ProximaSoft',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFD166),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.previewMomentCaptionSample,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'ProximaSoft',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _buildGuideStep({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    final isDark = AppColors.isDark(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step circle & vertical line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue
                      .withValues(alpha: isDark ? 0.2 : 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Step Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
