import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/localization_extension.dart';
import '../models/rewind_data.dart';
import '../models/rewind_period.dart';

class RewindStreakStory extends StatefulWidget {
  final RewindData data;

  const RewindStreakStory({
    super.key,
    required this.data,
  });

  @override
  State<RewindStreakStory> createState() => _RewindStreakStoryState();
}

class _RewindStreakStoryState extends State<RewindStreakStory>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final streak = widget.data.streakDays;
    final activeKeys = widget.data.activeDateKeys;
    final period = widget.data.period;
    final isWeek = period.type == RewindPeriodType.week;

    final now = DateTime.now();
    final effectiveEnd = period.endDateTime.isBefore(now)
        ? period.endDateTime
        : now;

    // For week: show Monday -> Sunday of that week
    // For month/quarter/year: show the 7 days ending at effectiveEnd
    final calendarStart = isWeek
        ? period.startDateTime
        : DateTime(effectiveEnd.year, effectiveEnd.month, effectiveEnd.day)
            .subtract(const Duration(days: 6));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  l10n.rewindStreakTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Pulsing Flame Icon
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFF7A00),
                    Color(0xFFFF3D00),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.6),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '🔥',
                  style: TextStyle(fontSize: 44),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Streak Count
          Text(
            l10n.rewindStreakDays(streak),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Supportive Message
          Text(
            streak >= 3
                ? l10n.rewindStreakSubtitle(streak)
                : (streak > 0 ? l10n.rewindStreakStarter : l10n.rewindStreakZero),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),

          // Extra stat for Quarter / Year
          if (period.type == RewindPeriodType.quarter || period.type == RewindPeriodType.year) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.rewindActiveDaysInPeriod(
                  activeKeys.length,
                  period.getTypeName(context).toLowerCase(),
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),

          // Mini Calendar Container
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  isWeek ? l10n.rewindDaysThisWeek : l10n.rewindDaysRecentInPeriod,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final date = calendarStart.add(Duration(days: i));
                    final key = DateFormat('yyyy-MM-dd').format(date);
                    final isActive = activeKeys.contains(key);
                    final weekdayLabel = DateFormat('E').format(date);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weekdayLabel.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFFFF5722)
                                : Colors.white.withValues(alpha: 0.1),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF5722).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isActive
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
