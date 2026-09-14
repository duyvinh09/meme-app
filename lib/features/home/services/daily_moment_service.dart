import 'dart:math';
import 'package:flutter/material.dart';

import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/user_model.dart';
import '../models/daily_moment.dart';

class DailyMomentService {
  DailyMomentService._();

  static DailyTimeSlot getTimeSlot(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final totalMinutes = hour * 60 + minute;

    if (totalMinutes < 180) {
      return DailyTimeSlot.lateNight; // 00:00 - 02:59
    } else if (totalMinutes < 300) {
      return DailyTimeSlot.dawn; // 03:00 - 04:59
    } else if (totalMinutes < 420) {
      return DailyTimeSlot.earlyMorning; // 05:00 - 06:59
    } else if (totalMinutes < 540) {
      return DailyTimeSlot.morningRush; // 07:00 - 08:59
    } else if (totalMinutes < 660) {
      return DailyTimeSlot.focusWork; // 09:00 - 10:59
    } else if (totalMinutes < 780) {
      return DailyTimeSlot.lunchTime; // 11:00 - 12:59
    } else if (totalMinutes < 870) {
      return DailyTimeSlot.napRecharge; // 13:00 - 14:29
    } else if (totalMinutes < 990) {
      return DailyTimeSlot.afternoon; // 14:30 - 16:29
    } else if (totalMinutes < 1110) {
      return DailyTimeSlot.afterWork; // 16:30 - 18:29
    } else if (totalMinutes < 1200) {
      return DailyTimeSlot.dinner; // 18:30 - 19:59
    } else if (totalMinutes < 1320) {
      return DailyTimeSlot.freeTime; // 20:00 - 21:59
    } else {
      return DailyTimeSlot.windDown; // 22:00 - 23:59
    }
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isLastDayOfMonth(DateTime date) {
    final nextDay = date.add(const Duration(days: 1));
    return nextDay.month != date.month;
  }

  static String _selectVariation(List<String> list, DateTime now, [int salt = 0]) {
    if (list.isEmpty) return '';
    final seed = now.year * 10000 + now.month * 100 + now.day + (now.hour ~/ 2) + salt;
    final index = Random(seed).nextInt(list.length);
    return list[index];
  }

  /// Evaluates and resolves the single best contextual DailyMoment
  /// following the priority hierarchy:
  /// 1. Special Event
  /// 2. Spending Context
  /// 3. Time of Day Context (12 time slots with day-of-week variations)
  static DailyMomentData resolveMoment({
    BuildContext? context,
    required UserModel? profile,
    required List<TransactionModel> transactions,
    List<BudgetModel> budgets = const [],
    String languageCode = 'vi',
    DateTime? mockNow,
  }) {
    final now = mockNow ?? DateTime.now();
    final effectiveLang = languageCode.trim().toLowerCase();
    final isVi = effectiveLang != 'en' && !effectiveLang.startsWith('en');
    final slot = getTimeSlot(now);

    final todayTransactions = transactions
        .where((tx) => _isSameDate(tx.createdAt, now))
        .toList();

    // -------------------------------------------------------------
    // PRIORITY 1: Spending Context (Triggered right after activity / alert)
    // -------------------------------------------------------------
    // 1.1 Fresh transaction logged in last 15 minutes
    if (todayTransactions.isNotEmpty) {
      final sorted = List<TransactionModel>.from(todayTransactions)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latestTx = sorted.first;
      final diffMinutes = now.difference(latestTx.createdAt).inMinutes.abs();

      if (diffMinutes <= 15) {
        final isFood = latestTx.category.toLowerCase().contains('ăn') ||
            latestTx.category.toLowerCase().contains('food') ||
            latestTx.category.toLowerCase().contains('uống') ||
            latestTx.category.toLowerCase().contains('drink');

        return DailyMomentData(
          greetingIcon: isFood ? '🍜' : '✨',
          greetingText: _selectVariation(
            isFood
                ? (isVi
                    ? [
                        'Bữa ăn vừa được ghi lại 🍜 Ăn ngon miệng không nè?',
                        'Ghi nhận bữa ăn xong rồi 🍱 Chi tiêu chuẩn chỉnh ghê!',
                        'Nạp năng lượng xong rồi 🍜 MeMe đã ghi lại giúp bạn nha',
                      ]
                    : [
                        'Meal just logged 🍜 Hope you enjoyed it!',
                        'Food moment recorded 🍱 Great tracking habit!',
                        'Refueled & tracked 🍜 MeMe safely saved your meal',
                      ])
                : (isVi
                    ? [
                        'Khoản chi vừa được ghi lại ✨ Quản lý ví chuẩn chỉ ghê!',
                        'Ghi chép kịp thời nè 📝 Ví luôn được giữ gọn gàng!',
                        'MeMe đã lưu lại khoản chi này ✨ Chúc bạn chi tiêu vui vẻ!',
                      ]
                    : [
                        'Moment freshly saved ✨ Great tracking habit!',
                        'Transaction logged 📝 Wallet kept in good shape',
                        'Just recorded ✨ MeMe has neatly stored this',
                      ]),
            now,
            103,
          ),
          mood: DailyMood(
            icon: isFood ? '🍜' : '✨',
            label: isVi ? 'Vừa chi tiêu' : 'Just logged',
            accentColor: const Color(0xFF36B66C),
          ),
          category: DailyMomentCategory.spendingEvent,
          timeSlot: slot,
        );
      }
    }

    // 1.2 Critical Budget Warning (> 90% or over budget)
    if (budgets.isNotEmpty) {
      final overBudgets = budgets.where((b) => b.limitAmount > 0 && b.spentAmount >= b.limitAmount).toList();
      final warningBudgets = budgets.where((b) => b.limitAmount > 0 && b.spentAmount >= b.limitAmount * 0.9).toList();

      if (overBudgets.isNotEmpty) {
        return DailyMomentData(
          greetingIcon: '👀',
          greetingText: _selectVariation(
            isVi
                ? [
                    'Ví đang hơi mỏng rồi đó 👀 Nhẹ tay chi tiêu nhé!',
                    'Ngân sách chạm đỉnh rồi ⚠️ Cân nhắc trước khi chi tiếp nha!',
                    'Chạm giới hạn ngân sách rồi 🚨 Tiết kiệm một chút thôi nào!',
                  ]
                : [
                    'Budget running a bit tight 👀 Take it easy today!',
                    'Limit reached ⚠️ Mind your spending for now!',
                    'Budget threshold hit 🚨 Time to go easy on the wallet!',
                  ],
            now,
            104,
          ),
          mood: DailyMood(
            icon: '⚠️',
            label: isVi ? 'Cảnh báo ví' : 'Budget alert',
            accentColor: const Color(0xFFFF7A7A),
          ),
          category: DailyMomentCategory.spendingEvent,
          timeSlot: slot,
        );
      } else if (warningBudgets.isNotEmpty && (slot == DailyTimeSlot.lunchTime || slot == DailyTimeSlot.dinner || slot == DailyTimeSlot.afterWork)) {
        return DailyMomentData(
          greetingIcon: '👀',
          greetingText: _selectVariation(
            isVi
                ? [
                    'Ngân sách đang chạy hơi nhanh đó 👀 Để ý một xíu nha',
                    'Sắp chạm giới hạn ngân sách rồi 💡 Cân đối chi tiêu thôi nè',
                    'Ví báo động nhẹ ⚠️ Chi tiêu khéo léo để an toàn ví nha',
                  ]
                : [
                    'Budget is pacing fast today 👀 Keep an eye on expenses',
                    'Nearing budget limit 💡 Balance your spend carefully',
                    'Gentle budget alert ⚠️ Stay mindful to keep the wallet safe',
                  ],
            now,
            105,
          ),
          mood: DailyMood(
            icon: '💡',
            label: isVi ? 'Để ý ngân sách' : 'Mind the budget',
            accentColor: const Color(0xFFFFC857),
          ),
          category: DailyMomentCategory.spendingEvent,
          timeSlot: slot,
        );
      }
    }

    // 1.3 Large transaction today (e.g. single expense >= 500,000 VND)
    final largeExpense = todayTransactions
        .where((tx) => tx.isPersonalExpense && tx.amount >= 500000)
        .toList();
    if (largeExpense.isNotEmpty && (now.hour >= 12 && now.hour <= 21)) {
      final showLarge = (now.day + now.hour) % 3 == 0;
      if (showLarge) {
        return DailyMomentData(
          greetingIcon: '👀',
          greetingText: _selectVariation(
            isVi
                ? [
                    'Khoản chi này hơi nặng ví một chút đó 👀 Nhớ cân đối nhé!',
                    'Ví vừa vơi đi một khoản lớn 💸 Nhưng nếu đáng thì không sao!',
                    'Một khoản chi đáng chú ý hôm nay 👀 Tiếp tục chi tiêu thông minh nha!',
                  ]
                : [
                    'Whoa… that was quite a heavy spend 👀 Keep things balanced!',
                    'Big spend recorded 💸 Totally fine if it was worth it!',
                    'Notable transaction today 👀 Keep rocking smart budgeting!',
                  ],
            now,
            106,
          ),
          mood: DailyMood(
            icon: '💸',
            label: isVi ? 'Chi lớn' : 'Big spend',
            accentColor: const Color(0xFFFF7AD9),
          ),
          category: DailyMomentCategory.spendingEvent,
          timeSlot: slot,
        );
      }
    }

    // 1.4 High Food expenses today
    final foodExpenses = todayTransactions.where((tx) {
      final cat = tx.category.toLowerCase();
      return tx.isPersonalExpense &&
          (cat.contains('ăn') || cat.contains('food') || cat.contains('uống') || cat.contains('drink') || cat.contains('cafe'));
    }).fold<double>(0, (sum, tx) => sum + tx.amount);

    final totalTodayExpense = todayTransactions
        .where((tx) => tx.isPersonalExpense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    if (totalTodayExpense > 0 && (foodExpenses / totalTodayExpense) >= 0.7 && (slot == DailyTimeSlot.lunchTime || slot == DailyTimeSlot.dinner)) {
      return DailyMomentData(
        greetingIcon: '🍜',
        greetingText: _selectVariation(
          isVi
              ? [
                  'Hôm nay có vẻ hơi yêu đồ ăn nha 🍜 Ăn ngon là hạnh phúc!',
                  'Tâm hồn ăn uống lên ngôi hôm nay 🍕 Bữa ăn chất lượng ghê!',
                  'Chi cho đồ ăn chiếm trọn hôm nay 🍲 Yêu bản thân là trên hết!',
                ]
              : [
                  'Foodie vibes secured today 🍜 Good food is pure happiness!',
                  'Food mood all day 🍕 Investing in delicious meals!',
                  'A delicious day 🍲 Nourishing yourself is always worth it!',
                ],
          now,
          107,
        ),
        mood: DailyMood(
          icon: '🍜',
          label: isVi ? 'Tâm hồn ăn uống' : 'Foodie mood',
          accentColor: const Color(0xFFFFA726),
        ),
        category: DailyMomentCategory.spendingEvent,
        timeSlot: slot,
      );
    }

    // -------------------------------------------------------------
    // PRIORITY 2: 12 Real-Time Time Slots (Blended with Special Events & Day-of-Week)
    // -------------------------------------------------------------
    return _buildTimeOfDayMoment(slot, isVi, now);
  }

  static DailyMomentData _buildTimeOfDayMoment(
    DailyTimeSlot slot,
    bool isVi,
    DateTime now,
  ) {
    final weekday = now.weekday;
    final isFirstDay = now.day == 1;
    final isLastDay = _isLastDayOfMonth(now);

    switch (slot) {
      case DailyTimeSlot.lateNight:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Tháng mới rồi 🦉 Cú đêm nhớ đi ngủ sớm mai còn đón tháng mới nha!',
            'Chào tháng mới 🌙 Đêm muộn rồi, nghỉ ngơi lấy sức nha',
          ];
          variationsEn = [
            'New month already 🦉 Rest up for a brilliant month!',
            'Hello new month 🌙 Don’t stay up too late tonight',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Đêm cuối tháng 🦉 Khép lại một tháng nhiều trải nghiệm nhé',
            'Đêm muộn cuối tháng 🌙 Nghỉ sớm để mai đón tháng mới nha',
          ];
          variationsEn = [
            'Late night month-end 🦉 Time to rest and reset',
            'Wrapping up the month 🌙 Sleep well tonight',
          ];
        } else {
          variationsVi = [
            'Cú đêm ơi 🦉 Nghỉ sớm mai còn chiến nha',
            'Muộn rồi đó 🌙 Đừng thức khuya quá nha',
            'Sao chưa ngủ ta? 🌌 Nhớ giữ gìn sức khoẻ nhé',
          ];
          variationsEn = [
            'Night owl mode 🦉 Get some rest soon!',
            'Still awake? 🌙 Don’t stay up too late',
            'Late night thoughts 🌌 Rest up for tomorrow',
          ];
        }

        return DailyMomentData(
          greetingIcon: isFirstDay ? '✨' : (isLastDay ? '📊' : '🦉'),
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            1,
          ),
          mood: DailyMood(
            icon: isFirstDay ? '✨' : (isLastDay ? '📊' : '🦉'),
            label: isFirstDay ? (isVi ? 'Tháng mới' : 'New month') : (isLastDay ? (isVi ? 'Cuối tháng' : 'Month-end') : (isVi ? 'Cú đêm' : 'Night owl')),
            accentColor: isFirstDay ? const Color(0xFF79AFFF) : const Color(0xFF8B7CFF),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.dawn:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Rạng sáng đầu tháng 🌌 Khởi đầu tháng mới thật nhiều may mắn!',
            'Bình minh ngày mùng 1 🌅 Chúc bạn một tháng thật rực rỡ',
          ];
          variationsEn = [
            'Dawn of a new month 🌌 Wishing you luck and success!',
            'First sunrise of the month 🌅 Have a brilliant month ahead',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Rạng sáng ngày cuối tháng 🌌 Chuẩn bị khép lại tháng này nhé',
            'Bình minh ngày cuối tháng 🌅 Sắp bước sang tháng mới rồi',
          ];
          variationsEn = [
            'Dawn of month-end 🌌 Preparing to wrap up this month',
            'Last sunrise of the month 🌅 A new chapter awaits',
          ];
        } else {
          variationsVi = [
            'Trời sắp sáng rồi 🌌 Dậy sớm hay chưa ngủ thế?',
            'Bình minh sắp đến 🌅 Nhớ nạp lại năng lượng nhé',
          ];
          variationsEn = [
            'Dawn is near 🌌 Early bird or haven\'t slept?',
            'Almost sunrise 🌅 Take good care of yourself',
          ];
        }

        return DailyMomentData(
          greetingIcon: isFirstDay ? '✨' : '🌅',
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            2,
          ),
          mood: DailyMood(
            icon: isFirstDay ? '✨' : '🌅',
            label: isFirstDay ? (isVi ? 'Tháng mới' : 'New month') : (isVi ? 'Bình minh' : 'Dawn'),
            accentColor: const Color(0xFF5C6BC0),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.earlyMorning:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Sáng đầu tháng trong lành 🍃 Chúc một tháng mới rực rỡ và may mắn!',
            'Chào sáng mùng 1 🌅 Khởi đầu tháng mới thật suôn sẻ nha',
          ];
          variationsEn = [
            'Fresh new month morning 🍃 Wishing you a brilliant month ahead!',
            'First morning of the month 🌅 Fresh start, fresh energy!',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Sáng ngày cuối tháng 🍃 Cùng hoàn thành nốt các mục tiêu tháng này nhé',
            'Chào ngày cuối tháng 🌅 Làm việc hiệu quả và tổng kết tháng thôi',
          ];
          variationsEn = [
            'Last morning of the month 🍃 Finishing goals strong today!',
            'Month-end morning 🌅 Let’s wrap up things nicely',
          ];
        } else {
          variationsVi = [
            'Sáng sớm trong lành 🍃 Chúc ngày mới tràn đầy năng lượng!',
            'Chào ngày mới 🌅 Khởi đầu ngày thật suôn sẻ nha',
          ];
          variationsEn = [
            'Fresh morning air 🍃 Ready for a great day!',
            'Early start 🌅 Wishing you a smooth day ahead',
          ];
        }

        return DailyMomentData(
          greetingIcon: isFirstDay ? '✨' : '🍃',
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            3,
          ),
          mood: DailyMood(
            icon: isFirstDay ? '✨' : '🍃',
            label: isFirstDay ? (isVi ? 'Tháng mới' : 'New month') : (isVi ? 'Sáng sớm' : 'Early start'),
            accentColor: const Color(0xFF36B66C),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.morningRush:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Sáng mùng 1 rực rỡ ☀️ Nạp năng lượng cho tháng mới suôn sẻ nha!',
            'Chào tháng mới 🥐 Ăn sáng rồi cùng bứt phá tháng này nào!',
          ];
          variationsEn = [
            'First morning rush ☀️ Fuel up for an amazing month ahead!',
            'Hello new month 🥐 Breakfast time, let’s make it count!',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Sáng ngày cuối tháng 📊 Nạp năng lượng để về đích tháng này nào!',
            'Chào buổi sáng cuối tháng ☀️ Cố gắng hoàn thành tốt tháng này nha!',
          ];
          variationsEn = [
            'Month-end morning rush 📊 Fuel up to finish strong today!',
            'Good morning ☀️ Wrapping up the month on a high note',
          ];
        } else {
          variationsVi = [
            'Chào buổi sáng ☀️ Bạn đã ăn sáng chưa nè?',
            'Sáng nay thế nào? 🥐 Nạp năng lượng rồi lên đồ thôi!',
            'Buổi sáng tươi vui ☕ Làm ly cà phê cho tỉnh táo nhé',
          ];
          variationsEn = [
            'Good morning ☀️ Had breakfast yet?',
            'Morning rush 🥐 Fuel up and let\'s roll!',
            'Morning vibe ☕ Coffee time to kick off',
          ];

          if (weekday == DateTime.monday) {
            variationsVi.insert(0, 'Thứ Hai tới rồi 🚀 Khởi đầu tuần mới thật suôn sẻ nha');
            variationsEn.insert(0, 'Monday mode 🚀 Fresh week, fresh start!');
          } else if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
            variationsVi.insert(0, 'Cuối tuần thảnh thơi 🌴 Thức dậy đón ngày mới nhẹ nhàng');
            variationsEn.insert(0, 'Weekend morning 🌴 Take it easy today!');
          }
        }

        return DailyMomentData(
          greetingIcon: isFirstDay ? '✨' : ((weekday == DateTime.saturday || weekday == DateTime.sunday) ? '🌴' : '☀️'),
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            4,
          ),
          mood: DailyMood(
            icon: isFirstDay ? '✨' : '☀️',
            label: isFirstDay ? (isVi ? 'Tháng mới' : 'New month') : (isVi ? 'Khởi đầu mới' : 'Fresh start'),
            accentColor: const Color(0xFFFFA726),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.focusWork:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Bật chế độ tập trung 🎧 Khởi động tháng mới với năng suất tối đa!',
            'Chiến hết mình nào 💻 Đặt mục tiêu và bứt phá tháng này nhé',
          ];
          variationsEn = [
            'Focus mode ON 🎧 Kicking off the new month with great focus!',
            'Deep work zone 💻 Crushing goals in the new month!',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Tập trung về đích 🎧 Hoàn tất nốt các mục tiêu của tháng này nào',
            'Chiến nốt hôm nay 💻 Khép lại tháng thật trọn vẹn nhé',
          ];
          variationsEn = [
            'Focus & finish strong 🎧 Completing all goals for the month',
            'Month-end flow 💻 Wrapping up on a high note',
          ];
        } else {
          variationsVi = [
            'Bật chế độ tập trung 🎧 Chúc bạn làm việc thật mượt mà',
            'Chiến hết mình nào 💻 Hôm nay công việc sẽ suôn sẻ thôi',
            'Vào guồng thôi ⚡ Chúc một ngày học tập, làm việc hiệu quả',
          ];
          variationsEn = [
            'Focus mode ON 🎧 Have a smooth and productive day',
            'Deep work zone 💻 Crushing the goals today',
            'In the flow ⚡ Let\'s make great progress',
          ];

          if (weekday == DateTime.monday) {
            variationsVi.insert(0, 'Thứ Hai đầy năng lượng ⚡ Cùng chiến hết việc hôm nay nha');
            variationsEn.insert(0, 'Monday focus ⚡ Let\'s kick off the week strong');
          } else if (weekday == DateTime.friday) {
            variationsVi.insert(0, 'Thứ Sáu rồi ✨ Cố gắng xíu nữa là xong tuần rồi');
            variationsEn.insert(0, 'Almost weekend ✨ Finish strong today');
          }
        }

        return DailyMomentData(
          greetingIcon: isFirstDay ? '✨' : '🎧',
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            5,
          ),
          mood: DailyMood(
            icon: isFirstDay ? '✨' : '🎧',
            label: isFirstDay ? (isVi ? 'Tháng mới' : 'New month') : (isVi ? 'Tập trung' : 'Focus mode'),
            accentColor: const Color(0xFF79AFFF),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.lunchTime:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Bữa trưa mùng 1 🍜 Tự thưởng bữa trưa ngon mở bát tháng mới nhé!',
            'Đến giờ ăn trưa rồi 🍱 Ăn ngon để tháng mới nhiều may mắn nha',
          ];
          variationsEn = [
            'First lunch of the month 🍜 Treat yourself to a great meal!',
            'New month lunch 🍱 Fuel up with good food and good vibes',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Bữa trưa ngày cuối tháng 🍜 Ăn trưa ngon miệng nạp lại năng lượng nha',
            'Ăn trưa nghỉ ngơi thôi 🍱 Nốt buổi chiều là khép lại tháng này rồi',
          ];
          variationsEn = [
            'Month-end lunch break 🍜 Step away and enjoy your meal',
            'Refuel time 🍱 Almost done with the month!',
          ];
        } else {
          variationsVi = [
            'Đến giờ ăn trưa rồi 🍜 Hôm nay ăn món gì ngon nè?',
            'Nạp năng lượng thôi 🍱 Tự thưởng bữa trưa thật ngon nhé',
            'Nghỉ tay ăn trưa thôi 🥗 Đừng bỏ bữa nha!',
          ];
          variationsEn = [
            'Lunch time 🍜 What\'s on the menu today?',
            'Refuel time 🍱 Treat yourself to good food',
            'Lunch break 🥗 Step away and enjoy your meal',
          ];
        }

        return DailyMomentData(
          greetingIcon: '🍜',
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            6,
          ),
          mood: DailyMood(
            icon: '🍜',
            label: isFirstDay ? (isVi ? 'Trưa đầu tháng' : 'Month lunch') : (isVi ? 'Ăn trưa' : 'Lunch break'),
            accentColor: const Color(0xFFFF7A7A),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.napRecharge:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Nghỉ trưa chút nhé 😴 Chiều mùng 1 lại tràn đầy năng lượng',
            'Chợp mắt một chút nào ☕ Để khởi đầu tháng mới thật tỉnh táo nha',
          ];
          variationsEn = [
            'Midday rest 😴 Power up for a great afternoon ahead',
            'Recharge time ☕ Fresh energy for the new month',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Nghỉ trưa xíu nào 😴 Nạp lại năng lượng để về đích tháng này',
            'Nghỉ ngơi lấy sức ☕ Chiều nay cùng tổng kết tháng nhé',
          ];
          variationsEn = [
            'Midday recharge 😴 Powering up for month-end finish',
            'Take a quick rest ☕ Fresh mind for the afternoon',
          ];
        } else {
          variationsVi = [
            'Nghỉ ngơi xíu nào 😴 Chợp mắt một chút cho tỉnh táo nha',
            'Nghỉ trưa chút nhé ☕ Chiều lại tràn đầy năng lượng',
          ];
          variationsEn = [
            'Recharge time 😴 Take a quick breather',
            'Midday rest ☕ Power up for the afternoon',
          ];
        }

        return DailyMomentData(
          greetingIcon: '😴',
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            7,
          ),
          mood: DailyMood(
            icon: '😴',
            label: isVi ? 'Nghỉ trưa' : 'Recharge',
            accentColor: const Color(0xFFAB47BC),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.afternoon:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Buổi chiều đầu tháng ☕ Tự thưởng ly trà chiều mở màn tháng mới nha',
            'Chiều mùng 1 nhẹ nhàng ✨ Cố gắng hoàn thành tốt công việc hôm nay nhé',
          ];
          variationsEn = [
            'New month afternoon ☕ Time for tea or coffee to celebrate',
            'Afternoon energy ✨ Smooth sailing into the new month',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Buổi chiều cuối tháng ☕ Sắp hoàn thành trọn vẹn tháng này rồi!',
            'Năng lượng chiều cuối tháng ✨ Cố gắng xíu nữa là xong tháng rồi',
          ];
          variationsEn = [
            'Month-end afternoon ☕ Wrapping up the final tasks',
            'Almost at the month-end finish line ✨ Great job!',
          ];
        } else {
          variationsVi = [
            'Buổi chiều nhẹ nhàng ☕ Tự thưởng ly trà chiều không?',
            'Năng lượng buổi chiều ✨ Cố gắng xíu nữa là xong ngày rồi',
          ];
          variationsEn = [
            'Afternoon grind ☕ Time for tea or coffee?',
            'Afternoon energy ✨ Almost at the finish line',
          ];
        }

        return DailyMomentData(
          greetingIcon: '☕',
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            8,
          ),
          mood: DailyMood(
            icon: '☕',
            label: isVi ? 'Chiều nhẹ' : 'Afternoon',
            accentColor: const Color(0xFFAB47BC),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.afterWork:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Tan làm ngày mùng 1 🎉 Khởi đầu tháng suôn sẻ, về nhà nghỉ ngơi thôi!',
            'Hôm nay bạn vất vả rồi 🫡 Ngày đầu tháng trôi qua thật tốt đẹp nha',
          ];
          variationsEn = [
            'First day survived 🎉 Great start to the month, time to unwind!',
            'Clocking out 🫡 Off to a fantastic month ahead',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Tan làm ngày cuối tháng 🎉 Bạn đã rất nỗ lực trong tháng này rồi!',
            'Hết giờ làm việc rồi 📊 Gác lại công việc và chuẩn bị đón tháng mới nhé',
          ];
          variationsEn = [
            'Month-end clock out 🎉 You did fantastic work this month!',
            'Done for the month 📊 Time to breathe and celebrate',
          ];
        } else {
          variationsVi = [
            'Hôm nay bạn vất vả rồi! 🫡 Chuẩn bị về nghỉ ngơi thôi',
            'Tan làm/tan học rồi 🎉 Thở phào nhẹ nhõm về nhà thôi',
            'Hết giờ làm việc rồi 🌆 Gác lại deadline nha',
          ];
          variationsEn = [
            'You survived today! 🫡 Great job today',
            'Clocking out 🎉 Time to breathe and unwind',
            'Done for the day 🌆 Leave the work behind',
          ];

          if (weekday == DateTime.friday) {
            variationsVi.insert(0, 'Thứ Sáu tới rồi 🎉 Tan học/tan làm rồi xả hơi thôi!');
            variationsEn.insert(0, 'FRIDAY!!! 🎉 The weekend is officially here');
          }
        }

        return DailyMomentData(
          greetingIcon: (isFirstDay || weekday == DateTime.friday) ? '🎉' : '🫡',
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            9,
          ),
          mood: DailyMood(
            icon: '🫡',
            label: isVi ? 'Tan làm' : 'After work',
            accentColor: const Color(0xFF26A69A),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.dinner:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Bữa tối mùng 1 🍲 Nạp năng lượng cho một tháng đầy hứng khởi nha!',
            'Đến giờ ăn tối rồi 🥘 Ăn thật ngon mở đầu tháng mới nhé',
          ];
          variationsEn = [
            'First dinner of the month 🍲 Good food to start a great month!',
            'Dinner time 🥘 Feasting to celebrate the new month',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Bữa tối ngày cuối tháng 🍲 Tự thưởng bữa ăn ngon sau một tháng chăm chỉ!',
            'Tối cuối tháng rồi 🥘 Ăn tối ấm cúng và tổng kết tháng nhé',
          ];
          variationsEn = [
            'Month-end dinner 🍲 Treat yourself to a warm, delicious meal!',
            'Dinner time 🥘 Celebrating another completed month',
          ];
        } else {
          variationsVi = [
            'Đến giờ ăn tối rồi 🍲 Tối nay bạn ăn gì ngon không?',
            'Bữa tối ấm cúng 🥘 Nạp lại năng lượng sau một ngày dài',
          ];
          variationsEn = [
            'Dinner time 🍲 What are we feasting on tonight?',
            'Warm dinner 🥘 Enjoying the evening food',
          ];
        }

        return DailyMomentData(
          greetingIcon: '🍲',
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            10,
          ),
          mood: DailyMood(
            icon: '🍲',
            label: isVi ? 'Bữa tối' : 'Dinner time',
            accentColor: const Color(0xFFFF7A7A),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.freeTime:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Tối mùng 1 thảnh thơi 🎮 Thư giãn và tận hưởng buổi tối đầu tháng nhé',
            'Thời gian cho bản thân ✨ Chúc bạn một tháng mới nhiều niềm vui',
          ];
          variationsEn = [
            'New month evening 🎮 Relax and enjoy your me-time',
            'Evening vibes ✨ Wishing you a joyful month ahead',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Tối cuối tháng rồi 📊 Cùng nhìn lại chi tiêu tháng này và xả hơi nhé',
            'Thời gian nhìn lại 📈 Bạn đã quản lý tài chính rất tốt tháng này',
          ];
          variationsEn = [
            'Month-end recap vibes 📊 Review your month and unwind',
            'Finally me-time 📈 You managed your budget well this month',
          ];
        } else {
          variationsVi = [
            'Thời gian cho bản thân 🎮 Thư giãn nghỉ ngơi thôi nào',
            'Buổi tối thảnh thơi 🎧 Nghe nhạc, lướt app thư giãn nhé',
            'Tận hưởng buổi tối ✨ Dành thời gian chăm sóc bản thân nha',
          ];
          variationsEn = [
            'Finally, me-time 🎮 Time to chill out',
            'Evening vibes 🎧 Cozy music, relaxed mind',
            'Me-time unlocked ✨ Enjoy your evening',
          ];

          if (weekday == DateTime.friday || weekday == DateTime.saturday) {
            variationsVi.insert(0, 'Tối cuối tuần thảnh thơi 🎉 Xả hơi và tận hưởng nhé');
            variationsEn.insert(0, 'Weekend night vibes ✨ Relax and enjoy');
          } else if (weekday == DateTime.sunday) {
            variationsVi.insert(0, 'Chủ Nhật nhẹ nhàng 🌙 Mai lại tiếp tục cố gắng nha');
            variationsEn.insert(0, 'Sunday evening 🌤️ Rest up for the new week');
          }
        }

        return DailyMomentData(
          greetingIcon: isFirstDay ? '✨' : (isLastDay ? '📊' : '🎮'),
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            11,
          ),
          mood: DailyMood(
            icon: isFirstDay ? '✨' : (isLastDay ? '📊' : '🎮'),
            label: isFirstDay ? (isVi ? 'Tháng mới' : 'New month') : (isLastDay ? (isVi ? 'Tổng kết' : 'Month wrap') : (isVi ? 'Thư giãn' : 'Chill time')),
            accentColor: const Color(0xFF79AFFF),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );

      case DailyTimeSlot.windDown:
        List<String> variationsVi;
        List<String> variationsEn;

        if (isFirstDay) {
          variationsVi = [
            'Khép lại ngày đầu tháng 🌙 Chúc bạn ngủ thật ngon và mơ đẹp nha',
            'Đến giờ đi ngủ rồi 🕯️ Ngủ ngon để mai tiếp tục tháng mới rực rỡ nhé',
          ];
          variationsEn = [
            'First day is winding down 🌙 Sleep well tonight',
            'Bedtime 🕯️ Rest easy for a wonderful month ahead',
          ];
        } else if (isLastDay) {
          variationsVi = [
            'Khép lại tháng này 🌙 Bạn đã làm rất tốt, ngủ thật ngon nha!',
            'Đêm cuối tháng 🕯️ Gác lại mọi âu lo, mai đón tháng mới thật tươi nhé',
          ];
          variationsEn = [
            'Wrapping up this month 🌙 You did great, sleep well tonight',
            'Last night of the month 🕯️ Rest up for the new chapter tomorrow',
          ];
        } else {
          variationsVi = [
            'Một ngày nữa sắp kết thúc 🌙 Chúc bạn ngủ thật ngon',
            'Đến giờ đi ngủ rồi 🕯️ Gác lại âu lo và ngủ ngon nha',
            'Đêm muộn rồi 🌌 Nghỉ ngơi để mai đón ngày mới thật tươi nhé',
          ];
          variationsEn = [
            'Day is winding down 🌙 Sleep well tonight',
            'Wind down time 🕯️ Rest easy and recharge',
            'Late night 🌌 Good night and sweet dreams',
          ];

          if (weekday == DateTime.sunday) {
            variationsVi.insert(0, 'Chủ Nhật sắp qua rồi 🌙 Ngủ ngon mai lại chiến tiếp nha');
            variationsEn.insert(0, 'Sunday is almost over 🌙 Sleep well for tomorrow');
          }
        }

        return DailyMomentData(
          greetingIcon: '🌙',
          greetingText: _selectVariation(
            isVi ? variationsVi : variationsEn,
            now,
            12,
          ),
          mood: DailyMood(
            icon: '🌙',
            label: isFirstDay ? (isVi ? 'Tháng mới' : 'New month') : (isVi ? 'Đi ngủ' : 'Bedtime'),
            accentColor: const Color(0xFF8B7CFF),
          ),
          category: (isFirstDay || isLastDay) ? DailyMomentCategory.specialEvent : DailyMomentCategory.timeOfDayEvent,
          timeSlot: slot,
        );
    }
  }
}
