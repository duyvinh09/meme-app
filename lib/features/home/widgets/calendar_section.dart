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

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final days = _daysInMonth(currentMonth);
    final weekdayLabels = _weekdayLabels(context);

    final monthTitle = context.l10n.monthYear(currentMonth.month, currentMonth.year);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: AppColors.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              AppColors.isDark(context) ? 0.16 : 0.04,
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
                Expanded(
                  child: Center(
                    child: Text(
                      monthTitle,
                      style: AppTextStyles.cardTitle(context).copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                _MiniNavButton(
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
  final VoidCallback onTap;

  const _MiniNavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.innerBorder(context),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.textPrimary(context),
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
        color: color.withOpacity(0.18),
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