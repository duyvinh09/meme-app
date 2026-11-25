import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meme_app/features/capture/controllers/receipt_scan_controller.dart';
import 'package:meme_app/features/capture/models/receipt_scan_result.dart';

void main() {
  test('Preview restores the completed camera scan without running OCR again',
      () {
    var scans = 0;
    final preview = ReceiptScanController(scanner: (_) async {
      scans++;
      return const ReceiptScanResult();
    });
    addTearDown(preview.dispose);
    const result = ReceiptScanResult(amountVnd: 590000);
    preview.restoreSnapshot(const ReceiptScanSnapshot(result: result));
    expect(preview.phase, ReceiptScanPhase.ready);
    expect(preview.result?.amountVnd, 590000);
    expect(scans, 0);
  });

  test('Missing native plugin has an actionable restart state', () async {
    final controller = ReceiptScanController(scanner: (_) async {
      throw MissingPluginException();
    });
    addTearDown(controller.dispose);
    await controller.scan(File('bill.jpg'));
    expect(controller.phase, ReceiptScanPhase.failed);
    expect(controller.requiresRestart, isTrue);
  });

  test('Only one scan runs at a time and state tracks the result', () async {
    final pending = Completer<ReceiptScanResult>();
    var calls = 0;
    final controller = ReceiptScanController(scanner: (_) {
      calls++;
      return pending.future;
    });
    addTearDown(controller.dispose);
    final first = controller.scan(File('bill.jpg'));
    expect(controller.phase, ReceiptScanPhase.loading);
    expect(await controller.scan(File('bill.jpg')), isNull);
    expect(calls, 1);
    pending.complete(const ReceiptScanResult(amountVnd: 100000));
    expect((await first)?.amountVnd, 100000);
    expect(controller.phase, ReceiptScanPhase.ready);
  });
  test('Leaving preview ignores late OCR results and notifications', () async {
    final pending = Completer<ReceiptScanResult>();
    var notifications = 0;
    final controller = ReceiptScanController(scanner: (_) => pending.future);
    controller.addListener(() => notifications++);
    final result = controller.scan(File('bill.jpg'));
    controller.dispose();
    pending.complete(const ReceiptScanResult(amountVnd: 100000));
    expect(await result, isNull);
    expect(notifications, 1);
  });
  test('An OCR failure allows retry and does not leave loading stuck',
      () async {
    var calls = 0;
    final controller = ReceiptScanController(scanner: (_) async {
      if (++calls == 1) throw const FormatException('fixture');
      return const ReceiptScanResult(amountVnd: 100000);
    });
    addTearDown(controller.dispose);
    expect(await controller.scan(File('bill.jpg')), isNull);
    expect(controller.phase, ReceiptScanPhase.failed);
    expect((await controller.scan(File('bill.jpg')))?.amountVnd, 100000);
    expect(controller.phase, ReceiptScanPhase.ready);
  });
}
