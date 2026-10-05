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
                        dateOfBirth: profile.user?.dateOfBirth,
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8.5),
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
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF14151B),
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 10),
            // Divider |
            Container(
              width: 1.2,
              height: 12,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(width: 10),
            // 🔥 chuỗi n ngày / 🔥 n-day streak
            Text(
              streakText,
              style: TextStyle(
                fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon lịch trái tim
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
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
                  size: 18,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.55),
                ),
                Positioned(
                  bottom: 9,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 8,
                    color: isDark
                      ? Colors.white.withValues(alpha: 0.65)
                      : Colors.black.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.65)
                  : Colors.black.withValues(alpha: 0.65),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            dateText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.90)
                  : Colors.black.withValues(alpha: 0.90),
              height: 1.3,
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
      width: 44,
      height: 28,
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
      width: 52,
      height: 38,
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

enum _CalendarFilterMode {
  all,
  expense,
  income,
}

String _formatDailyCompact({
  required double amountVnd,
  required String? currency,
  required bool isVi,
}) {
  if (amountVnd <= 0) return '';
  final normCurrency = AppCurrencyFormatter.normalizeCurrency(currency);
  if (normCurrency == 'USD') {
    final usd = AppCurrencyFormatter.fromVnd(amountVnd: amountVnd, currency: 'USD');
    if (usd < 1) {
      return '\$${usd.toStringAsFixed(2)}';
    }
    if (usd < 1000) {
      return '\$${usd.round()}';
    }
    if (usd < 1000000) {
      final k = usd / 1000;
      final text = k >= 10 || k % 1 == 0 ? k.round().toString() : k.toStringAsFixed(1);
      return '\$${text}k';
    }
    final m = usd / 1000000;
    final text = m >= 10 || m % 1 == 0 ? m.round().toString() : m.toStringAsFixed(1);
    return '\$${text}M';
  }

  // VND
  if (amountVnd < 1000) {
    return '${amountVnd.round()}đ';
  }
  if (amountVnd < 1000000) {
    return '${(amountVnd / 1000).round()}k';
  }
  if (amountVnd < 1000000000) {
    final m = amountVnd / 1000000;
    final text = m >= 10 || m % 1 == 0 ? m.round().toString() : m.toStringAsFixed(1);
    return isVi ? '${text}tr' : '${text}M';
  }
  final b = amountVnd / 1000000000;
  final text = b >= 10 || b % 1 == 0 ? b.round().toString() : b.toStringAsFixed(1);
  return isVi ? '${text}tỷ' : '${text}B';
}

/// Thẻ tháng hoàn chỉnh (Month Card)
class _MonthCalendarCard extends StatefulWidget {
  final DateTime month;
  final List<TransactionModel> allTransactions;
  final String userCurrency;
  final DateTime? dateOfBirth;

  const _MonthCalendarCard({
    required this.month,
    required this.allTransactions,
    required this.userCurrency,
    this.dateOfBirth,
  });

  @override
  State<_MonthCalendarCard> createState() => _MonthCalendarCardState();
}

class _MonthCalendarCardState extends State<_MonthCalendarCard> {
  _CalendarFilterMode _selectedFilter = _CalendarFilterMode.all;

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
    final isVi = locale.toLowerCase().startsWith('vi');
    final isDark = AppColors.isDark(context);

    // Gom nhóm giao dịch theo ngày và tính tổng thu/chi trong 1 vòng lặp O(N) duy nhất
    final Map<int, List<TransactionModel>> dayTxMap = {};
    double totalExpense = 0.0;
    double totalIncome = 0.0;

    for (final tx in widget.allTransactions) {
      if (tx.createdAt.year == widget.month.year &&
          tx.createdAt.month == widget.month.month) {
        (dayTxMap[tx.createdAt.day] ??= []).add(tx);
        if (tx.isPersonalExpense) {
          totalExpense += tx.amount;
        } else if (tx.isPersonalIncome) {
          totalIncome += tx.amount;
        }
      }
    }

    // Tiêu đề tháng
    final rawMonthTitle =
        DateFormat('MMMM, yyyy', locale).format(widget.month);
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

    final days = _daysInMonth(widget.month);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rowCount = (days.length / 7).ceil();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131418) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFC8CDD8) : const Color(0xFF2D313E),
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 10),

          // 2 Ô Tổng Chi & Tổng Thu (Giữ nguyên chiều rộng, hỗ trợ bấm để lọc)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                // Ô Chi
                Expanded(
                  child: _MonthlySummaryBox(
                    label: l10n.expense,
                    icon: Icons.arrow_outward_rounded,
                    amountText: totalExpense > 0
                        ? '-${AppCurrencyFormatter.formatFromVnd(amountVnd: totalExpense, currency: widget.userCurrency)}'
                        : '0₫',
                    accentColor: const Color(0xFFFF5252),
                    badgeBgColor: isDark
                        ? const Color(0xFFFF5252).withValues(alpha: 0.15)
                        : const Color(0xFFFFEBEE),
                    isSelected: _selectedFilter == _CalendarFilterMode.expense,
                    isDimmed: _selectedFilter == _CalendarFilterMode.income,
                    onTap: () {
                      setState(() {
                        if (_selectedFilter == _CalendarFilterMode.expense) {
                          _selectedFilter = _CalendarFilterMode.all;
                        } else {
                          _selectedFilter = _CalendarFilterMode.expense;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Ô Thu
                Expanded(
                  child: _MonthlySummaryBox(
                    label: l10n.income,
                    icon: Icons.south_east_rounded,
                    amountText: totalIncome > 0
                        ? '+${AppCurrencyFormatter.formatFromVnd(amountVnd: totalIncome, currency: widget.userCurrency)}'
                        : '0₫',
                    accentColor: const Color(0xFF2ECC71),
                    badgeBgColor: isDark
                        ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
                        : const Color(0xFFE8F8F0),
                    isSelected: _selectedFilter == _CalendarFilterMode.income,
                    isDimmed: _selectedFilter == _CalendarFilterMode.expense,
                    onTap: () {
                      setState(() {
                        if (_selectedFilter == _CalendarFilterMode.income) {
                          _selectedFilter = _CalendarFilterMode.all;
                        } else {
                          _selectedFilter = _CalendarFilterMode.income;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

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
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isWeekend
                            ? AppColors.primaryBlue
                            : (isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),

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

                    final dayAllTransactions =
                        dayTxMap[date.day] ?? const <TransactionModel>[];

                    // Lọc theo tab đang chọn
                    final List<TransactionModel> displayedTransactions;
                    double dayAmount = 0.0;

                    if (_selectedFilter == _CalendarFilterMode.expense) {
                      displayedTransactions = dayAllTransactions
                          .where((tx) => tx.isPersonalExpense)
                          .toList();
                      for (final tx in displayedTransactions) {
                        dayAmount += tx.amount;
                      }
                    } else if (_selectedFilter == _CalendarFilterMode.income) {
                      displayedTransactions = dayAllTransactions
                          .where((tx) => tx.isPersonalIncome)
                          .toList();
                      for (final tx in displayedTransactions) {
                        dayAmount += tx.amount;
                      }
                    } else {
                      displayedTransactions = dayAllTransactions;
                    }

                    final isToday = _sameDate(date, now);
                    final isFuture =
                        DateTime(date.year, date.month, date.day).isAfter(today);
                    final hasData = displayedTransactions.isNotEmpty;
                    final isBirthday = widget.dateOfBirth != null &&
                        date.day == widget.dateOfBirth!.day &&
                        date.month == widget.dateOfBirth!.month;

                    String? amountText;
                    Color? amountColor;

                    if (_selectedFilter == _CalendarFilterMode.expense) {
                      if (dayAmount > 0) {
                        amountText = _formatDailyCompact(
                          amountVnd: dayAmount,
                          currency: widget.userCurrency,
                          isVi: isVi,
                        );
                        amountColor = const Color(0xFFFF5252);
                      }
                    } else if (_selectedFilter == _CalendarFilterMode.income) {
                      if (dayAmount > 0) {
                        amountText = '+${_formatDailyCompact(
                          amountVnd: dayAmount,
                          currency: widget.userCurrency,
                          isVi: isVi,
                        )}';
                        amountColor = const Color(0xFF2ECC71);
                      }
                    }

                    return Expanded(
                      child: _CalendarDayCell(
                        date: date,
                        isToday: isToday,
                        isFuture: isFuture,
                        hasData: hasData,
                        isBirthday: isBirthday,
                        transactions: displayedTransactions,
                        amountText: amountText,
                        amountColor: amountColor,
                        onTap: hasData
                            ? () {
                                Navigator.pushNamed(
                                  context,
                                  RouteNames.dayDetail,
                                  arguments: {
                                    'date': date,
                                    'filterType': _selectedFilter ==
                                            _CalendarFilterMode.expense
                                        ? 'expense'
                                        : (_selectedFilter ==
                                                _CalendarFilterMode.income
                                            ? 'income'
                                            : null),
                                  },
                                );
                              }
                            : null, // Không bấm được nếu là ngày chưa có dữ liệu tương ứng
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

/// Ô tóm tắt Tổng Chi / Tổng Thu trong thẻ tháng (Hỗ trợ tương tác chọn để lọc)
class _MonthlySummaryBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final String amountText;
  final Color accentColor;
  final Color badgeBgColor;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback onTap;

  const _MonthlySummaryBox({
    required this.label,
    required this.icon,
    required this.amountText,
    required this.accentColor,
    required this.badgeBgColor,
    this.isSelected = false,
    this.isDimmed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDimmed ? 0.45 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? accentColor.withValues(alpha: 0.16)
                  : accentColor.withValues(alpha: 0.08))
              : (isDark ? const Color(0xFF0D0E12) : const Color(0xFFF7F8FA)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF1F222D) : const Color(0xFFE8ECF2)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.30 : 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge: [↗ Chi] hoặc [↘ Thu]
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: isDark ? 0.35 : 0.22)
                          : badgeBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor
                            .withValues(alpha: isSelected ? 0.9 : 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 10.5,
                          color: accentColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Số tiền
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amountText,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF14151B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ô hiển thị từng ngày trong lưới lịch (Dấu x ở ngày chưa chụp, Badge số lượng cho >= 3 giao dịch, Badge sinh nhật 🎂, Số tiền hàng ngày)
class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isFuture;
  final bool hasData;
  final bool isBirthday;
  final List<TransactionModel> transactions;
  final String? amountText;
  final Color? amountColor;
  final VoidCallback? onTap;

  const _CalendarDayCell({
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.hasData,
    this.isBirthday = false,
    required this.transactions,
    this.amountText,
    this.amountColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Widget phần đầu (Ảnh sticker / dấu x / ô xám mờ / bánh sinh nhật)
    Widget topWidget;

    if (hasData) {
      if (transactions.length == 1) {
        topWidget = _SingleImageSticker(
          transaction: transactions.first,
          isToday: isToday,
          isBirthday: isBirthday,
        );
      } else {
        topWidget = _StackedImageSticker(
          firstTransaction: transactions[0],
          secondTransaction: transactions[1],
          isToday: isToday,
          isBirthday: isBirthday,
        );
      }
    } else if (isBirthday) {
      // Ngày sinh nhật chưa có transaction: Hiển thị badge bánh sinh nhật màu hồng giống date picker
      topWidget = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryPink.withValues(alpha: 0.15),
          border: Border.all(
            color: AppColors.primaryPink.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: const Center(
          child: Text(
            '🎂',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
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
    Widget displayedTopWidget = showCountBadge
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

    // Nếu là sinh nhật và đã có ảnh/dữ liệu giao dịch -> gắn kèm thẻ badge bánh sinh nhật 🎂 ở góc
    if (isBirthday && hasData) {
      displayedTopWidget = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          displayedTopWidget,
          Positioned(
            top: -4,
            left: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4081),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF131418) : Colors.white,
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '🎂',
                  style: TextStyle(fontSize: 9.5, height: 1.0),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Màu chữ số ngày
    final Color dayNumberColor;
    if (isBirthday) {
      dayNumberColor = const Color(0xFFFF4081); // Pink festive
    } else if (isToday) {
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
        // Số ngày + Chấm dot hoặc bánh kem 🎂 ở trước nếu là sinh nhật
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBirthday) ...[
              const Text(
                '🎂',
                style: TextStyle(fontSize: 9.5, height: 1.0),
              ),
              const SizedBox(width: 2),
            ] else if (isToday) ...[
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF29B6F6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: (isToday || isBirthday) ? FontWeight.w900 : FontWeight.w700,
                color: dayNumberColor,
                height: 1.0,
              ),
            ),
          ],
        ),
        if (amountText != null && amountText!.isNotEmpty) ...[
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amountText!,
              maxLines: 1,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: amountColor ??
                    (isDark ? Colors.white70 : Colors.black87),
                letterSpacing: -0.2,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 2),
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
  final bool isBirthday;

  const _SingleImageSticker({
    required this.transaction,
    required this.isToday,
    this.isBirthday = false,
  });

  @override
  Widget build(BuildContext context) {
    return _StickerFrame(
      transaction: transaction,
      size: 36,
      isToday: isToday,
      isBirthday: isBirthday,
    );
  }
}

/// Sticker ảnh xếp chồng (Stacked Polaroid effect)
class _StackedImageSticker extends StatelessWidget {
  final TransactionModel firstTransaction;
  final TransactionModel secondTransaction;
  final bool isToday;
  final bool isBirthday;

  const _StackedImageSticker({
    required this.firstTransaction,
    required this.secondTransaction,
    required this.isToday,
    this.isBirthday = false,
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
                isBirthday: isBirthday,
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
                isBirthday: isBirthday,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung ảnh sticker bo góc tròn với viền màu đỏ (Chi tiêu) hoặc xanh lá (Thu nhập) hoặc hồng (Sinh nhật)
class _StickerFrame extends StatelessWidget {
  final TransactionModel transaction;
  final double size;
  final bool isToday;
  final bool isBirthday;

  const _StickerFrame({
    required this.transaction,
    required this.size,
    required this.isToday,
    this.isBirthday = false,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense' && !transaction.isGroupContribution;
    final typeColor = isExpense ? AppColors.expense : AppColors.income;
    final borderColor = isBirthday
        ? const Color(0xFFFF4081)
        : (isToday ? const Color(0xFF29B6F6) : typeColor);
    final radius = BorderRadius.circular(size * 0.32);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: borderColor,
        borderRadius: radius,
        border: Border.all(
          color: borderColor,
          width: (isToday || isBirthday) ? 2.0 : 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: isBirthday
                ? const Color(0xFFFF4081).withValues(alpha: 0.45)
                : (isToday
                    ? const Color(0xFF29B6F6).withValues(alpha: 0.45)
                    : typeColor.withValues(alpha: 0.35)),
            blurRadius: (isToday || isBirthday) ? 6 : 4,
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