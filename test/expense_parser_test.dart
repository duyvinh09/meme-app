import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/core/services/expense_parser.dart';

void main() {
  group('ExpenseParser Vietnamese & English Tests', () {
    test('User Example 1: Trưa nay mình ăn phở bò hết 45 nghìn', () {
      final res = ExpenseParser.parse('Trưa nay mình ăn phở bò hết 45 nghìn');
      expect(res.amount, 45000);
      expect(res.currency, 'VND');
      expect(res.category, 'Ăn uống');
      expect(res.hasAmount, true);
      expect(res.hasCategory, true);
      expect(res.isHighConfidence, true);
    });

    test('User Example 2: Mua áo hết 350k', () {
      final res = ExpenseParser.parse('Mua áo hết 350k');
      expect(res.amount, 350000);
      expect(res.currency, 'VND');
      expect(res.category, 'Mua sắm');
      expect(res.hasAmount, true);
    });

    test('User Example 3: Đổ xăng 70 ngàn', () {
      final res = ExpenseParser.parse('Đổ xăng 70 ngàn');
      expect(res.amount, 70000);
      expect(res.category, 'Đi lại');
      expect(res.hasAmount, true);
    });

    test('User Example 4: Tối qua đi xem phim hết 120 nghìn', () {
      final res = ExpenseParser.parse('Tối qua đi xem phim hết 120 nghìn');
      expect(res.amount, 120000);
      expect(res.category, 'Giải trí');
      expect(res.hasAmount, true);
    });

    test('User Example 5: Được công ty trả lương 10 triệu', () {
      final res = ExpenseParser.parse('Được công ty trả lương 10 triệu');
      expect(res.amount, 10000000);
      expect(res.category, 'Lương');
      expect(res.type, 'income');
      expect(res.hasAmount, true);
    });

    test('User Example 6: Mua quà sinh nhật cho mẹ 500 nghìn', () {
      final res = ExpenseParser.parse('Mua quà sinh nhật cho mẹ 500 nghìn');
      expect(res.amount, 500000);
      expect(res.category, 'Quà tặng');
      expect(res.hasAmount, true);
    });

    test('User Example 7: Đóng học phí 2 triệu', () {
      final res = ExpenseParser.parse('Đóng học phí 2 triệu');
      expect(res.amount, 2000000);
      expect(res.category, 'Học tập');
      expect(res.hasAmount, true);
    });

    test('User Example 8: Mua đồ 1 triệu 200', () {
      final res = ExpenseParser.parse('Mua đồ 1 triệu 200');
      expect(res.amount, 1200000);
      expect(res.category, 'Mua sắm');
      expect(res.hasAmount, true);
    });

    test('User Example 9: 2 triệu rưỡi', () {
      final res = ExpenseParser.parse('Mua giày 2 triệu rưỡi');
      expect(res.amount, 2500000);
      expect(res.category, 'Mua sắm');
    });

    test('English Example 1: Had lunch for 15 dollars', () {
      final res = ExpenseParser.parse('Had lunch for 15 dollars');
      expect(res.amount, 15);
      expect(res.currency, 'USD');
      expect(res.category, 'Ăn uống');
      expect(res.hasAmount, true);
      expect(res.isHighConfidence, true);
    });

    test('English Example 2: Bought a shirt for \$45', () {
      final res = ExpenseParser.parse('Bought a shirt for \$45');
      expect(res.amount, 45);
      expect(res.currency, 'USD');
      expect(res.category, 'Mua sắm');
      expect(res.hasAmount, true);
    });

    test('English Example 3: Paid 30 dollars for gas', () {
      final res = ExpenseParser.parse('Paid 30 dollars for gas');
      expect(res.amount, 30);
      expect(res.currency, 'USD');
      expect(res.category, 'Đi lại');
      expect(res.hasAmount, true);
    });

    test('English Example 4: Received 3000 dollars salary', () {
      final res = ExpenseParser.parse('Received 3000 dollars salary');
      expect(res.amount, 3000);
      expect(res.currency, 'USD');
      expect(res.category, 'Lương');
      expect(res.type, 'income');
    });

    test('Fallback to Khác when category is not mentioned', () {
      final res = ExpenseParser.parse('Chi 50k');
      expect(res.amount, 50000);
      expect(res.category, 'Khác');
      expect(res.hasCategory, false);
      expect(res.hasAmount, true);
    });

    test('Explicit category Khác', () {
      final res = ExpenseParser.parse('Khoản khác 100k');
      expect(res.amount, 100000);
      expect(res.category, 'Khác');
      expect(res.hasCategory, true);
    });

    test('Conversation phrase: what\'s your name should NOT match Shopping or any other category', () {
      final res = ExpenseParser.parse('what\'s your name');
      expect(res.category, 'Khác');
      expect(res.hasCategory, false);
      expect(res.hasAmount, false);
    });

    test('Conversation phrase: hello how are you', () {
      final res = ExpenseParser.parse('hello how are you');
      expect(res.category, 'Khác');
      expect(res.hasCategory, false);
      expect(res.hasAmount, false);
    });

    test('Words containing sub-keywords do NOT trigger false positives (person, teacher, business, against, cable, price)', () {
      final res1 = ExpenseParser.parse('met a nice person today');
      expect(res1.category, 'Khác');
      expect(res1.hasCategory, false);

      final res2 = ExpenseParser.parse('talked with teacher');
      expect(res2.category, 'Khác');
      expect(res2.hasCategory, false);

      final res3 = ExpenseParser.parse('business meeting');
      expect(res3.category, 'Khác');
      expect(res3.hasCategory, false);

      final res4 = ExpenseParser.parse('vote against this');
      expect(res4.category, 'Khác');
      expect(res4.hasCategory, false);
    });

    test('Vietnamese diacritics: cháo gà 35k should match Ăn uống, NOT Mua sắm (áo)', () {
      final res = ExpenseParser.parse('cháo gà 35k');
      expect(res.amount, 35000);
      expect(res.category, 'Ăn uống');
      expect(res.hasCategory, true);
      expect(res.hasAmount, true);
    });

    test('Vietnamese diacritics: mua cháo gà 35k should match Ăn uống', () {
      final res = ExpenseParser.parse('mua cháo gà 35k');
      expect(res.amount, 35000);
      expect(res.category, 'Ăn uống');
      expect(res.hasCategory, true);
      expect(res.hasAmount, true);
    });

    test('Quỹ nhóm: nạp quỹ nhóm 200k', () {
      final res = ExpenseParser.parse('nạp quỹ nhóm 200k');
      expect(res.amount, 200000);
      expect(res.category, 'Quỹ nhóm');
      expect(res.categoryKey, 'group_fund');
      expect(res.hasCategory, true);
      expect(res.hasAmount, true);
    });

    test('Quỹ nhóm: đóng quỹ nhóm 500 nghìn', () {
      final res = ExpenseParser.parse('đóng quỹ nhóm 500 nghìn');
      expect(res.amount, 500000);
      expect(res.category, 'Quỹ nhóm');
      expect(res.categoryKey, 'group_fund');
      expect(res.hasCategory, true);
    });

    test('Quỹ nhóm English: deposit 50 dollars to group fund', () {
      final res = ExpenseParser.parse('deposit 50 dollars to group fund');
      expect(res.amount, 50);
      expect(res.currency, 'USD');
      expect(res.category, 'Quỹ nhóm');
      expect(res.categoryKey, 'group_fund');
      expect(res.hasCategory, true);
    });

    group('Billions and Hundreds of Billions (Trăm tỷ) Tests', () {
      test('100 tỷ', () {
        final res = ExpenseParser.parse('Mua nhà 100 tỷ');
        expect(res.amount, 100000000000);
        expect(res.currency, 'VND');
        expect(res.hasAmount, true);
        expect(res.caption, 'Mua nhà');
      });

      test('250 tỷ', () {
        final res = ExpenseParser.parse('Đầu tư dự án 250 tỷ');
        expect(res.amount, 250000000000);
        expect(res.currency, 'VND');
        expect(res.hasAmount, true);
      });

      test('100 tỷ 500 triệu', () {
        final res = ExpenseParser.parse('Mua đất 100 tỷ 500 triệu');
        expect(res.amount, 100500000000);
        expect(res.hasAmount, true);
      });

      test('100 tỷ rưỡi', () {
        final res = ExpenseParser.parse('Mua toà nhà 100 tỷ rưỡi');
        expect(res.amount, 100500000000);
        expect(res.hasAmount, true);
      });

      test('một trăm tỷ in words', () {
        final res = ExpenseParser.parse('Thưởng dự án một trăm tỷ');
        expect(res.amount, 100000000000);
        expect(res.hasAmount, true);
      });

      test('hai trăm tỷ in words', () {
        final res = ExpenseParser.parse('Đầu tư hai trăm tỷ');
        expect(res.amount, 200000000000);
        expect(res.hasAmount, true);
      });

      test('1 tỷ rưỡi', () {
        final res = ExpenseParser.parse('Mua xe 1 tỷ rưỡi');
        expect(res.amount, 1500000000);
        expect(res.hasAmount, true);
      });

      test('Plain 12-digit number (100 billion)', () {
        final res = ExpenseParser.parse('Chuyển khoản 100000000000 đ');
        expect(res.amount, 100000000000);
        expect(res.hasAmount, true);
      });
    });

    group('Caption Cleaning and Currency Word Stripping Tests', () {
      test('User case 1: Đi uống cà phê Highland ngon 25.000 đồng', () {
        final res = ExpenseParser.parse('Đi uống cà phê Highland ngon 25.000 đồng');
        expect(res.amount, 25000);
        expect(res.category, 'Ăn uống');
        expect(res.caption, 'Đi uống cà phê Highland ngon');
        expect(res.hasAmount, true);
      });

      test('User case 2: mua trà sữa 90000đ cho bạn', () {
        final res = ExpenseParser.parse('mua trà sữa 90000đ cho bạn');
        expect(res.amount, 90000);
        expect(res.category, 'Ăn uống');
        expect(res.caption, 'Mua trà sữa cho bạn');
        expect(res.hasAmount, true);
      });

      test('Currency variation: 90.000 đồng', () {
        final res = ExpenseParser.parse('mua trà sữa 90.000 đồng cho bạn');
        expect(res.amount, 90000);
        expect(res.caption, 'Mua trà sữa cho bạn');
      });

      test('Currency variation: 90 nghìn đồng', () {
        final res = ExpenseParser.parse('mua trà sữa 90 nghìn đồng cho bạn');
        expect(res.amount, 90000);
        expect(res.caption, 'Mua trà sữa cho bạn');
      });

      test('Currency variation: 90k việt nam đồng', () {
        final res = ExpenseParser.parse('mua trà sữa 90k việt nam đồng cho bạn');
        expect(res.amount, 90000);
        expect(res.caption, 'Mua trà sữa cho bạn');
      });

      test('Currency variation: 90000 vnđ', () {
        final res = ExpenseParser.parse('mua trà sữa 90000 vnđ cho bạn');
        expect(res.amount, 90000);
        expect(res.caption, 'Mua trà sữa cho bạn');
      });

      test('User case 3: nhận lương 25.000đ trên tháng này does NOT cut "trên" into "ên"', () {
        final res = ExpenseParser.parse('nhận lương 25.000đ trên tháng này');
        expect(res.amount, 25000);
        expect(res.category, 'Lương');
        expect(res.type, 'income');
        expect(res.caption, 'Nhận lương trên tháng này');
      });

      test('User case 4: Đi uống cà phê Highland ngon 25.000 ₫ (Unicode dong sign)', () {
        final res = ExpenseParser.parse('Đi uống cà phê Highland ngon 25.000 ₫');
        expect(res.amount, 25000);
        expect(res.category, 'Ăn uống');
        expect(res.caption, 'Đi uống cà phê Highland ngon');
      });

      test('User case 5: mua sách lập trình một trăm tám nghìn -> 180.000đ', () {
        final res = ExpenseParser.parse('mua sách lập trình một trăm tám nghìn');
        expect(res.amount, 180000);
        expect(res.category, 'Học tập');
        expect(res.caption, 'Mua sách lập trình');
      });

      test('User case 6: một trăm hai nghìn -> 120.000đ', () {
        final res = ExpenseParser.parse('mua quà một trăm hai nghìn');
        expect(res.amount, 120000);
        expect(res.caption, 'Mua quà');
      });

      test('User case 7: ba lăm nghìn / ba nhăm nghìn -> 35.000đ', () {
        final res = ExpenseParser.parse('ăn sáng ba lăm nghìn');
        expect(res.amount, 35000);
        expect(res.category, 'Ăn uống');
        expect(res.caption, 'Ăn sáng');

        final res2 = ExpenseParser.parse('ăn sáng ba nhăm nghìn');
        expect(res2.amount, 35000);
      });

      test('User case 8: hai lăm nghìn -> 25.000đ, bốn lăm nghìn -> 45.000đ', () {
        final res1 = ExpenseParser.parse('trà đá hai lăm nghìn');
        expect(res1.amount, 25000);
        expect(res1.caption, 'Trà đá');

        final res2 = ExpenseParser.parse('bún bò bốn lăm nghìn');
        expect(res2.amount, 45000);
        expect(res2.caption, 'Bún bò');
      });

      test('User case 9: hôm nay mình đi ăn với ba người một trăm rưỡi -> 150.000đ and clean caption', () {
        final res = ExpenseParser.parse('hôm nay mình đi ăn với ba người một trăm rưỡi');
        expect(res.amount, 150000);
        expect(res.category, 'Ăn uống');
        expect(res.caption, 'Đi ăn với ba người');
      });

      test('User case 10: hai trăm rưỡi -> 250.000đ, trăm rưỡi -> 150.000đ', () {
        final res1 = ExpenseParser.parse('mua áo hai trăm rưỡi');
        expect(res1.amount, 250000);
        expect(res1.category, 'Mua sắm');
        expect(res1.caption, 'Mua áo');

        final res2 = ExpenseParser.parse('đổ xăng trăm rưỡi');
        expect(res2.amount, 150000);
        expect(res2.category, 'Đi lại');
        expect(res2.caption, 'Đổ xăng');
      });

      test('User case 11: mua sách hết một triệu hai trăm nghìn -> 1.200.000đ', () {
        final res = ExpenseParser.parse('mua sách hết một triệu hai trăm nghìn');
        expect(res.amount, 1200000);
        expect(res.category, 'Học tập');
        expect(res.caption, 'Mua sách');

        final resTypo = ExpenseParser.parse('mua sách hết một triệu hai trắm nghìn');
        expect(resTypo.amount, 1200000);
        expect(resTypo.caption, 'Mua sách');
      });

      test('User case 12: mua sách hết hai triệu không trăm tám chục nghìn -> 2.080.000đ', () {
        final res = ExpenseParser.parse('mua sách hết hai triệu không trăm tám chục nghìn');
        expect(res.amount, 2080000);
        expect(res.category, 'Học tập');
        expect(res.caption, 'Mua sách');
      });

      test('User case 13: mua đồ ba triệu năm trăm năm mươi nghìn -> 3.550.000đ', () {
        final res = ExpenseParser.parse('mua đồ ba triệu năm trăm năm mươi nghìn');
        expect(res.amount, 3550000);
        expect(res.category, 'Mua sắm');
        expect(res.caption, 'Mua đồ');
      });

      test('User case 14: mua sách hát hai triệu không trăm tám chục ngàn -> 2.080.000đ and clean caption', () {
        final res = ExpenseParser.parse('mua sách hát hai triệu không trăm tám chục ngàn');
        expect(res.amount, 2080000);
        expect(res.category, 'Học tập');
        expect(res.caption, 'Mua sách');
      });

      test('User case 15: mua sách hát 2 triệu không trăm tám chục ngàn (with digit 2) -> 2.080.000đ and clean caption', () {
        final res = ExpenseParser.parse('mua sách hát 2 triệu không trăm tám chục ngàn');
        expect(res.amount, 2080000);
        expect(res.category, 'Học tập');
        expect(res.caption, 'Mua sách');
      });

      test('User case 16: mua sách 2 triệu không trăm 80 ngàn -> 2.080.000đ', () {
        final res = ExpenseParser.parse('mua sách 2 triệu không trăm 80 ngàn');
        expect(res.amount, 2080000);
        expect(res.category, 'Học tập');
        expect(res.caption, 'Mua sách');
      });

      test('User case 17: mua đồ 3 triệu năm trăm năm mươi nghìn (digit 3) -> 3.550.000đ', () {
        final res = ExpenseParser.parse('mua đồ 3 triệu năm trăm năm mươi nghìn');
        expect(res.amount, 3550000);
        expect(res.category, 'Mua sắm');
        expect(res.caption, 'Mua đồ');
      });

      test('User case 18: mua sách 2 triệu không trăm lẻ tám nghìn -> 2.008.000đ', () {
        final res = ExpenseParser.parse('mua sách 2 triệu không trăm lẻ tám nghìn');
        expect(res.amount, 2008000);
        expect(res.category, 'Học tập');
        expect(res.caption, 'Mua sách');
      });

      test('User case 19: STT split artifact: mua đồ 3.500.000 50.000 -> 3.550.000đ and clean caption "Mua đồ"', () {
        final res = ExpenseParser.parse('mua đồ 3.500.000 50.000');
        expect(res.amount, 3550000);
        expect(res.category, 'Mua sắm');
        expect(res.caption, 'Mua đồ');
      });

      test('User case 20: STT dot artifact: mua đồ 3.500.000 .000 -> 3.500.000đ and clean caption "Mua đồ"', () {
        final res = ExpenseParser.parse('mua đồ 3.500.000 .000');
        expect(res.amount, 3500000);
        expect(res.category, 'Mua sắm');
        expect(res.caption, 'Mua đồ');
      });

      test('User case 21: STT split with k: mua đồ 3.500.000 50k -> 3.550.000đ and clean caption "Mua đồ"', () {
        final res = ExpenseParser.parse('mua đồ 3.500.000 50k');
        expect(res.amount, 3550000);
        expect(res.category, 'Mua sắm');
        expect(res.caption, 'Mua đồ');
      });

      test('User case 22: STT split with trieu: mua đồ 3 triệu 50.000 -> 3.050.000đ and clean caption "Mua đồ"', () {
        final res = ExpenseParser.parse('mua đồ 3 triệu 50.000');
        expect(res.amount, 3050000);
        expect(res.category, 'Mua sắm');
        expect(res.caption, 'Mua đồ');
      });

      test('User case 23: STT split with trieu & tram: mua đồ 3 triệu 500 50.000 -> 3.550.000đ and clean caption "Mua đồ"', () {
        final res = ExpenseParser.parse('mua đồ 3 triệu 500 50.000');
        expect(res.amount, 3550000);
        expect(res.category, 'Mua sắm');
        expect(res.caption, 'Mua đồ');
      });
    });
  });
}
