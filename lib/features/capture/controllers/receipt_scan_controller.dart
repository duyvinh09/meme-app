import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/receipt_scan_result.dart';
import '../services/receipt_scan_service.dart';

enum ReceiptScanPhase { idle, loading, ready, failed }

typedef ReceiptScanner = Future<ReceiptScanResult> Function(File file);

class ReceiptScanController extends ChangeNotifier {
  ReceiptScanController({ReceiptScanner? scanner})
      : _scanner = scanner ?? ReceiptScanService().scan;
  final ReceiptScanner _scanner;
  ReceiptScanPhase _phase = ReceiptScanPhase.idle;
  ReceiptScanResult? _result;
  bool _disposed = false;
  bool _requiresRestart = false;
  int _generation = 0;

  ReceiptScanPhase get phase => _phase;
  ReceiptScanResult? get result => _result;
  bool get requiresRestart => _requiresRestart;
  ReceiptScanSnapshot get snapshot =>
      ReceiptScanSnapshot(result: _result, requiresRestart: _requiresRestart);

  void restoreSnapshot(ReceiptScanSnapshot snapshot) {
    if (_disposed || _phase == ReceiptScanPhase.loading) return;
    _result = snapshot.result;
    _requiresRestart = snapshot.requiresRestart;
    _phase = _result == null ? ReceiptScanPhase.failed : ReceiptScanPhase.ready;
    notifyListeners();
  }

  Future<ReceiptScanResult?> scan(File file) async {
    if (_disposed || _phase == ReceiptScanPhase.loading) return null;
    final generation = ++_generation;
    _phase = ReceiptScanPhase.loading;
    _result = null;
    _requiresRestart = false;
    notifyListeners();
    try {
      final result = await _scanner(file);
      if (_disposed || generation != _generation) return null;
      _result = result;
      _phase = ReceiptScanPhase.ready;
      notifyListeners();
      return result;
    } on Object catch (error, stack) {
      if (_disposed || generation != _generation) return null;
      debugPrint('Receipt scan failed (${error.runtimeType})\n$stack');
      _phase = ReceiptScanPhase.failed;
      _requiresRestart = error is MissingPluginException;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
