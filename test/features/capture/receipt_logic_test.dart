import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/features/capture/models/receipt_scan_result.dart';
import 'package:meme_app/features/capture/models/receipt_autofill_policy.dart';
import 'package:meme_app/features/capture/services/receipt_amount_reader.dart';
import 'package:meme_app/features/capture/services/receipt_classifier.dart';
import 'package:meme_app/features/capture/services/receipt_item_evidence.dart';

ReceiptLine line(String text,
        {double x = 0, double y = 0, double width = 100}) =>
    ReceiptLine(text, left: x, top: y, width: width, height: 20);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Final payable amount', () {
    test(
        'Reads exact OCR shown in screenshot: merged total groups and extra text',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Pepsi 3,00 16 000 48 000'),
            line('Tiền hàng: 11 468 500', y: 30),
            line('Tiền thuế: 5% 573425', y: 60),
            line('Tổng: 12 041925 QUANG ĐIỆP', y: 90),
            line('Khach dua: 12 041 925', y: 120),
          ]),
          12041925);
    });
    test('A clean labelled amount can have unrelated trailing OCR words', () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng: 12 041 925 QUANG ĐIỆP'),
          ]),
          12041925);
    });
    test('Broken amount grouping is not repaired from a different cash amount',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng: 12 041925 QUANG ĐIỆP'),
            line('Khách đưa: 13 000 000', y: 30),
          ]),
          isNull);
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng: 12 04O925 QUANG ĐIỆP'),
            line('Khách đưa: 12 041 925', y: 30),
          ]),
          isNull);
    });
    test(
        'A larger isolated footer can be recognized from layout without its label',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('1 AO 260000'),
            line('1 VAY 300000', y: 30),
            const ReceiptLine('Chot so 570000',
                left: 0, top: 100, width: 100, height: 30),
          ]),
          570000);
    });
    test('Prominent footer does not override a later unreadable tax', () {
      expect(
          ReceiptAmountReader.fromLines([
            line('1 AO 260000'),
            line('1 VAY 300000', y: 30),
            const ReceiptLine('560000',
                left: 0, top: 100, width: 100, height: 30),
            line('VAT ??', y: 150),
          ]),
          isNull);
    });
    test(
        'Infers an unknown final label from item amounts rather than vocabulary',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('1 QUAN 260000'),
            line('2 AO 300000', y: 30),
            line('So phai nop hom nay: 560000', y: 90),
            line('Khach dua 1000000', y: 120),
            line('Tra lai 440000', y: 150),
            line('Hotline 0901234567', y: 180),
          ]),
          560000);
    });
    test('Infers a bare final amount with shuffled physical rows', () {
      expect(
          ReceiptAmountReader.fromLines([
            line('560 000', y: 90),
            line('2 AO 300000', y: 30),
            line('1 QUAN 260000'),
          ]),
          560000);
    });
    test('Unknown label inference checks tax and discount arithmetic', () {
      expect(
          ReceiptAmountReader.fromLines([
            line('1 QUAN 260000'),
            line('1 AO 300000', y: 30),
            line('VAT 10% 56000', y: 60),
            line('Giam gia 16000', y: 90),
            line('Ket so: 600000', y: 120),
          ]),
          600000);
    });
    test(
        'Does not turn a last item, phone, cash or inconsistent value into total',
        () {
      final items = [line('1 QUAN 260000'), line('1 AO 300000', y: 30)];
      for (final footer in [
        '',
        'Hotline 0901234567',
        'Khach dua 560000',
        'Tra lai 560000',
        'Ma hoa don 560000',
        'Chot so 999000'
      ]) {
        expect(
            ReceiptAmountReader.fromLines([
              ...items,
              if (footer.isNotEmpty) line(footer, y: 90),
            ]),
            isNull,
            reason: footer);
      }
    });
    for (final label in [
      'Tông',
      'Tông cộng',
      'TỔNG',
      'TONG',
      'Tính tiền',
      'TINH TIEN',
      'T!NH T1EN',
      'Tính tlền'
    ]) {
      test('Reads shop bill total or payment label: $label', () {
        expect(ReceiptAmountReader.fromLines([line('$label: 1,155,000')]),
            1155000);
      });
    }
    for (final money in [
      '1,155,000',
      '1.155.000',
      '1 . 155 . 000',
      '1 , 155 , 000',
      '1. 155. 000'
    ]) {
      test('Reads photographed shop bill including spaced separators: $money',
          () {
        expect(
            ReceiptAmountReader.fromLines([
              line('1 QUAN 260,000'),
              line('2 QUAN 300,000', y: 30),
              line('TONG CONG', y: 60),
              line(money, y: 90),
              line('TINH TIEN 1,155,000', y: 120),
              line('CAM ON QUY KHACH', y: 150),
            ]),
            1155000);
        expect(ReceiptAmountReader.readVnd(money), 1155000);
      });
    }
    test('Payment after discount uses Tinh tien rather than original total',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tông cộng 1,200,000'),
            line('Giảm giá 45,000', y: 30),
            line('Tính tiền 1,155,000', y: 60),
            line('Khách đưa 2,000,000', y: 90),
          ]),
          1155000);
    });
    for (final amount in [
      '12 041 925',
      '12.041.925',
      '12,041,925',
      '12\u00a0041\u00a0925',
      '12\u202f041\u202f925',
      '12.041 925',
      '12 041,925',
      '12   041  925'
    ]) {
      test('Reads supplied bill final total after tax: $amount', () {
        expect(
            ReceiptAmountReader.fromLines([
              line('Tiền hàng: 11 468 500'),
              line('Tiền thuế: 5% 573 425', y: 30),
              line('Tổng: $amount', y: 60),
              line('+ Khách đưa: 12 041 925', y: 90),
              line('+ Trả lại: 0', y: 120),
            ]),
            12041925);
      });
    }
    test('Final total below adjustments uses printed geometry, not input order',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng: 12 041 925', y: 60),
            line('Tiền thuế: 573 425', y: 30),
            line('Tiền hàng: 11 468 500'),
          ]),
          12041925);
    });
    test('A tax or discount after a gross total still requires a final total',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng: 11 468 500'),
            line('Tiền thuế: 573 425', y: 30),
          ]),
          isNull);
    });
    test('A bill total takes precedence over individual line totals', () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Thành tiền: 295,000'),
            line('Thành tiền: 100,000', y: 30),
            line('Tổng cộng: 395,000', y: 60),
          ]),
          395000);
    });
    for (final label in [
      'Tổng số tiền cần trả',
      'Tổng số tiền',
      'Thành tiền',
      'T0ng s0 tien',
      'Tổng@tiền',
      'T.o.n.g c.o.n.g',
      'Tổng2 tiền',
      'Tổng tiền2',
      'Tổng tiền thanh toá',
      'Tổngtiềnthanhtoán',
      'T0ng t!en thanh t0an',
      'Tiền th@nh toán',
      'Thành tlền',
    ]) {
      test('Reads noisy OCR label and its trailing amount: $label', () {
        expect(
            ReceiptAmountReader.fromLines([line('$label: 590,000 đ')]), 590000);
      });
    }
    test('Reads amount attached to the final label', () {
      expect(ReceiptAmountReader.fromLines([line('Tổngtiền590,000đ')]), 590000);
    });
    test('Noisy final payable still wins over gross, cash, change and footer',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng cộng: 600,000'),
            line('Giảm giá: 10,000', y: 30),
            line('T0ng t!en thanh t0an: 590,000', y: 60),
            line('Tiền khách đưa: 1,000,000', y: 90),
            line('Tiền thừa: 410,000', y: 120),
            line('Hotline: 0901234567', y: 150),
          ]),
          590000);
    });
    test('Does not use the last numeric string without a payable label', () {
      for (final text in [
        'MST: 0123456789',
        'Tiền khách đưa: 590,000',
        'Tổng số lượng: 123',
        'Tổng giảm giá: 590,000',
        '2 Hàu nướng 295,000 590,000',
        'Tạm tính: 590,000',
        'Thành tiền: 59O,OOO',
        'Tổng tiền: -100000',
        'Tổng tiền: 1.5',
        'Tổng tiền: 0',
      ]) {
        expect(ReceiptAmountReader.fromLines([line(text)]), isNull,
            reason: text);
      }
    });
    for (final label in [
      'Tổng thanh toán',
      'Total',
      'Tiền phải trả',
      'Tổng cộng',
      'Tổng',
      'Số tiền cần trả',
      'Tiền cần trả',
      'Số tiền thanh toán',
      'Tổng cộng phải trả',
      'Tổng cộng cần thanh toán',
      'Total amount',
      'Total amount due',
      'Total amount payable',
      'Final total',
      'Tóng thanh toan',
      'Tổng thanh toản',
      'Tlen phai tra',
      'Tổng cọng',
      'TotaI',
      'Tota1',
      'T0ng',
      'Grand totaI',
    ]) {
      test('Reads expanded exact or OCR-corrupted label: $label', () {
        expect(
            ReceiptAmountReader.fromLines([line('$label: 590,000')]), 590000);
        expect(
            ReceiptAmountReader.fromLines([
              line(label),
              line('590,000', x: 150),
            ]),
            590000);
      });
    }
    test('Expanded payable labels take precedence after discount', () {
      for (final label in [
        'Tiền phải trả',
        'Tổng cộng phải trả',
        'Total amount due',
        'Tóng thanh toan'
      ]) {
        expect(
            ReceiptAmountReader.fromLines([
              line('Tổng cộng 600.000'),
              line('Giảm giá 10.000', y: 30),
              line('$label: 590.000', y: 60),
            ]),
            590000);
      }
    });
    test('Expanded fuzzy labels reject unrelated numbers and uncertain totals',
        () {
      for (final text in [
        'Subtotal: 590,000',
        'Tổng số lượng: 2',
        'Total discount: 590,000',
        'Tiền khách đưa: 600,000',
        'Tiền thừa: 10,000',
        'Hồng: 590,000',
        'TotaI: 59O,000'
      ]) {
        expect(ReceiptAmountReader.fromLines([line(text)]), isNull,
            reason: text);
      }
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng cộng 600.000'),
            line('Tóng thanh toan: ???', y: 30),
          ]),
          isNull);
      expect(
          ReceiptAmountReader.fromLines([
            line('Total: 590.000'),
            line('Tổng cộng: 580.000', y: 30),
          ]),
          isNull);
    });
    test(
        'Visible OCR from the supplied bill keeps total when cash text touches its value',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('1 Phở gà Đệ nhất Tràng 12295,000'),
            line('590,000'),
            line('An'),
            line('Thành tiền: 590,000'),
            line('Tổng tiền: 590,000'),
            line('+Thành toán tiền mặt590.000'),
          ]),
          590000);
    });
    test(
        'Recognizes a mildly corrupted total label, without changing any digits',
        () {
      expect(
          ReceiptAmountReader.fromLines([line('Tóng tlên: 590,000')]), 590000);
      expect(
          ReceiptAmountReader.fromLines([line('T0ng t1en: 590,000')]), 590000);
    });
    test('Does not fuzzy-match subtotal or guess unreadable monetary digits',
        () {
      expect(
          ReceiptAmountReader.fromLines([line('Tạm tính: 590,000')]), isNull);
      expect(
          ReceiptAmountReader.fromLines([line('Tóng tlên: 59O,OOO')]), isNull);
    });
    test('Currency annotation on label is not confused with amount text', () {
      expect(ReceiptAmountReader.fromLines([line('Tổng tiền (VNĐ): 120.000')]),
          120000);
      expect(
          ReceiptAmountReader.fromLines([
            line('TỔNG THANH TOÁN(VND)'),
            line('₫ 120.000', x: 150),
          ]),
          120000);
    });
    test('Below amount can precede its label in the native OCR block order',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('120.000 đ', y: 30),
            line('Tổng thanh toán'),
          ]),
          120000);
    });
    test('Tax registration text is not an extra tax charge', () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Mã số thuế: 0123456789'),
            line('Tổng tiền 120.000', y: 90),
          ]),
          120000);
    });
    test('Must not take the cash row below a total label as the amount due',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng thanh toán'),
            line('Tiền khách đưa', y: 30),
            line('200000', x: 150, y: 30),
          ]),
          isNull);
    });
    test(
        'Reads the original branch product-total label without confusing quantity',
        () {
      expect(ReceiptAmountReader.fromLines([line('Tổng 2 SP: 120.000 đ')]),
          120000);
      expect(ReceiptAmountReader.fromLines([line('Tổng số lượng: 2')]), isNull);
      expect(
          ReceiptAmountReader.fromLines(
              [line('2 x 100000'), line('MST 123456789')]),
          isNull);
    });
    for (final label in [
      'Tổng cộng',
      'Tổng tiền',
      'TỔNG THANH TOÁN',
      'TONG TIEN',
      'Grand total',
      'Total',
      'Khách cần trả'
    ]) {
      test('Reads $label', () {
        expect(
            ReceiptAmountReader.fromLines([line('$label: 120.000 đ')]), 120000);
      });
    }
    test('Uses final payment after discount, ignoring cash and change', () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng cộng 120.000'),
            line('Giảm giá 20.000', y: 30),
            line('Thanh toán 100.000', y: 60),
            line('Tiền khách đưa 200.000', y: 90),
            line('Tiền thừa 100.000', y: 120),
          ]),
          100000);
    });
    test('Final total includes VAT and service charge', () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tạm tính 100.000'),
            line('VAT 10.000', y: 30),
            line('Phí dịch vụ 5.000', y: 60),
            line('Tổng thanh toán 115.000', y: 90),
          ]),
          115000);
    });
    test('Reads right-hand amount and next-line amount', () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng thanh toán'),
            line('120,000 VND', x: 150),
          ]),
          120000);
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng thanh toán'),
            line('120.000 đ', y: 30),
          ]),
          120000);
    });
    test('Conflicting payments or multiple amount columns require manual input',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng thanh toán 120.000'),
            line('Thanh toán 100.000', y: 30),
          ]),
          isNull);
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng tiền'),
            line('120000', x: 150),
            line('50000', x: 250),
          ]),
          isNull);
    });
    test('Never guesses gross total when discount or final amount is unclear',
        () {
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng cộng 120.000'),
            line('Giảm giá 20.000', y: 30),
          ]),
          isNull);
      expect(
          ReceiptAmountReader.fromLines([
            line('Tổng cộng 120.000'),
            line('Thanh toán ???', y: 30),
          ]),
          isNull);
    });
    test('Rejects foreign currencies, item counts, and numbers without labels',
        () {
      expect(
          ReceiptAmountReader.fromLines([line('Grand total 120 USD')]), isNull);
      expect(
          ReceiptAmountReader.fromLines([
            line('Currency: USD'),
            line('Total 120', y: 30),
          ]),
          isNull);
      expect(ReceiptAmountReader.fromLines([line('Tổng số lượng 12')]), isNull);
      expect(ReceiptAmountReader.fromLines([line('Hotline 19001234')]), isNull);
    });
    test(
        'Accepts whole-VND decimals, rejects negative, zero and oversized totals',
        () {
      expect(ReceiptAmountReader.readVnd('1.200.000,00 VND'), 1200000);
      expect(ReceiptAmountReader.readVnd('1,200,000.00 VND'), 1200000);
      for (final bad in [
        '-100000',
        '0',
        '1.5',
        '1000000000000',
        '12.000,300'
      ]) {
        expect(ReceiptAmountReader.readVnd(bad), isNull, reason: bad);
      }
    });
  });

  group('Receipt category and model', () {
    late ReceiptClassifier classifier;
    setUpAll(() async {
      classifier = await ReceiptClassifier.load();
    });
    test(
        'Recognizes short unaccented clothing items from the supplied shop bill',
        () {
      expect(classifier.suggest('''LINH SHOP
REG 15-03-2025 14:08
CA 1 000022
1 QUAN 260,000
2 QUAN 300,000
3 AO 330,000
1 AO 135,000
1 VAY 130,000
TONG CONG 1,155,000
TINH TIEN 1,155,000
CAM ON QUY KHACH''')?.category, 'Mua sắm');
    });
    for (final row in [
      '1 QUAN 260,000',
      '3 AO 330,000',
      '1 VAY 130,000',
      'QUẦN 260.000',
      'ÁO 330 000',
      'VÁY 130000',
      '1 A0 135,000',
      '1 V4Y 130,000',
      '2 SHIRT 330,000',
      '1 DRESS 130,000'
    ]) {
      test('Short clothing name with item context: $row', () {
        expect(classifier.suggest(row)?.category, 'Mua sắm');
      });
    }
    test('Short names in separate OCR columns still supply clothing evidence',
        () {
      expect(
          classifier.suggest('QUAN\nAO\nVAY\n260000\n330000\n130000')?.category,
          'Mua sắm');
    });
    test('Does not mistake district, restaurant or loan text for clothing', () {
      for (final text in [
        'dia chi quan 1',
        'quan an',
        'quan 1',
        'tien vay 130000',
        'ao ca',
        'vay',
        'ao',
        'quan'
      ]) {
        expect(
            ReceiptItemEvidence.categories(text), isNot(contains('shopping')),
            reason: text);
      }
    });
    final categoryItems = {
      'trà sữa': 'Ăn uống',
      'hàu nướng': 'Ăn uống',
      'bút bi': 'Học tập',
      'sách giáo khoa': 'Học tập',
      'áo thun': 'Mua sắm',
      'kem chống nắng': 'Mua sắm',
      'vé tàu': 'Đi lại',
      'phí gửi xe': 'Đi lại',
      'vé xem phim': 'Giải trí',
      'vé khu vui chơi': 'Giải trí',
      'quà sinh nhật': 'Quà tặng',
      'hộp quà': 'Quà tặng',
      'tiền điện': 'Khác',
      'cước internet': 'Khác',
    };
    for (final entry in categoryItems.entries) {
      for (final text in {
        entry.key,
        entry.key.toUpperCase(),
        entry.key.replaceAll(' ', '@'),
        entry.key.replaceAll(' ', '.'),
        entry.key.replaceAll(' ', ''),
      }) {
        test('Category item survives OCR punctuation or glued words: $text',
            () {
          expect(classifier.suggest('$text 1 92000')?.category, entry.value,
              reason: text);
        });
      }
    }
    for (final entry in {
      'tr@ sua': 'Ăn uống',
      'nuoc kh0ang': 'Ăn uống',
      'sach gia0 khoa': 'Học tập',
      'but2bi': 'Học tập',
      'kem chong nan': 'Mua sắm',
      'sac du ph0ng': 'Mua sắm',
      'phi van chuyen': 'Đi lại',
      'parking fee': 'Đi lại',
      've bieu dlen': 'Giải trí',
      'movie ticket': 'Giải trí',
      'qua sinh nhat': 'Quà tặng',
      'gift wrapping': 'Quà tặng',
      'cuoc internct': 'Khác',
      'electricity bill': 'Khác',
    }.entries) {
      test('Category supports OCR character mistakes: ${entry.key}', () {
        expect(classifier.suggest('${entry.key} 92000')?.category, entry.value);
      });
    }
    test('Punctuation repair does not invent items from footer or mixed rows',
        () {
      for (final text in [
        'mst 0123456789',
        'tong@tien 92000',
        'dia.chi 12 duong abc',
        'but\nbi',
        'tien\ndien',
        'qua\nsinh nhat'
      ]) {
        expect(ReceiptItemEvidence.categories(text), isEmpty, reason: text);
      }
      expect(classifier.suggest('ao@thun\ntra@sua'), isNull);
      expect(classifier.suggest('but@bi\nve@tau'), isNull);
    });
    test('Committed model matches its expected dimensions', () {
      expect(classifier.weights.lengthInBytes,
          classifier.labels.length * classifier.size * 4);
    });
    for (final item in [
      'Hàu nướng mỡ hành',
      'Hầu nướng mỡ hành',
      'hau nuong mo hanh',
      'HÀU NUỚNG MỠ HÀNH',
      'hau nuon mo hanh',
      'hau nuong',
      'hau mo hanh',
      'mo hanh',
      'tom hap',
      'muc xao',
      'so nuong',
      'bach tuoc nuong',
      'ca hoi chien',
      'suon nuong',
      'dau hu chien',
      'lau thai',
      'bun rieu',
      'banh xeo',
      'mi quang',
      'chao long',
      'goi cuon',
      'bo kho',
      'sinh to',
      'nuoc mia',
      'tra tac',
      'sushi',
      'ramen',
      'spaghetti',
      'hamburger',
      'banh xe0',
      'sinh to bo',
      'canh chua ca',
      'ha\u0300u nu\u031bo\u031b\u0301ng mo\u031b\u0303 ha\u0300nh',
    ]) {
      test('Recognizes food item, accents or mild OCR damage: $item', () {
        expect(
            classifier
                .suggest('QUAN ABC\n$item 1 590,000\nTổng 590,000')
                ?.category,
            'Ăn uống');
      });
    }
    for (final entry in {
      'ao thun': 'Mua sắm',
      'kem chong nang': 'Mua sắm',
      'tai nghc': 'Mua sắm',
      'sach bai tap': 'Học tập',
      'but da quang': 'Học tập',
      'phi cau duong': 'Đi lại',
    }.entries) {
      test('Recognizes additional receipt items: ${entry.key}', () {
        expect(
            classifier.suggest('${entry.key} 120000')?.category, entry.value);
      });
    }
    test('Does not force food for mixed purchases', () {
      expect(classifier.suggest('hau nuong mo hanh\nao thun'), isNull);
      expect(classifier.suggest('tom hap\nsach bai tap'), isNull);
    });
    test('Fuzzy item matching needs an intact word and stays on one row', () {
      for (final text in [
        'hau\nnuong',
        'nuong',
        'hanh',
        'tien mat',
        'tong cong',
        'dia chi',
        '590000',
        'hau nu',
        'ao thun',
      ]) {
        expect(ReceiptItemEvidence.categories(text), isNot(contains('food')),
            reason: text);
      }
      expect(ReceiptItemEvidence.matches(['bnnh', 'xe0'], ['banh', 'xeo']),
          isFalse);
    });
    final examples = {
      'QUAN NGOC ANH\nCom chien 45000\nCanh chua 25000\nTong tien 70000':
          'Ăn uống',
      'CAFE AN NHIEN\nTra dao 35000\nHong tra 25000\nTong cong 60000':
          'Ăn uống',
      'FAHASA\nSach giao khoa 100000\nQua tang kem theo 0\nTong cong 100000':
          'Học tập',
      'NHA SACH FAHASA SACH GIAO KHOA BUT BI TONG CONG 110000': 'Học tập',
      'FPT SHOP IPHONE 16 TONG CONG 20000000': 'Mua sắm',
      'PHÚC LONG TRÀ SỮA CÀ PHÊ Tổng cộng 65000': 'Ăn uống',
      'MAI LINH TAXI CUOC TAXI 120000': 'Đi lại',
      'PETROLIMEX XANG RON95 100000': 'Đi lại',
      'LOTTE CINEMA VE XEM PHIM 100000': 'Giải trí',
    };
    for (final entry in examples.entries) {
      test('Uses merchant or item evidence: ${entry.value}', () {
        expect(classifier.suggest(entry.key)?.category, entry.value);
      });
    }
    test('Abstains on weak, empty, numeric-only or mixed-category evidence',
        () {
      for (final text in [
        '',
        '123456789',
        'hello world',
        'Tổng cộng 120000',
        'FPT SHOP IPHONE PHUC LONG TRA SUA'
      ]) {
        expect(classifier.suggest(text), isNull, reason: text);
      }
    });
  });

  group('Autofill does not overwrite user edits', () {
    const policy = ReceiptAutofillPolicy(
        amountRevision: 0, categoryRevision: 0, currency: 'VND');
    test('Can fill untouched VND expense fields', () {
      expect(
          policy.canFillAmount(
              currentRevision: 0,
              currentText: '',
              currentCurrency: 'VND',
              isExpense: true),
          isTrue);
      expect(
          policy.canFillCategory(currentRevision: 0, isExpense: true), isTrue);
    });
    test('Manual input or typing then clearing is preserved', () {
      expect(
          policy.canFillAmount(
              currentRevision: 1,
              currentText: '',
              currentCurrency: 'VND',
              isExpense: true),
          isFalse);
      expect(
          policy.canFillAmount(
              currentRevision: 0,
              currentText: '50000',
              currentCurrency: 'VND',
              isExpense: true),
          isFalse);
      expect(
          policy.canFillCategory(currentRevision: 1, isExpense: true), isFalse);
    });
    test('Income or currency change while reading prevents autofill', () {
      expect(
          policy.canFillAmount(
              currentRevision: 0,
              currentText: '',
              currentCurrency: 'USD',
              isExpense: true),
          isFalse);
      expect(
          policy.canFillAmount(
              currentRevision: 0,
              currentText: '',
              currentCurrency: 'VND',
              isExpense: false),
          isFalse);
      expect(policy.canFillCategory(currentRevision: 0, isExpense: false),
          isFalse);
    });
  });
}
