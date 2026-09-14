import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/home_controller.dart';
import '../widgets/streak_detail_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loaded) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null && context.read<HomeController>().transactions.isEmpty) {
        context.read<HomeController>().load(uid);
      }

      _loaded = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Sinh danh sách các tháng từ tháng hiện tại ngược về quá khứ
  /// Sử dụng reverse: true giúp hiển thị tháng hiện tại ở đáy trước lập tức,
  /// khi người dùng cuộn lướt lên trên thì các tháng quá khứ mới được load lười (lazy loading).
  List<DateTime> _generateMonthsList({
    required DateTime? userCreatedAt,
    required List<TransactionModel> transactions,
  }) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    DateTime earliest = currentMonth;

    if (userCreatedAt != null) {
      final userMonth = DateTime(userCreatedAt.year, userCreatedAt.month);
      if (userMonth.isBefore(earliest)) {
        earliest = userMonth;
      }
    }

    for (final tx in transactions) {
      final txMonth = DateTime(tx.createdAt.year, tx.createdAt.month);
      if (txMonth.isBefore(earliest)) {
        earliest = txMonth;
      }
    }

    // Giới hạn an toàn tối đa 5 năm trước để tránh loop quá dài nếu userCreatedAt có lỗi timestamp 1970
    final maxPast = DateTime(now.year - 5, 1);
    if (earliest.isBefore(maxPast)) {
      earliest = maxPast;
    }

    final months = <DateTime>[];

    var iter = currentMonth;
    while (!iter.isBefore(earliest)) {
      months.add(iter);
      iter = DateTime(iter.year, iter.month - 1);
    }

    if (months.isEmpty) {
      months.add(currentMonth);
    }

    return months;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();
    final profile = context.watch<ProfileController>();
    final currency = profile.currency;

    final userCreated = profile.user?.createdAt ?? auth.user?.metadata.creationTime;

    DateTime earliestDate = userCreated ?? DateTime.now();
    if (home.transactions.isNotEmpty) {
      DateTime earliestTx = home.transactions.first.createdAt;
      for (final tx in home.transactions) {
        if (tx.createdAt.isBefore(earliestTx)) {
          earliestTx = tx.createdAt;
        }
      }
      earliestDate = earliestTx;
    }

    final months = _generateMonthsList(
      userCreatedAt: userCreated,
      transactions: home.transactions,
    );

    final totalMemesCount = home.transactions.length;
    final userStreak = home.profile?.currentStreak ?? profile.user?.currentStreak ?? 0;

    final topPadding = MediaQuery.of(context).padding.top + 62;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 20;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          // Danh sách cuộn ngược (reverse: true):
          // 1. Tháng hiện tại và Badge nằm ở đáy và HIỂN THỊ ĐẦU TIÊN tức thì (0ms).
          // 2. Người dùng cuộn lướt màn hình lên trên thì các tháng trước mới được tải lười.
          // Cuộn bên dưới header được làm mờ (blur background).
          Positioned.fill(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Cuộn từ đáy lên trên
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14, topPadding, 14, bottomPadding),
              itemCount: months.length + 1, // +1 cho thẻ Badge ở đáy
              itemBuilder: (context, index) {
                // Index 0: Thẻ Badge tổng Meme & Chuỗi ngày nằm ở vị trí dưới cùng
                if (index == 0) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      _MemeStatsBadge(
                        totalMemes: totalMemesCount,
                        streak: userStreak,
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }

                final monthIndex = index - 1;
                final month = months[monthIndex];
                final isEarliestMonth = monthIndex == months.length - 1;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mốc thời gian kỷ niệm Meme đầu tiên ở đỉnh của tháng cũ nhất
                    if (isEarliestMonth) ...[
                      _FirstMemeMilestoneHeader(
                        date: earliestDate,
                        hasTransaction: home.transactions.isNotEmpty,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _TopThreadLoop(monthNumber: month.month),
                      ),
                    ],

                    // Thẻ tháng
                    RepaintBoundary(
                      child: _MonthCalendarCard(
                        month: month,
                        allTransactions: home.transactions,
                        userCurrency: currency,
                      ),
                    ),

                    // Sợi dây nét đứt riêng biệt nối tháng này xuống tháng bên dưới
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _MonthDashedConnectorThread(
                        monthNumber: month.month,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Top Bar Header với hiệu ứng Blur nền mờ (Frosted Glassmorphism)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: AppColors.background(context).withValues(alpha: 0.72),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Row(
                        children: [
                          _TopCircleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _scrollController,
                              builder: (context, child) {
                                final offset = _scrollController.hasClients
                                    ? _scrollController.offset
                                    : 0.0;
                                final titleOpacity =
                                    (1.0 - (offset / 120.0)).clamp(0.0, 1.0);
                                return Opacity(
                                  opacity: titleOpacity,
                                  child: child,
                                );
                              },
                              child: Text(
                                locale.toLowerCase().startsWith('vi') ? 'Kỷ niệm' : 'Moments',
                                style: AppTextStyles.pageTitle(context).copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
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
          ),
        ],
      ),
    );
  }
}

/// Thẻ Badge tổng số Meme & Chuỗi ngày (💛 n Meme | 🔥 chuỗi n ngày)
class _MemeStatsBadge extends StatelessWidget {
  final int totalMemes;
  final int streak;

  const _MemeStatsBadge({
    required this.totalMemes,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final locale = Localizations.localeOf(context).toString();
    final isVi = locale.toLowerCase().startsWith('vi');

    final countFormatted = NumberFormat.decimalPattern(isVi ? 'vi_VN' : 'en_US').format(totalMemes);
    final memeLabel = isVi ? 'Meme' : (totalMemes == 1 ? 'Meme' : 'Memes');
    final streakText = isVi
        ? '🔥 chuỗi $streak ngày'
        : (streak == 1 ? '🔥 1-day streak' : '🔥 $streak-day streak');

    return InkWell(
      onTap: () {
        StreakDetailSheet.show(context);
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131418) : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(
            color: isDark ? const Color(0xFF252936) : const Color(0xFFE2E6EE),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 💛 n Meme / Memes
            Text(
              '💛 $countFormatted $memeLabel',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF14151B),
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 14),
            // Divider |
            Container(
              width: 1.2,
              height: 14,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(width: 14),
            // 🔥 chuỗi n ngày / 🔥 n-day streak
            Text(
              streakText,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF14151B),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner mốc thời gian kỷ niệm Meme đầu tiên hoặc ngày tham gia ở đỉnh lịch
class _FirstMemeMilestoneHeader extends StatelessWidget {
  final DateTime date;
  final bool hasTransaction;

  const _FirstMemeMilestoneHeader({
    required this.date,
    required this.hasTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final locale = Localizations.localeOf(context).toString();
    final isVi = locale.toLowerCase().startsWith('vi');

    final titleText = hasTransaction
        ? (isVi
            ? 'Meme đầu tiên của bạn đã được gửi vào'
            : 'Your first Meme was sent on')
        : (isVi
            ? 'Bạn đã tham gia Meme vào'
            : 'You joined Meme on');

    final dateText = isVi
        ? 'ngày ${date.day} thg ${date.month}, ${date.year}'
        : DateFormat('MMMM d, yyyy', 'en_US').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon lịch trái tim
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 22,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.55),
                ),
                Positioned(
                  bottom: 11,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 9.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.65)
                        : Colors.black.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.65)
                  : Colors.black.withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.90)
                  : Colors.black.withValues(alpha: 0.90),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sợi dây nét đứt đỉnh đầu
class _TopThreadLoop extends StatelessWidget {
  final int monthNumber;

  const _TopThreadLoop({required this.monthNumber});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dashColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return SizedBox(
      width: 52,
      height: 38,
      child: CustomPaint(
        painter: _MonthUniqueDashedPainter(
          month: monthNumber,
          color: dashColor,
          isTopHeader: true,
        ),
      ),
    );
  }
}

/// Widget sợi dây nét đứt kết nối: Mỗi tháng có 1 kiểu uốn lượn riêng biệt trong 12 tháng
class _MonthDashedConnectorThread extends StatelessWidget {
  final int monthNumber;

  const _MonthDashedConnectorThread({required this.monthNumber});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dashColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return SizedBox(
      width: 64,
      height: 52,
      child: CustomPaint(
        painter: _MonthUniqueDashedPainter(
          month: monthNumber,
          color: dashColor,
        ),
      ),
    );
  }
}

/// CustomPainter vẽ 12 kiểu dây nét đứt khác nhau cho 12 tháng (Liền mạch, tinh xảo)
class _MonthUniqueDashedPainter extends CustomPainter {
  final int month;
  final Color color;
  final bool isTopHeader;

  _MonthUniqueDashedPainter({
    required this.month,
    required this.color,
    this.isTopHeader = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerX = size.width / 2;
    final h = size.height;

    final m = ((month - 1) % 12) + 1; // 1 đến 12

    if (isTopHeader) {
      // Header loop kiểu 9 liền nét
      path.moveTo(centerX - 4, 0);
      path.cubicTo(centerX + 18, 6, centerX + 22, 22, centerX + 4, 24);
      path.cubicTo(centerX - 16, 26, centerX - 12, 10, centerX + 2, 12);
      path.cubicTo(centerX + 12, 14, centerX + 2, 30, centerX, h);
      _drawDashedPath(canvas, path, paint, dashLength: 4.5, dashSpace: 3.5);
      return;
    }

    switch (m) {
      case 1:
        // Tháng 1: Loop 360 độ xoắn tròn số 9 tinh tế
        path.moveTo(centerX, 0);
        path.cubicTo(centerX - 4, h * 0.2, centerX - 18, h * 0.28, centerX - 18, h * 0.48);
        path.cubicTo(centerX - 18, h * 0.68, centerX + 18, h * 0.68, centerX + 18, h * 0.48);
        path.cubicTo(centerX + 18, h * 0.32, centerX + 2, h * 0.32, centerX - 4, h * 0.52);
        path.cubicTo(centerX - 10, h * 0.72, centerX + 2, h * 0.88, centerX, h);
        break;

      case 2:
        // Tháng 2: Romantic Ribbon Swirl (Dải ruy băng xoắn chéo mềm mại)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX - 18, h * 0.15, centerX - 22, h * 0.38, centerX - 4, h * 0.44);
        path.cubicTo(centerX + 14, h * 0.50, centerX + 22, h * 0.35, centerX + 16, h * 0.20);
        path.cubicTo(centerX + 8, h * 0.08, centerX - 14, h * 0.68, centerX + 2, h * 0.80);
        path.cubicTo(centerX + 14, h * 0.88, centerX + 6, h * 0.98, centerX, h);
        break;

      case 3:
        // Tháng 3: Spring Leaf Clover Loop (Xoắn 3 nhịp chồi non mùa xuân)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX + 20, h * 0.14, centerX + 24, h * 0.32, centerX + 2, h * 0.36);
        path.cubicTo(centerX - 22, h * 0.40, centerX - 22, h * 0.64, centerX - 2, h * 0.68);
        path.cubicTo(centerX + 18, h * 0.72, centerX + 16, h * 0.90, centerX, h);
        break;

      case 4:
        // Tháng 4: Figure-8 Infinity (Nút thắt số 8 vô cực liền mạch một nét)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX + 16, h * 0.15, centerX + 20, h * 0.35, centerX, h * 0.5);
        path.cubicTo(centerX - 20, h * 0.65, centerX - 16, h * 0.85, centerX, h);
        break;

      case 5:
        // Tháng 5: Bowknot Loop (Dây nơ uốn vòng đôi nhịp nhàng)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX - 18, h * 0.2, centerX - 22, h * 0.45, centerX, h * 0.45);
        path.cubicTo(centerX + 22, h * 0.45, centerX + 18, h * 0.7, centerX, h * 0.7);
        path.cubicTo(centerX - 8, h * 0.7, centerX - 4, h * 0.9, centerX, h);
        break;

      case 6:
        // Tháng 6: Zigzag Lò xo góc bo mềm
        path.moveTo(centerX, 0);
        path.cubicTo(centerX - 18, h * 0.15, centerX - 20, h * 0.35, centerX - 12, h * 0.38);
        path.cubicTo(centerX + 20, h * 0.45, centerX + 18, h * 0.65, centerX + 8, h * 0.68);
        path.cubicTo(centerX - 14, h * 0.75, centerX - 4, h * 0.92, centerX, h);
        break;

      case 7:
        // Tháng 7: Double Helix Loops (2 vòng xoắn nối tiếp)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX - 16, h * 0.15, centerX - 14, h * 0.35, centerX + 4, h * 0.35);
        path.cubicTo(centerX + 20, h * 0.35, centerX + 14, h * 0.65, centerX - 4, h * 0.65);
        path.cubicTo(centerX - 16, h * 0.65, centerX + 12, h * 0.85, centerX, h);
        break;

      case 8:
        // Tháng 8: Diamond Knot (Nút thắt hình thoi mở rộng)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX - 22, h * 0.25, centerX - 22, h * 0.45, centerX, h * 0.5);
        path.cubicTo(centerX + 22, h * 0.55, centerX + 22, h * 0.75, centerX, h);
        break;

      case 9:
        // Tháng 9: Xoáy ốc nghiêng bên phải (Spiral Curl)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX + 20, h * 0.22, centerX + 22, h * 0.55, centerX, h * 0.52);
        path.cubicTo(centerX - 14, h * 0.5, centerX - 12, h * 0.78, centerX, h);
        break;

      case 10:
        // Tháng 10: Double Ribbon Wave (Làn sóng ruy băng kép mềm mại)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX + 18, h * 0.22, centerX - 18, h * 0.5, centerX + 12, h * 0.75);
        path.cubicTo(centerX + 4, h * 0.88, centerX - 4, h * 0.95, centerX, h);
        break;

      case 11:
        // Tháng 11: Tilted Oval Loop (Vòng elip xoắn nằm nghiêng)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX - 20, h * 0.22, centerX + 20, h * 0.35, centerX + 10, h * 0.55);
        path.cubicTo(centerX - 18, h * 0.65, centerX - 4, h * 0.85, centerX, h);
        break;

      case 12:
      default:
        // Tháng 12: Festive Clover Knot (Nút thắt hoa lễ hội cuối năm)
        path.moveTo(centerX, 0);
        path.cubicTo(centerX - 18, h * 0.2, centerX - 16, h * 0.45, centerX, h * 0.45);
        path.cubicTo(centerX + 18, h * 0.45, centerX + 16, h * 0.75, centerX, h * 0.75);
        path.cubicTo(centerX - 8, h * 0.75, centerX + 4, h * 0.9, centerX, h);
        break;
    }

    _drawDashedPath(canvas, path, paint, dashLength: 4.5, dashSpace: 3.5);
  }

  @override
  bool shouldRepaint(covariant _MonthUniqueDashedPainter oldDelegate) =>
      oldDelegate.month != month ||
      oldDelegate.color != color ||
      oldDelegate.isTopHeader != isTopHeader;
}

/// Hàm phụ trợ vẽ đường nét đứt dọc theo Path bất kỳ
void _drawDashedPath(
  Canvas canvas,
  Path source,
  Paint paint, {
  required double dashLength,
  required double dashSpace,
}) {
  for (final pathMetric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < pathMetric.length) {
      final nextDistance = math.min(distance + dashLength, pathMetric.length);
      final extractPath = pathMetric.extractPath(distance, nextDistance);
      canvas.drawPath(extractPath, paint);
      distance += dashLength + dashSpace;
    }
  }
}

/// Thẻ tháng hoàn chỉnh (Month Card)
class _MonthCalendarCard extends StatelessWidget {
  final DateTime month;
  final List<TransactionModel> allTransactions;
  final String userCurrency;

  const _MonthCalendarCard({
    required this.month,
    required this.allTransactions,
    required this.userCurrency,
  });

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime?> _daysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final days = <DateTime?>[];

    // Thứ 2 = 1, CN = 7
    for (int i = 0; i < firstDay.weekday - 1; i++) {
      days.add(null);
    }

    for (int day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final isDark = AppColors.isDark(context);

    // Gom nhóm giao dịch theo ngày và tính tổng thu/chi trong 1 vòng lặp O(N) duy nhất
    final Map<int, List<TransactionModel>> dayTxMap = {};
    double totalExpense = 0.0;
    double totalIncome = 0.0;

    for (final tx in allTransactions) {
      if (tx.createdAt.year == month.year && tx.createdAt.month == month.month) {
        (dayTxMap[tx.createdAt.day] ??= []).add(tx);
        if (tx.isPersonalExpense) {
          totalExpense += tx.amount;
        } else if (tx.isPersonalIncome) {
          totalIncome += tx.amount;
        }
      }
    }

    // Tiêu đề tháng
    final rawMonthTitle = DateFormat('MMMM, yyyy', locale).format(month);
    final monthTitle = rawMonthTitle.isNotEmpty
        ? rawMonthTitle[0].toUpperCase() + rawMonthTitle.substring(1)
        : rawMonthTitle;

    // Danh sách nhãn thứ T2 - CN
    final weekdayLabels = List.generate(7, (index) {
      final day = DateTime(2024, 1, 1 + index); // Monday
      if (locale.toLowerCase().startsWith('vi')) {
        return index == 6 ? 'CN' : 'T${index + 2}';
      }
      return DateFormat('E', locale).format(day).toUpperCase();
    });

    final days = _daysInMonth(month);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rowCount = (days.length / 7).ceil();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131418) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF222530) : const Color(0xFFE6E9F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tiêu đề Tháng, Năm (vd: Tháng 12, 2025)
          Text(
            monthTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFC8CDD8) : const Color(0xFF2D313E),
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 16),

          // 2 Ô Tổng Chi & Tổng Thu
          Row(
            children: [
              // Ô Chi
              Expanded(
                child: _MonthlySummaryBox(
                  label: l10n.expense,
                  icon: Icons.arrow_outward_rounded,
                  amountText: totalExpense > 0
                      ? '-${AppCurrencyFormatter.formatFromVnd(amountVnd: totalExpense, currency: userCurrency)}'
                      : '0₫',
                  accentColor: const Color(0xFFFF5252),
                  badgeBgColor: isDark
                      ? const Color(0xFFFF5252).withValues(alpha: 0.15)
                      : const Color(0xFFFFEBEE),
                ),
              ),
              const SizedBox(width: 10),
              // Ô Thu
              Expanded(
                child: _MonthlySummaryBox(
                  label: l10n.income,
                  icon: Icons.south_east_rounded,
                  amountText: totalIncome > 0
                      ? '+${AppCurrencyFormatter.formatFromVnd(amountVnd: totalIncome, currency: userCurrency)}'
                      : '0₫',
                  accentColor: const Color(0xFF2ECC71),
                  badgeBgColor: isDark
                      ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
                      : const Color(0xFFE8F8F0),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Hàng thứ trong tuần (T2, T3, T4, T5, T6, T7, CN)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: List.generate(7, (index) {
                final isWeekend = index >= 5;
                return Expanded(
                  child: Center(
                    child: Text(
                      weekdayLabels[index],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isWeekend
                            ? AppColors.primaryBlue
                            : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 12),

          // Lưới ngày siêu nhẹ (Lightweight 7-column Row layout, 0ms render không dùng GridView/shrinkWrap)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(rowCount, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    if (cellIndex >= days.length) {
                      return const Expanded(child: SizedBox.shrink());
                    }

                    final date = days[cellIndex];
                    if (date == null) {
                      return const Expanded(child: SizedBox.shrink());
                    }

                    final dayTransactions = dayTxMap[date.day] ?? const <TransactionModel>[];
                    final isToday = _sameDate(date, now);
                    final isFuture = DateTime(date.year, date.month, date.day).isAfter(today);
                    final hasData = dayTransactions.isNotEmpty;

                    return Expanded(
                      child: _CalendarDayCell(
                        date: date,
                        isToday: isToday,
                        isFuture: isFuture,
                        hasData: hasData,
                        transactions: dayTransactions,
                        onTap: hasData
                            ? () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.dayDetail,
                                  arguments: date,
                                );
                              }
                            : null, // Không bấm được nếu là ngày chưa chụp
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Ô tóm tắt Tổng Chi / Tổng Thu trong thẻ tháng
class _MonthlySummaryBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final String amountText;
  final Color accentColor;
  final Color badgeBgColor;

  const _MonthlySummaryBox({
    required this.label,
    required this.icon,
    required this.amountText,
    required this.accentColor,
    required this.badgeBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0E12) : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1F222D) : const Color(0xFFE8ECF2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge: [↗ Chi] hoặc [↘ Thu]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: accentColor,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Số tiền
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amountText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF14151B),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô hiển thị từng ngày trong lưới lịch (Dấu x ở ngày chưa chụp, Badge số lượng cho >= 3 giao dịch)
class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isFuture;
  final bool hasData;
  final List<TransactionModel> transactions;
  final VoidCallback? onTap;

  const _CalendarDayCell({
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.hasData,
    required this.transactions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Widget phần đầu (Ảnh sticker / dấu x / ô xám mờ)
    Widget topWidget;

    if (hasData) {
      if (transactions.length == 1) {
        topWidget = _SingleImageSticker(
          transaction: transactions.first,
          isToday: isToday,
        );
      } else {
        topWidget = _StackedImageSticker(
          firstTransaction: transactions[0],
          secondTransaction: transactions[1],
          isToday: isToday,
        );
      }
    } else if (isFuture) {
      // Ngày tương lai: Ô tròn xám mờ
      topWidget = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E212B) : const Color(0xFFE2E5EC),
        ),
      );
    } else {
      // Ngày quá khứ/hôm nay chưa chụp: DẤU X tinh tế, viền tròn mờ (như Locket)
      topWidget = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.22)
                : const Color(0xFFC9C3CF),
            width: 1.3,
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 17,
          color: isDark
              ? Colors.white.withValues(alpha: 0.38)
              : const Color(0xFF9B93A5),
        ),
      );
    }

    // Nếu ngày có từ 3 giao dịch trở lên -> Thêm Badge số lượng giao dịch ở góc trên bên phải
    final showCountBadge = hasData && transactions.length >= 3;
    final displayedTopWidget = showCountBadge
        ? Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              topWidget,
              Positioned(
                top: -2,
                right: -3,
                child: _TransactionCountBadge(
                  count: transactions.length,
                ),
              ),
            ],
          )
        : topWidget;

    // Màu chữ số ngày
    final Color dayNumberColor;
    if (isToday) {
      dayNumberColor = const Color(0xFF29B6F6); // Cyan / Bright Blue
    } else if (isFuture) {
      dayNumberColor = isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);
    } else {
      dayNumberColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    }

    final cellContent = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Phần icon/sticker ở trên
        SizedBox(
          height: 38,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: displayedTopWidget,
            ),
          ),
        ),
        const SizedBox(height: 3),
        // Số ngày + Chấm dot nếu là hôm nay
        Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
            color: dayNumberColor,
            height: 1.0,
          ),
        ),
        if (isToday) ...[
          const SizedBox(height: 2),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF29B6F6),
              shape: BoxShape.circle,
            ),
          ),
        ] else ...[
          const SizedBox(height: 6),
        ],
      ],
    );

    if (onTap == null) {
      return cellContent;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: cellContent,
    );
  }
}

/// Huy hiệu số lượng giao dịch cho các ngày có từ 3 giao dịch trở lên
class _TransactionCountBadge extends StatelessWidget {
  final int count;

  const _TransactionCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF388AF6),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isDark ? const Color(0xFF131418) : Colors.white,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Sticker 1 ảnh bo góc
class _SingleImageSticker extends StatelessWidget {
  final TransactionModel transaction;
  final bool isToday;

  const _SingleImageSticker({
    required this.transaction,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return _StickerFrame(
      transaction: transaction,
      size: 36,
      isToday: isToday,
    );
  }
}

/// Sticker ảnh xếp chồng (Stacked Polaroid effect)
class _StackedImageSticker extends StatelessWidget {
  final TransactionModel firstTransaction;
  final TransactionModel secondTransaction;
  final bool isToday;

  const _StackedImageSticker({
    required this.firstTransaction,
    required this.secondTransaction,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Tấm ảnh phía sau nghiêng sang phải
          Positioned(
            right: 1,
            top: 2,
            child: Transform.rotate(
              angle: 12 * math.pi / 180,
              child: _StickerFrame(
                transaction: secondTransaction,
                size: 32,
                isToday: false,
              ),
            ),
          ),
          // Tấm ảnh phía trước nghiêng sang trái
          Positioned(
            left: 1,
            top: 2,
            child: Transform.rotate(
              angle: -8 * math.pi / 180,
              child: _StickerFrame(
                transaction: firstTransaction,
                size: 33,
                isToday: isToday,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung ảnh sticker bo góc tròn với viền màu đỏ (Chi tiêu) hoặc xanh lá (Thu nhập)
class _StickerFrame extends StatelessWidget {
  final TransactionModel transaction;
  final double size;
  final bool isToday;

  const _StickerFrame({
    required this.transaction,
    required this.size,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense' && !transaction.isGroupContribution;
    final typeColor = isExpense ? AppColors.expense : AppColors.income;
    final radius = BorderRadius.circular(size * 0.32);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: typeColor,
        borderRadius: radius,
        border: Border.all(
          color: typeColor,
          width: isToday ? 2.0 : 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? const Color(0xFF29B6F6).withValues(alpha: 0.45)
                : typeColor.withValues(alpha: 0.35),
            blurRadius: isToday ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: ColoredBox(
          color: const Color(0xFF1E212B),
          child: TransactionMomentImage(
            imageUrl: transaction.displayImageUrl,
            category: transaction.category,
            categoryIconCodePoint: transaction.categoryIconCodePoint,
            categoryColorHex: transaction.categoryColorHex,
            caption: null,
            width: size,
            height: size,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(size * 0.28),
            isVideo: transaction.isVideo,
          ),
        ),
      ),
    );
  }
}

/// Nút tròn trên thanh AppBar
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
        width: 44,
        height: 44,
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
          size: 19,
        ),
      ),
    );
  }
}