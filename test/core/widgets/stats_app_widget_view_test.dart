import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/core/widgets/app_widgets/stats_app_widget_view.dart';

void main() {
  for (final isEn in [false, true]) {
    testWidgets('StatsWidget_DateAndDailyTotals_Fit4x2_${isEn ? 'en' : 'vi'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(380, 180);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final date = isEn ? 'Wed, 25/11/2026' : 'Thứ Tư, 25/11/2026';
      await tester.pumpWidget(
        MaterialApp(
          home: StatsAppWidgetView(
            data: StatsWidgetData(
              totalExpense: 600000,
              todayExpense: 50000,
              todayIncome: 100000,
              previousMonthExpense: 500000,
              monthLabel: isEn ? 'This Month' : 'Tháng này',
              dateLabel: date,
              isEn: isEn,
              categories: List.generate(
                6,
                (i) => CategoryShare(
                  name: 'Category $i',
                  amount: 100000,
                  percentage: 100 / 6,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text(date), findsOneWidget);
      expect(find.text('+100k'), findsOneWidget);
      expect(find.text('-50k'), findsOneWidget);
      final dateBounds = tester.getRect(find.text(date));
      expect(dateBounds.top, greaterThanOrEqualTo(14));
      expect(dateBounds.bottom, lessThanOrEqualTo(42));
      expect(tester.takeException(), isNull);
    });
  }
}
