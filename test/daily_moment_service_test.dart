import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/data/models/budget_model.dart';
import 'package:meme_app/data/models/transaction_model.dart';
import 'package:meme_app/data/models/user_model.dart';
import 'package:meme_app/features/home/models/daily_moment.dart';
import 'package:meme_app/features/home/services/daily_moment_service.dart';

void main() {
  group('DailyMomentService Time Slots & Greetings', () {
    test('Correctly maps all 12 time slots', () {
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 1, 30)), DailyTimeSlot.lateNight);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 4, 15)), DailyTimeSlot.dawn);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 6, 0)), DailyTimeSlot.earlyMorning);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 7, 45)), DailyTimeSlot.morningRush);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 10, 0)), DailyTimeSlot.focusWork);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 12, 15)), DailyTimeSlot.lunchTime);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 13, 45)), DailyTimeSlot.napRecharge);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 15, 0)), DailyTimeSlot.afternoon);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 17, 30)), DailyTimeSlot.afterWork);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 19, 0)), DailyTimeSlot.dinner);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 20, 30)), DailyTimeSlot.freeTime);
      expect(DailyMomentService.getTimeSlot(DateTime(2026, 9, 15, 23, 0)), DailyTimeSlot.windDown);
    });

    test('Resolves bilingual greeting (VI & EN) and priority contexts', () {
      final user = UserModel(
        uid: 'u1',
        name: 'Vinh',
        username: 'vinh',
        email: 'vinh@test.com',
        avatarUrl: '',
        currency: 'VND',
        language: 'vi',
        themeMode: 'system',
        currentStreak: 10,
        bestStreak: 15,
        createdAt: DateTime(2026, 1, 1),
        lastActiveDate: DateTime(2026, 9, 13),
      );

      // 1. Test 1st day of month (Special event merged into time slot)
      final firstDayMomentVi = DailyMomentService.resolveMoment(
        profile: user,
        transactions: [],
        languageCode: 'vi',
        mockNow: DateTime(2026, 10, 1, 9, 0),
      );
      expect(firstDayMomentVi.category, DailyMomentCategory.specialEvent);
      expect(firstDayMomentVi.greetingText.toLowerCase().contains('tháng'), true);

      final firstDayMomentEn = DailyMomentService.resolveMoment(
        profile: user,
        transactions: [],
        languageCode: 'en',
        mockNow: DateTime(2026, 10, 1, 9, 0),
      );
      expect(firstDayMomentEn.greetingText.toLowerCase().contains('month'), true);

      // 2. Test fresh transaction logging in last 15 mins (Spending event)
      final freshTx = TransactionModel(
        id: 'tx1',
        userId: 'u1',
        amount: 45000,
        type: 'expense',
        category: 'Ăn uống',
        caption: 'Cơm trưa',
        note: '',
        imageUrl: '',
        createdAt: DateTime(2026, 9, 15, 12, 5),
        locationName: '',
        sharedToFeed: false,
        privacy: 'private',
      );

      final freshMoment = DailyMomentService.resolveMoment(
        profile: user,
        transactions: [freshTx],
        languageCode: 'vi',
        mockNow: DateTime(2026, 9, 15, 12, 10),
      );
      expect(freshMoment.category, DailyMomentCategory.spendingEvent);
      expect(freshMoment.greetingText.toLowerCase().contains('ghi') || freshMoment.greetingText.toLowerCase().contains('bữa') || freshMoment.greetingText.toLowerCase().contains('nạp'), true);

      // 3. Test over budget warning
      final overBudget = BudgetModel(
        id: 'b1',
        userId: 'u1',
        name: 'Ăn uống',
        iconCodePoint: 0xe532,
        colorHex: '#FF0000',
        limitAmount: 500000,
        spentAmount: 550000,
        isDefault: false,
        period: 'month',
        budgetType: 'category',
        createdAt: DateTime.now(),
      );

      final overBudgetMoment = DailyMomentService.resolveMoment(
        profile: user,
        transactions: [],
        budgets: [overBudget],
        languageCode: 'vi',
        mockNow: DateTime(2026, 9, 15, 15, 0),
      );
      expect(overBudgetMoment.category, DailyMomentCategory.spendingEvent);
      expect(overBudgetMoment.greetingText.toLowerCase().contains('ví') || overBudgetMoment.greetingText.toLowerCase().contains('ngân sách') || overBudgetMoment.greetingText.toLowerCase().contains('chạm'), true);
    });
  });
}
