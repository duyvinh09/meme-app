import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/features/capture/services/receipt_scan_service.dart';

Map<String, Object?> recognized(List<String> lines) {
  final payload = <Map<String, Object?>>[];
  for (var i = 0; i < lines.length; i++) {
    payload.add({
      'text': lines[i],
      'rect': {'left': 0, 'top': i * 30, 'right': 300, 'bottom': i * 30 + 20},
      'points': [],
      'recognizedLanguages': ['vi'],
      'elements': [],
      'confidence': 0.98,
      'angle': 0.0
    });
  }
  return {
    'text': lines.join('\n'),
    'blocks': lines.isEmpty
        ? []
        : [
            {
              'text': lines.join('\n'),
              'rect': {'left': 0, 'top': 0, 'right': 300, 'bottom': 300},
              'points': [],
              'recognizedLanguages': ['vi'],
              'lines': payload,
            }
          ]
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('google_mlkit_text_recognizer');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  var lines = <String>[];
  var fail = false;
  var textOnly = false;
  setUp(() {
    calls.clear();
    fail = false;
    textOnly = false;
    lines = [
      'PHUC LONG',
      'TRA SUA 120000',
      'Tong cong 120000',
      'Giam gia 20000',
      'Thanh toan 100000'
    ];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'vision#startTextRecognizer') {
        if (fail) throw PlatformException(code: 'fixture_ocr_error');
        return textOnly
            ? {'text': lines.join('\n'), 'blocks': []}
            : recognized(lines);
      }
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test('Native OCR lines reach background analysis and recognizer is closed',
      () async {
    final result =
        await ReceiptScanService().scan(File('full-size-receipt.jpg'));
    expect(result.amountVnd, 100000);
    expect(result.category?.category, 'Ăn uống');
    expect(calls.map((call) => call.method),
        ['vision#startTextRecognizer', 'vision#closeTextRecognizer']);
    expect((calls.first.arguments as Map)['id'],
        (calls.last.arguments as Map)['id']);
  });
  test('Native shuffled columns reconstruct the total row before analysis',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method != 'vision#startTextRecognizer') return null;
      final data = recognized([
        '600,000',
        'Tong tien:',
        '700,000',
        '+Thanh toan tien mat',
        '590,000',
        'Thanh tien:'
      ]);
      final block = (data['blocks'] as List).single as Map;
      final nativeLines = block['lines'] as List;
      final coordinates = [
        [500, 110, 600, 130],
        [20, 70, 160, 90],
        [500, 30, 600, 50],
        [20, 110, 270, 130],
        [500, 70, 600, 90],
        [20, 30, 170, 50]
      ];
      for (var i = 0; i < nativeLines.length; i++) {
        final rect = coordinates[i];
        (nativeLines[i] as Map)['rect'] = {
          'left': rect[0],
          'top': rect[1],
          'right': rect[2],
          'bottom': rect[3]
        };
      }
      return data;
    });
    final result = await ReceiptScanService().scan(File('square-receipt.jpg'));
    expect(result.amountVnd, 590000);
    expect(result.recognizedText.split('\n'), [
      'Thanh tien: 700,000',
      'Tong tien: 590,000',
      '+Thanh toan tien mat 600,000'
    ]);
  });
  test('Full OCR text is used when native blocks are missing', () async {
    textOnly = true;
    final result = await ReceiptScanService().scan(File('bill.jpg'));
    expect(result.amountVnd, 100000);
    expect(result.recognizedText, contains('PHUC LONG'));
  });
  test('Empty OCR gives a manual-entry result and releases recognizer',
      () async {
    lines = [];
    final result = await ReceiptScanService().scan(File('blurred.jpg'));
    expect(result.hasText, isFalse);
    expect(result.amountVnd, isNull);
    expect(result.category, isNull);
    expect(calls.last.method, 'vision#closeTextRecognizer');
  });
  test('Foreign-currency receipt is never interpreted as a VND amount',
      () async {
    lines = ['PHUC LONG', 'Grand total 120 USD'];
    final result = await ReceiptScanService().scan(File('dollar-receipt.jpg'));
    expect(result.foreignCurrency, isTrue);
    expect(result.amountVnd, isNull);
  });
  test('Recognizer also closes after native OCR throws', () async {
    fail = true;
    await expectLater(ReceiptScanService().scan(File('bad.jpg')),
        throwsA(isA<PlatformException>()));
    expect(calls.last.method, 'vision#closeTextRecognizer');
  });
}
