import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../controllers/home_controller.dart';

class CalendarSection extends StatefulWidget {
  const CalendarSection({super.key});

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isBeforeToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    return target.isBefore(today);
  }

  bool _isAfterToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    return target.isAfter(today);
  }

  List<DateTime?> _daysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final days = <DateTime?>[];

    for (int i = 0; i < firstDay.weekday - 1; i++) {
      days.add(null);
    }

    for (int day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    return days;
  }

  List<TransactionModel> _transactionsOfDay(
      List<TransactionModel> all,
      DateTime date,
      ) {
    return all.where((tx) => _sameDate(tx.createdAt, date)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<TransactionModel> _previewTransactionsOfDay(
      List<TransactionModel> dayTransactions,
      ) {
    return dayTransactions.take(2).toList();
  }

  String _capitalizedWeekdayAbbrev(String label) {
    if (label.isEmpty) return label;
    final t = label.trim();
    final lower = t.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  List<String> _weekdayLabels(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monday = DateTime(2024, 1, 1); // Monday
    return List.generate(7, (index) {
      final label = DateFormat.E(locale).format(monday.add(Duration(days: index)));
      return _capitalizedWeekdayAbbrev(label);
    });
  }

  Future<void> _openMonthPicker(
    BuildContext context,
    List<TransactionModel> transactions,
  ) async {
    final picked = await _HomeScreenMonthPickerSheet.show(
      context,
      initialMonth: currentMonth,
      transactions: transactions,
    );

    if (picked != null && mounted) {
      setState(() {
        currentMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final days = _daysInMonth(currentMonth);
    final weekdayLabels = _weekdayLabels(context);

    final now = DateTime.now();
    final isCurrentMonth =
        currentMonth.year == now.year && currentMonth.month == now.month;
    final monthTitle =
        context.l10n.monthYear(currentMonth.month, currentMonth.year);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.16 : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Column(
          children: [
            Row(
              children: [
                _MiniNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () {
                    setState(() {
                      currentMonth = DateTime(
                        currentMonth.year,
                        currentMonth.month - 1,
                      );
                    });
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Center(
                    child: InkWell(
                      onTap: () => _openMonthPicker(context, home.transactions),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                monthTitle,
                                style: AppTextStyles.cardTitle(context).copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 19,
                              color: AppColors.textSecondary(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isCurrentMonth) ...[
                  _MiniNavButton(
                    icon: Icons.today_rounded,
                    iconColor: AppColors.primaryBlue,
                    bgColor: AppColors.primaryBlue.withValues(
                      alpha: AppColors.isDark(context) ? 0.2 : 0.1,
                    ),
                    borderColor: AppColors.primaryBlue.withValues(alpha: 0.45),
                    onTap: () {
                      setState(() {
                        currentMonth = DateTime(now.year, now.month);
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                ],
                _MiniNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: isCurrentMonth
                      ? null
                      : () {
                          setState(() {
                            currentMonth = DateTime(
                              currentMonth.year,
                              currentMonth.month + 1,
                            );
                          });
                        },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.innerBorder(context),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Center(child: _WeekdayText(weekdayLabels[0]))),
                  Expanded(child: Center(child: _WeekdayText(weekdayLabels[1]))),
                  Expanded(child: Center(child: _WeekdayText(weekdayLabels[2]))),
                  Expanded(child: Center(child: _WeekdayText(weekdayLabels[3]))),
                  Expanded(child: Center(child: _WeekdayText(weekdayLabels[4]))),
                  Expanded(
                    child: Center(
                      child: _WeekdayText(weekdayLabels[5], weekend: true),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _WeekdayText(weekdayLabels[6], weekend: true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: days.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 7,
                mainAxisSpacing: 4,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, index) {
                final date = days[index];

                if (date == null) {
                  return const SizedBox.shrink();
                }

                final txs = _transactionsOfDay(home.transactions, date);
                final imageTxs = _previewTransactionsOfDay(txs);

                final hasData = txs.isNotEmpty;
                final hasImage = imageTxs.isNotEmpty;
                final isToday = _sameDate(date, DateTime.now());
                final isPast = _isBeforeToday(date);
                final isFuture = _isAfterToday(date);

                return _CalendarStickerCell(
                  date: date,
                  isPast: isPast,
                  isFuture: isFuture,
                  hasData: hasData,
                  hasImage: hasImage,
                  imageTransactions: imageTxs,
                  totalCount: txs.length,
                  isToday: isToday,
                  onTap: hasData
                      ? () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.dayDetail,
                      arguments: date,
                    );
                  }
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? bgColor;
  final Color? borderColor;

  const _MiniNavButton({
    required this.icon,
    this.onTap,
    this.iconColor,
    this.bgColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled ? 0.3 : 1.0,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bgColor ?? AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor ?? AppColors.innerBorder(context),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.textPrimary(context),
          ),
        ),
      ),
    );
  }
}

class _WeekdayText extends StatelessWidget {
  final String text;
  final bool weekend;

  const _WeekdayText(
      this.text, {
        this.weekend = false,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption(context).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: weekend
            ? AppColors.primaryBlue
            : AppColors.textSecondary(context),
      ),
    );
  }
}

class _CalendarStickerCell extends StatelessWidget {
  final DateTime date;
  final bool isPast;
  final bool isFuture;
  final bool hasData;
  final bool hasImage;
  final List<TransactionModel> imageTransactions;
  final int totalCount;
  final bool isToday;
  final VoidCallback? onTap;

  const _CalendarStickerCell({
    required this.date,
    required this.isPast,
    required this.isFuture,
    required this.hasData,
    required this.hasImage,
    required this.imageTransactions,
    required this.totalCount,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final markerColor = isToday
        ? AppColors.primaryBlue
        : const Color(0xFF6DB7FF);

    final dayColor = isToday
        ? AppColors.primaryBlue
        : AppColors.textPrimary(context).withValues(alpha: isDark ? 0.72 : 0.84);

    Widget topWidget;

    if (hasImage) {
      if (imageTransactions.length == 1) {
        topWidget = _SingleImageSticker(
          transaction: imageTransactions.first,
          borderColor: markerColor,
        );
      } else {
        topWidget = _StackedImageSticker(
          firstTransaction: imageTransactions[0],
          secondTransaction: imageTransactions[1],
          borderColor: markerColor,
        );
      }
    } else if (hasData) {
      topWidget = _SolidCircleMarker(
        color: markerColor,
      );
    } else if (isFuture) {
      topWidget = _SolidCircleMarker(
        color: isDark
            ? Colors.white.withValues(alpha: 0.24)
            : const Color(0xFFD8D3DD),
      );
    } else {
      topWidget = const _EmptyDayMarker();
    }

    final showCountBadge = hasData && totalCount > 2;

    final displayedTopWidget = showCountBadge
        ? Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              topWidget,
              Positioned(
                top: 1,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(
                    minWidth: 15,
                    minHeight: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF388AF6),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isDark ? const Color(0xFF141722) : Colors.white,
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      totalCount > 99 ? '99+' : '$totalCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : topWidget;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellHeight = constraints.maxHeight;

          final topHeight = (cellHeight * 0.72).clamp(42.0, 54.0);
          final dayHeight = (cellHeight * 0.22).clamp(16.0, 20.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: topHeight,
                child: Center(
                  child: OverflowBox(
                    maxWidth: 72,
                    maxHeight: 56,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: displayedTopWidget,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: dayHeight,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isToday) ...[
                          const _TodayDot(),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                            isToday ? FontWeight.w900 : FontWeight.w700,
                            color: dayColor,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}



class _TodayDot extends StatelessWidget {
  const _TodayDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyDayMarker extends StatelessWidget {
  const _EmptyDayMarker();

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.isDark(context)
        ? Colors.white.withValues(alpha: 0.24)
        : const Color(0xFFC9C3CF);

    final iconColor = AppColors.isDark(context)
        ? Colors.white.withValues(alpha: 0.38)
        : const Color(0xFF9B93A5);

    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Icon(
        Icons.close_rounded,
        size: 17,
        color: iconColor,
      ),
    );
  }
}

class _SolidCircleMarker extends StatelessWidget {
  final Color color;

  const _SolidCircleMarker({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(
          color: color,
          width: 1.3,
        ),
      ),
    );
  }
}

class _SingleImageSticker extends StatelessWidget {
  final TransactionModel transaction;
  final Color borderColor;

  const _SingleImageSticker({
    required this.transaction,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -6 * math.pi / 180,
      child: _StickerFrame(
        transaction: transaction,
        borderColor: borderColor,
        size: 38,
      ),
    );
  }
}

class _StackedImageSticker extends StatelessWidget {
  final TransactionModel firstTransaction;
  final TransactionModel secondTransaction;
  final Color borderColor;

  const _StackedImageSticker({
    required this.firstTransaction,
    required this.secondTransaction,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            top: 5,
            child: Transform.rotate(
              angle: -13 * math.pi / 180,
              child: _StickerFrame(
                transaction: firstTransaction,
                borderColor: borderColor,
                size: 36,
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 5,
            child: Transform.rotate(
              angle: 13 * math.pi / 180,
              child: _StickerFrame(
                transaction: secondTransaction,
                borderColor: borderColor,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerFrame extends StatelessWidget {
  final TransactionModel transaction;
  final Color borderColor;
  final double size;

  const _StickerFrame({
    required this.transaction,
    required this.borderColor,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = transaction.categoryColorHex != null &&
        transaction.categoryColorHex!.trim().isNotEmpty
        ? _parseHexColor(transaction.categoryColorHex!)
        : borderColor;

    final radius = BorderRadius.circular(size * 0.28);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: categoryColor,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: categoryColor,
          width: 1.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: categoryColor,
          child: TransactionMomentImage(
            imageUrl: transaction.displayImageUrl,
            category: transaction.category,
            categoryIconCodePoint: transaction.categoryIconCodePoint,
            categoryColorHex: transaction.categoryColorHex,
            caption: null,
            width: size,
            height: size,
            fit: BoxFit.cover,
            borderRadius: radius,
            isVideo: transaction.isVideo,
          ),
        ),
      ),
    );
  }

  Color _parseHexColor(String value) {
    var cleaned = value.trim().replaceAll('#', '');

    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }

    if (cleaned.length != 8) {
      return borderColor;
    }

    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return borderColor;
    }
  }
}

/// Bảng chọn Tháng & Năm cho Calendar ở Homescreen (Modal Bottom Sheet)
class _HomeScreenMonthPickerSheet extends StatefulWidget {
  final DateTime initialMonth;
  final List<TransactionModel> transactions;

  const _HomeScreenMonthPickerSheet({
    required this.initialMonth,
    required this.transactions,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialMonth,
    required List<TransactionModel> transactions,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HomeScreenMonthPickerSheet(
        initialMonth: initialMonth,
        transactions: transactions,
      ),
    );
  }

  @override
  State<_HomeScreenMonthPickerSheet> createState() =>
      _HomeScreenMonthPickerSheetState();
}

class _HomeScreenMonthPickerSheetState
    extends State<_HomeScreenMonthPickerSheet> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final locale = Localizations.localeOf(context).toString();
    final isVi = locale.toLowerCase().startsWith('vi');
    final now = DateTime.now();
    final currentActualMonth = DateTime(now.year, now.month);

    // Map số lượng giao dịch / memes theo tháng trong năm _selectedYear
    final Map<int, int> monthTxCountMap = {};
    for (final tx in widget.transactions) {
      if (tx.createdAt.year == _selectedYear) {
        monthTxCountMap[tx.createdAt.month] =
            (monthTxCountMap[tx.createdAt.month] ?? 0) + 1;
      }
    }

    final cardBg = isDark ? const Color(0xFF15171E) : Colors.white;
    final innerTileBg =
        isDark ? const Color(0xFF0E1015) : const Color(0xFFF4F6F9);
    final innerTileBorder =
        isDark ? const Color(0xFF232734) : const Color(0xFFE2E6EE);
    final textPrimary = isDark ? Colors.white : const Color(0xFF14151B);
    final textSecondary =
        isDark ? const Color(0xFF8C93A4) : const Color(0xFF71788A);

    final canGoNextYear = _selectedYear < now.year;
    final minYear = now.year - 10;
    final canGoPrevYear = _selectedYear > minYear;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0xFF252936) : const Color(0xFFE2E6EE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo drag handle
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Tiêu đề + Nút "Hiện tại" (Icon only)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVi ? 'Chọn tháng xem lại' : 'Select Month',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isVi
                              ? 'Duyệt kỷ niệm và chi tiêu theo tháng'
                              : 'Browse memories and expenses',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nút Hiện tại dạng Icon Only
                  InkWell(
                    onTap: () {
                      Navigator.pop(context, currentActualMonth);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.today_rounded,
                        size: 19,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Hộp chọn Năm [ < ] [ 2026 ] [ > ]
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: innerTileBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: innerTileBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: canGoPrevYear
                          ? textPrimary
                          : textSecondary.withValues(alpha: 0.3),
                      onPressed: canGoPrevYear
                          ? () {
                              setState(() {
                                _selectedYear--;
                              });
                            }
                          : null,
                      splashRadius: 20,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_selectedYear',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: canGoNextYear
                          ? textPrimary
                          : textSecondary.withValues(alpha: 0.3),
                      onPressed: canGoNextYear
                          ? () {
                              setState(() {
                                _selectedYear++;
                              });
                            }
                          : null,
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Lưới 12 tháng (4 hàng x 3 cột)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.62,
                ),
                itemBuilder: (context, index) {
                  final monthNum = index + 1;
                  final targetDate = DateTime(_selectedYear, monthNum);
                  final isFuture = targetDate.isAfter(currentActualMonth);
                  final isInitialSelected =
                      _selectedYear == widget.initialMonth.year &&
                          monthNum == widget.initialMonth.month;
                  final isThisMonth =
                      _selectedYear == now.year && monthNum == now.month;
                  final txCount = monthTxCountMap[monthNum] ?? 0;

                  final monthName = isVi
                      ? 'Tháng $monthNum'
                      : DateFormat('MMM', locale)
                          .format(DateTime(2024, monthNum, 1));

                  return _HomeScreenMonthGridItem(
                    monthName: monthName,
                    isFuture: isFuture,
                    isSelected: isInitialSelected,
                    isCurrent: isThisMonth,
                    txCount: txCount,
                    isVi: isVi,
                    onTap: isFuture
                        ? null
                        : () {
                            Navigator.pop(context, targetDate);
                          },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô hiển thị từng tháng trong lưới chọn tháng
class _HomeScreenMonthGridItem extends StatelessWidget {
  final String monthName;
  final bool isFuture;
  final bool isSelected;
  final bool isCurrent;
  final int txCount;
  final bool isVi;
  final VoidCallback? onTap;

  const _HomeScreenMonthGridItem({
    required this.monthName,
    required this.isFuture,
    required this.isSelected,
    required this.isCurrent,
    required this.txCount,
    required this.isVi,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    if (isFuture) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0C0D10).withValues(alpha: 0.5)
              : const Color(0xFFF2F4F7).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1A1C24) : const Color(0xFFEBEFF5),
            width: 1,
          ),
        ),
        child: Text(
          monthName,
          style: TextStyle(
            color: isDark
                ? const Color(0xFF454B5A)
                : const Color(0xFFB0B7C3),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final tileBg = isSelected
        ? AppColors.primaryBlue.withValues(alpha: isDark ? 0.22 : 0.12)
        : (isDark ? const Color(0xFF0F1014) : const Color(0xFFF4F6F9));

    final tileBorder = isSelected
        ? AppColors.primaryBlue
        : (isCurrent
            ? AppColors.primaryBlue.withValues(alpha: 0.45)
            : (isDark ? const Color(0xFF232734) : const Color(0xFFE2E6EE)));

    final textColor = isSelected
        ? AppColors.primaryBlue
        : (isDark ? Colors.white : const Color(0xFF14151B));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: tileBorder,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight:
                        isSelected || isCurrent ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                if (txCount > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💛', style: TextStyle(fontSize: 8.5)),
                      const SizedBox(width: 2.5),
                      Text(
                        isVi ? '$txCount meme' : '$txCount memes',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : (isDark
                                  ? const Color(0xFF9EA6B8)
                                  : const Color(0xFF6E7587)),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ] else if (isCurrent) ...[
                  const SizedBox(height: 2),
                  Text(
                    isVi ? 'Tháng này' : 'Current',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}