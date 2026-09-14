import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_icon_registry.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../models/rewind_data.dart';
import '../models/rewind_period.dart';

class RewindSummaryStory extends StatefulWidget {
  // ═════════════════════════════════════════════════════════════════════════
  // 🎨 TÙY CHỈNH VÙNG SÁNG (SPOTLIGHT GLOW CONFIGURATION)
  // Bạn có thể dễ dàng thay đổi vị trí, kích thước, bán kính và màu sắc tại đây:
  // ═════════════════════════════════════════════════════════════════════════
  static const double glowWidth = 320.0; // Chiều rộng vùng sáng
  static const double glowHeight = 220.0; // Chiều cao vùng sáng
  static const double glowTopOffset = -15.0; // Vị trí cách đỉnh (âm = nhô lên trên)
  static const double glowRightOffset = -50.0; // Vị trí sang phải
  static const Alignment glowCenter = Alignment(0.25, -0.15); // Tâm điểm phát sáng
  static const double glowRadius = 0.78; // Bán kính góc tỏa sáng

  // Màu sắc & độ trong suốt của các tầng sáng (Lõi trong -> Tầng giữa -> Tầng ngoài)
  static final Color glowCenterColor = const Color(0xFFFBBF24).withValues(alpha: 0.42); // Lõi vàng sáng
  static final Color glowMidColor = const Color(0xFFF59E0B).withValues(alpha: 0.24); // Tầng giữa hổ phách
  static final Color glowOuterColor = const Color(0xFFD97706).withValues(alpha: 0.08); // Tầng viền mờ

  final RewindData data;
  final String currency;
  final String userName;

  const RewindSummaryStory({
    super.key,
    required this.data,
    required this.currency,
    required this.userName,
  });

  @override
  State<RewindSummaryStory> createState() => _RewindSummaryStoryState();
}

class _RewindSummaryStoryState extends State<RewindSummaryStory>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  bool _isProcessing = false;
  AnimationController? _animController;
  Animation<double>? _fadeAnim;
  Animation<double>? _scaleAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    if (_animController == null) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      _fadeAnim = CurvedAnimation(
        parent: _animController!,
        curve: Curves.easeOut,
      );
      _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController!,
          curve: Curves.easeOutBack,
        ),
      );
      _animController!.forward();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _initAnimations();
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  Future<File?> _captureCardImage() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/meme_rewind_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      debugPrint('Error capturing rewind card: $e');
      return null;
    }
  }

  Future<void> _shareCard() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final file = await _captureCardImage();
      if (file != null && mounted) {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: context.l10n.rewindShareText,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveCard() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final file = await _captureCardImage();
      if (file != null && mounted) {
        await Gal.putImage(file.path);
        if (mounted) {
          AppToast.show(
            context,
            context.l10n.rewindSaveSuccess,
            icon: Icons.check_circle_outline_rounded,
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _getDayOfWeekName(DateTime date, bool isEn) {
    if (isEn) {
      return DateFormat('EEEE', 'en_US').format(date);
    }
    switch (date.weekday) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
      default:
        return 'Chủ Nhật';
    }
  }

  String _getPeriodDisplay(BuildContext context, RewindPeriod period) {
    final title = period.getTitle(context);
    final yearStr = '${period.startDateTime.year}';
    if (title.contains(yearStr)) {
      return title;
    }
    return '$title • $yearStr';
  }

  @override
  Widget build(BuildContext context) {
    _initAnimations();
    final l10n = context.l10n;
    final data = widget.data;
    final currency = widget.currency;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    final topCat = data.categories.isNotEmpty ? data.categories.first : null;
    final biggestExpense =
        data.topExpenses.isNotEmpty ? data.topExpenses.first : null;
    final biggestDay = data.biggestDay;

    // Moments with real pictures
    final photoMoments = data.momentTransactions
        .where((t) => t.displayImageUrl.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 68, 18, 20),
      child: FadeTransition(
        opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
        child: ScaleTransition(
          scale: _scaleAnim ?? const AlwaysStoppedAnimation(1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ═══════════════════════════════════════════════════════════════
              // CAPTURABLE GEN-Z SUMMARY RECAP CARD
              // ═══════════════════════════════════════════════════════════════
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF141728),
                        Color(0xFF0F1221),
                        Color(0xFF0A0C16),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.22),
                        blurRadius: 36,
                        spreadRadius: -4,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        // 🌟 VÙNG SÁNG VÀNG ẤM ÁP (SPOTLIGHT AMBIENT GLOW CHUẨN MẪU)
                        Positioned(
                          top: RewindSummaryStory.glowTopOffset,
                          right: RewindSummaryStory.glowRightOffset,
                          left: 20,
                          child: Center(
                            child: Container(
                              width: RewindSummaryStory.glowWidth,
                              height: RewindSummaryStory.glowHeight,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  center: RewindSummaryStory.glowCenter,
                                  radius: RewindSummaryStory.glowRadius,
                                  colors: [
                                    RewindSummaryStory.glowCenterColor,
                                    RewindSummaryStory.glowMidColor,
                                    RewindSummaryStory.glowOuterColor,
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.4, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Card Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. TOP HEADER ROW (⚡ Meme Rewind + Period)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('⚡', style: TextStyle(fontSize: 13)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Meme Rewind',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _getPeriodDisplay(context, data.period),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // 2. HERO TOTAL EXPENSE (Big Glow Highlight)
                              Text(
                                isEn ? 'Total Expense' : l10n.rewindTotalExpense,
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                AppCurrencyFormatter.formatFromVnd(
                                  amountVnd: data.totalExpense,
                                  currency: currency,
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFACC15),
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.2,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x88F59E0B),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),

                              Text(
                                isEn
                                    ? (data.totalTransactions == 1
                                        ? '1 transaction'
                                        : '${data.totalTransactions} transactions')
                                    : '${data.totalTransactions} giao dịch',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 3. OVERLAPPING AVATAR / MOMENT CIRCLES
                              _buildMomentAvatarRow(photoMoments, data),
                              const SizedBox(height: 20),

                              // 4. TILE: CHI NHIỀU NHẤT (Top Spending / Category)
                              _buildInfoTile(
                                icon: Icons.emoji_events_rounded,
                                iconColor: const Color(0xFFFBBF24),
                                iconBgColor:
                                    const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                label: isEn ? 'Highest Spending' : 'Chi nhiều nhất',
                                value: topCat != null
                                    ? '${BudgetNameLocalizer.display(context, topCat.name)} ${biggestExpense != null && biggestExpense.note.isNotEmpty ? '• ${biggestExpense.note}' : ''}'
                                    : (biggestExpense?.category ?? (isEn ? 'None' : 'Chưa có')),
                              ),
                              const SizedBox(height: 10),

                              // 5. TILE: NGÀY CHI NHIỀU NHẤT (Peak Spending Day)
                              _buildInfoTile(
                                icon: Icons.calendar_month_rounded,
                                iconColor: const Color(0xFF818CF8),
                                iconBgColor:
                                    const Color(0xFF6366F1).withValues(alpha: 0.22),
                                label: isEn ? 'Peak Spending Day' : 'Ngày chi nhiều nhất',
                                value: biggestDay != null && biggestDay.amount > 0
                                    ? '${_getDayOfWeekName(biggestDay.date, isEn)} • ${AppCurrencyFormatter.formatFromVnd(amountVnd: biggestDay.amount, currency: currency)}'
                                    : (isEn ? 'No big spikes' : 'Không có biến động lớn'),
                              ),
                              const SizedBox(height: 12),

                              // 6. BOTTOM 2-COLUMN SPLIT INSIGHT CARDS
                              Row(
                                children: [
                                  // Left Insight Card: Khoảnh khắc thoải mái / Top Vibe
                                  Expanded(
                                    child: _buildInsightCard(
                                      icon: Icons.auto_awesome_rounded,
                                      iconColor: const Color(0xFFFACC15),
                                      badgeTag: isEn ? 'Comfortable Moments' : 'Khoảnh khắc thoải mái',
                                      badgeColor: const Color(0xFF34D399),
                                      bigCount: topCat != null
                                          ? topCat.count
                                          : data.expenseCount,
                                      percentage: topCat?.percentage ?? 0,
                                      amountText: topCat != null
                                          ? AppCurrencyFormatter.formatFromVnd(
                                              amountVnd: topCat.amount,
                                              currency: currency)
                                          : AppCurrencyFormatter.formatFromVnd(
                                              amountVnd: 0,
                                              currency: currency),
                                      progressColor: const Color(0xFF10B981),
                                      photoUrls: photoMoments
                                          .take(3)
                                          .map((e) => e.displayImageUrl)
                                          .toList(),
                                      isEn: isEn,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Right Insight Card: Cần xem lại / Biggest single item
                                  Expanded(
                                    child: _buildInsightCard(
                                      icon: Icons.search_rounded,
                                      iconColor: const Color(0xFF38BDF8),
                                      badgeTag: isEn ? 'Need Review' : 'Cần xem lại',
                                      badgeColor: const Color(0xFFFB923C),
                                      bigCount: biggestExpense != null ? 1 : 0,
                                      percentage: (biggestExpense != null &&
                                              data.totalExpense > 0)
                                          ? (biggestExpense.amount /
                                                  data.totalExpense) *
                                              100
                                          : 0,
                                      amountText: biggestExpense != null
                                          ? AppCurrencyFormatter.formatFromVnd(
                                              amountVnd: biggestExpense.amount,
                                              currency: currency)
                                          : AppCurrencyFormatter.formatFromVnd(
                                              amountVnd: 0,
                                              currency: currency),
                                      progressColor: const Color(0xFFF97316),
                                      photoUrls: biggestExpense != null &&
                                              biggestExpense
                                                  .displayImageUrl.isNotEmpty
                                          ? [biggestExpense.displayImageUrl]
                                          : [],
                                      isEn: isEn,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════════
              // ACTION BUTTONS: [ LƯU ẢNH ] & [ CHIA SẺ ]
              // ═══════════════════════════════════════════════════════════════
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isProcessing ? null : _saveCard,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.rewindSaveCard,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _isProcessing ? null : _shareCard,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF6366F1).withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.rewindShareCard,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═════════════════════════════════════════════════════════════════════════

  /// Overlapping avatar / moment row
  Widget _buildMomentAvatarRow(
      List<TransactionModel> photoMoments, RewindData data) {
    if (photoMoments.isNotEmpty) {
      final displayList = photoMoments.take(5).toList();
      return SizedBox(
        height: 48,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(displayList.length, (index) {
              final tx = displayList[index];
              return Container(
                margin: EdgeInsets.only(left: index * 32.0),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    tx.displayImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF312E81),
                      child: const Icon(Icons.image_rounded,
                          color: Colors.white70, size: 20),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    }

    // Fallback: Category Icon Avatar Ring Stack
    final categories = data.categories.take(5).toList();
    if (categories.isEmpty) {
      return const SizedBox(height: 8);
    }

    return SizedBox(
      height: 48,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(categories.length, (index) {
            final cat = categories[index];
            final color = _parseHexColor(cat.colorHex);
            return Container(
              margin: EdgeInsets.only(left: index * 32.0),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.3),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  cat.iconCodePoint != null
                      ? AppIconRegistry.fromCodePoint(cat.iconCodePoint!)
                      : Icons.category_rounded,
                  color: color,
                  size: 20,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Horizontal Info Tile (Chi nhiều nhất, Ngày chi nhiều nhất)
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Split Insight Card (Khoảnh khắc thoải mái / Cần xem lại)
  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required String badgeTag,
    required Color badgeColor,
    required int bigCount,
    required double percentage,
    required String amountText,
    required Color progressColor,
    required List<String> photoUrls,
    required bool isEn,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + mini photo previews
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const Spacer(),
              if (photoUrls.isNotEmpty)
                SizedBox(
                  height: 22,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(
                      photoUrls.take(2).length,
                      (i) => Container(
                        margin: EdgeInsets.only(left: i * 14.0),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            photoUrls[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Big Count
          Text(
            '$bigCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isEn
                ? (bigCount == 1 ? 'transaction' : 'transactions')
                : 'giao dịch',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.05, 1.0),
              minHeight: 4.5,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 6),

          // Percentage & Amount Subtitle
          Text(
            '${percentage.toStringAsFixed(1)}% • $amountText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Badge Tag Name
          Text(
            badgeTag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF38BDF8);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF38BDF8);
    }
  }
}
