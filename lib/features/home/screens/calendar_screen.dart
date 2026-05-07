import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../data/models/transaction_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../controllers/home_controller.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!loaded) {
      final uid = context.read<AuthController>().user?.uid;

      if (uid != null && context.read<HomeController>().transactions.isEmpty) {
        context.read<HomeController>().load(uid);
      }

      loaded = true;
    }
  }

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

  String _capitalizeMonth(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _showMonthYearPicker() async {
    final now = DateTime.now();

    int selectedYear = currentMonth.year;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.card(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final years = List.generate(
              11,
                  (index) => now.year - 8 + index,
            );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary(context).withOpacity(0.22),
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Text(
                          'Chọn tháng',
                          style: AppTextStyles.sectionTitle(context).copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                              DateTime(now.year, now.month),
                            );
                          },
                          child: const Text('Hôm nay'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.border(context),
                        ),
                      ),
                      child: Row(
                        children: [
                          _MonthNavButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: () {
                              setSheetState(() {
                                selectedYear--;
                              });
                            },
                          ),

                          Expanded(
                            child: Center(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: years.contains(selectedYear)
                                      ? selectedYear
                                      : null,
                                  hint: Text(
                                    '$selectedYear',
                                    style: AppTextStyles.sectionTitle(context),
                                  ),
                                  dropdownColor: AppColors.card(context),
                                  items: years.map((year) {
                                    return DropdownMenuItem<int>(
                                      value: year,
                                      child: Text(
                                        '$year',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(context),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value == null) return;

                                    setSheetState(() {
                                      selectedYear = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),

                          _MonthNavButton(
                            icon: Icons.chevron_right_rounded,
                            onTap: () {
                              setSheetState(() {
                                selectedYear++;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.25,
                      ),
                      itemBuilder: (context, index) {
                        final month = index + 1;

                        final isSelected =
                            selectedYear == currentMonth.year &&
                                month == currentMonth.month;

                        final isCurrentMonth =
                            selectedYear == now.year && month == now.month;

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pop(
                              sheetContext,
                              DateTime(selectedYear, month),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue.withOpacity(0.18)
                                  : AppColors.surface(context),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : isCurrentMonth
                                    ? AppColors.primaryBlue.withOpacity(0.45)
                                    : AppColors.border(context),
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Text(
                              'Tháng $month',
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.textPrimary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
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
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      currentMonth = DateTime(picked.year, picked.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final days = _daysInMonth(currentMonth);

    final monthTitle = _capitalizeMonth(
      DateFormat('MMMM yyyy', 'vi_VN').format(currentMonth),
    );

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            12,
            14,
            10,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _TopCircleButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Lịch giao dịch',
                      style: AppTextStyles.pageTitle(context).copyWith(
                        fontSize: 28,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.border(context),
                  ),
                ),
                child: Row(
                  children: [
                    _MonthNavButton(
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
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _showMonthYearPicker,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  monthTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.sectionTitle(context).copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary(context),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _MonthNavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () {
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
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border(context),
                  ),
                ),
                child: Row(
                  children: List.generate(7, (index) {
                    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                    final isWeekend = index >= 5;

                    return Expanded(
                      child: Center(
                        child: Text(
                          labels[index],
                          style: AppTextStyles.caption(context).copyWith(
                            color: isWeekend
                                ? AppColors.primaryBlue
                                : AppColors.textSecondary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: GridView.builder(
                  cacheExtent: 700,
                  itemCount: days.length,
                  physics: const BouncingScrollPhysics(),
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

                    return RepaintBoundary(
                      child: _CalendarStickerCell(
                        date: date,
                        isPast: isPast,
                        isFuture: isFuture,
                        hasData: hasData,
                        hasImage: hasImage,
                        imageTransactions: imageTxs,
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
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: AppColors.border(context),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary(context),
          size: 20,
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.innerBorder(context),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary(context),
        ),
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
  final bool isToday;
  final VoidCallback? onTap;

  const _CalendarStickerCell({
    required this.date,
    required this.isPast,
    required this.isFuture,
    required this.hasData,
    required this.hasImage,
    required this.imageTransactions,
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
        : AppColors.textPrimary(context).withOpacity(isDark ? 0.72 : 0.84);

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
            ? Colors.white.withOpacity(0.24)
            : const Color(0xFFD8D3DD),
      );
    } else {
      topWidget = const _EmptyDayMarker();
    }

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
                    maxWidth: 68,
                    maxHeight: 54,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: topWidget,
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
        ? Colors.white.withOpacity(0.24)
        : const Color(0xFFC9C3CF);

    final iconColor = AppColors.isDark(context)
        ? Colors.white.withOpacity(0.38)
        : const Color(0xFF9B93A5);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: borderColor,
          width: 1.4,
        ),
      ),
      child: Icon(
        Icons.close_rounded,
        size: 19,
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
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.18),
        border: Border.all(
          color: color,
          width: 1.5,
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
      width: 56,
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