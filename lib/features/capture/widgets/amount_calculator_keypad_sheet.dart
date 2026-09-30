import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountCalculatorKeypadSheet extends StatefulWidget {
  final String initialAmount;
  final String currency;
  final String amountPrefix;
  final Color accentColor;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback? onConfirm;
  final VoidCallback? onMaxDigitsExceeded;

  const AmountCalculatorKeypadSheet({
    super.key,
    required this.initialAmount,
    required this.currency,
    required this.amountPrefix,
    required this.accentColor,
    required this.onAmountChanged,
    this.onConfirm,
    this.onMaxDigitsExceeded,
  });

  static Future<String?> show(
    BuildContext context, {
    required String initialAmount,
    required String currency,
    required String amountPrefix,
    required Color accentColor,
    required ValueChanged<String> onAmountChanged,
    VoidCallback? onConfirm,
    VoidCallback? onMaxDigitsExceeded,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => AmountCalculatorKeypadSheet(
        initialAmount: initialAmount,
        currency: currency,
        amountPrefix: amountPrefix,
        accentColor: accentColor,
        onAmountChanged: onAmountChanged,
        onConfirm: onConfirm,
        onMaxDigitsExceeded: onMaxDigitsExceeded,
      ),
    );
  }

  @override
  State<AmountCalculatorKeypadSheet> createState() =>
      _AmountCalculatorKeypadSheetState();
}

class _AmountCalculatorKeypadSheetState
    extends State<AmountCalculatorKeypadSheet> {
  // Biểu thức thô dạng chuỗi ký tự máy tính (vd: "50000+35000*2")
  String _rawExpression = '';
  final NumberFormat _vndFormatter = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _syncInitialAmount();
  }

  @override
  void didUpdateWidget(covariant AmountCalculatorKeypadSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAmount != widget.initialAmount && _rawExpression.isEmpty) {
      _syncInitialAmount();
    }
  }

  void _syncInitialAmount() {
    final clean = widget.initialAmount.replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.isNotEmpty && clean != '0') {
      _rawExpression = clean;
    }
  }

  bool get _isUsd => widget.currency.toUpperCase() == 'USD';

  /// Lấy phân đoạn số hiện tại đang nhập ở cuối biểu thức
  String get _currentNumberSegment {
    if (_rawExpression.isEmpty) return '';
    final lastOpIndex = _rawExpression.lastIndexOf(RegExp(r'[+\-*/]'));
    if (lastOpIndex == -1) return _rawExpression;
    return _rawExpression.substring(lastOpIndex + 1);
  }

  /// Tính toán kết quả của biểu thức
  double? get _calculatedResult {
    if (_rawExpression.isEmpty) return null;
    return _MathExpressionEvaluator.evaluate(_rawExpression);
  }

  /// Biểu thức có chứa phép toán hay không (+, -, *, /)
  bool get _hasOperator {
    return _rawExpression.contains(RegExp(r'[+\-*/]'));
  }

  /// Định dạng 1 số độc lập sang dạng tiền tệ đẹp mắt
  String _formatNumberString(String numberStr) {
    if (numberStr.isEmpty) return '';
    if (_isUsd) {
      final parts = numberStr.split('.');
      final intPart = parts[0];
      final formattedInt = intPart.isEmpty
          ? '0'
          : NumberFormat('#,##0', 'en_US').format(int.tryParse(intPart) ?? 0);
      if (parts.length > 1) {
        return '$formattedInt.${parts[1]}';
      }
      return numberStr.endsWith('.') ? '$formattedInt.' : formattedInt;
    } else {
      final clean = numberStr.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isEmpty) return '';
      final val = int.tryParse(clean) ?? 0;
      return _vndFormatter.format(val);
    }
  }

  /// Định dạng toàn bộ biểu thức để hiển thị trực quan cho người dùng
  String get _formattedDisplayExpression {
    if (_rawExpression.isEmpty) return '';

    final buffer = StringBuffer();
    var currentSegment = '';

    for (int i = 0; i < _rawExpression.length; i++) {
      final char = _rawExpression[i];
      if (char == '+' || char == '-' || char == '*' || char == '/') {
        if (currentSegment.isNotEmpty) {
          buffer.write(_formatNumberString(currentSegment));
          currentSegment = '';
        }
        final displayOp = char == '*'
            ? ' × '
            : char == '/'
                ? ' ÷ '
                : ' $char ';
        buffer.write(displayOp);
      } else {
        currentSegment += char;
      }
    }

    if (currentSegment.isNotEmpty) {
      buffer.write(_formatNumberString(currentSegment));
    }

    return buffer.toString();
  }

  /// Trả về số tiền đã tính toán hoàn chỉnh để cập nhật vào controller
  String get _finalFormattedAmountText {
    final result = _calculatedResult;
    if (result == null || result <= 0) {
      if (_rawExpression.isNotEmpty && !_hasOperator) {
        return _formatNumberString(_rawExpression);
      }
      return '';
    }

    if (_isUsd) {
      if (result == result.roundToDouble()) {
        return result.toInt().toString();
      }
      return result.toStringAsFixed(2);
    } else {
      final intVal = result.round();
      return _vndFormatter.format(intVal);
    }
  }

  void _notifyAmountChanged() {
    final formatted = _formattedDisplayExpression;
    widget.onAmountChanged(formatted);
  }

  void _onDigitPressed(String digit) {
    HapticFeedback.selectionClick();
    final seg = _currentNumberSegment;
    if (seg.replaceAll('.', '').length >= 12) {
      widget.onMaxDigitsExceeded?.call();
      return;
    }

    setState(() {
      if (_rawExpression == '0' && digit != '.') {
        _rawExpression = digit;
      } else {
        _rawExpression += digit;
      }
    });
    _notifyAmountChanged();
  }

  void _onThousandShortcutsPressed() {
    HapticFeedback.selectionClick();
    final seg = _currentNumberSegment;
    if (seg.isEmpty || seg == '0') return;
    if (seg.replaceAll('.', '').length + 3 > 12) {
      widget.onMaxDigitsExceeded?.call();
      return;
    }

    setState(() {
      _rawExpression += '000';
    });
    _notifyAmountChanged();
  }

  void _onDotPressed() {
    HapticFeedback.selectionClick();
    final seg = _currentNumberSegment;
    if (seg.contains('.')) return;

    setState(() {
      if (seg.isEmpty) {
        _rawExpression += '0.';
      } else {
        _rawExpression += '.';
      }
    });
    _notifyAmountChanged();
  }

  void _onOperatorPressed(String op) {
    HapticFeedback.mediumImpact();
    if (_rawExpression.isEmpty) {
      if (op == '-') {
        setState(() => _rawExpression = '-');
      }
      return;
    }

    setState(() {
      final lastChar = _rawExpression[_rawExpression.length - 1];
      if (lastChar == '+' ||
          lastChar == '-' ||
          lastChar == '*' ||
          lastChar == '/') {
        _rawExpression =
            _rawExpression.substring(0, _rawExpression.length - 1) + op;
      } else {
        _rawExpression += op;
      }
    });
    _notifyAmountChanged();
  }

  void _onEqualsPressed() {
    HapticFeedback.mediumImpact();
    final result = _calculatedResult;
    if (result != null) {
      setState(() {
        if (_isUsd) {
          _rawExpression = (result == result.roundToDouble())
              ? result.toInt().toString()
              : result.toStringAsFixed(2);
        } else {
          _rawExpression = result.round().toString();
        }
      });
      _notifyAmountChanged();
    }
  }

  void _onBackspacePressed() {
    HapticFeedback.selectionClick();
    if (_rawExpression.isEmpty) return;

    setState(() {
      _rawExpression = _rawExpression.substring(0, _rawExpression.length - 1);
    });
    _notifyAmountChanged();
  }

  void _onClearPressed() {
    HapticFeedback.mediumImpact();
    setState(() {
      _rawExpression = '';
    });
    _notifyAmountChanged();
  }

  void _onDonePressed() {
    HapticFeedback.mediumImpact();
    _onEqualsPressed();
    final finalAmount = _finalFormattedAmountText;
    widget.onAmountChanged(finalAmount);
    if (widget.onConfirm != null) {
      widget.onConfirm!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, finalAmount);
    }
  }

  @override
  void dispose() {
    final finalAmount = _finalFormattedAmountText;
    if (finalAmount.isNotEmpty) {
      widget.onAmountChanged(finalAmount);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Absorb all taps so fast typing never dismisses the keyboard
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! > 7) {
          _onDonePressed();
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 120) {
          _onDonePressed();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161822),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle with gesture support
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! > 4) {
                    _onDonePressed();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Row 1: C, ÷, ×, ⌫
              Row(
                children: [
                  _buildCalcKey(
                    label: 'C',
                    isSpecial: true,
                    textColor: const Color(0xFFFF5252),
                    onTap: _onClearPressed,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '÷',
                    isOperator: true,
                    onTap: () => _onOperatorPressed('/'),
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '×',
                    isOperator: true,
                    onTap: () => _onOperatorPressed('*'),
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    icon: Icons.backspace_outlined,
                    isSpecial: true,
                    textColor: Colors.white70,
                    onTap: _onBackspacePressed,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: 7, 8, 9, -
              Row(
                children: [
                  _buildCalcKey(label: '7', onTap: () => _onDigitPressed('7')),
                  const SizedBox(width: 8),
                  _buildCalcKey(label: '8', onTap: () => _onDigitPressed('8')),
                  const SizedBox(width: 8),
                  _buildCalcKey(label: '9', onTap: () => _onDigitPressed('9')),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '-',
                    isOperator: true,
                    onTap: () => _onOperatorPressed('-'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 3: 4, 5, 6, +
              Row(
                children: [
                  _buildCalcKey(label: '4', onTap: () => _onDigitPressed('4')),
                  const SizedBox(width: 8),
                  _buildCalcKey(label: '5', onTap: () => _onDigitPressed('5')),
                  const SizedBox(width: 8),
                  _buildCalcKey(label: '6', onTap: () => _onDigitPressed('6')),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '+',
                    isOperator: true,
                    onTap: () => _onOperatorPressed('+'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 4: 1, 2, 3, =
              Row(
                children: [
                  _buildCalcKey(label: '1', onTap: () => _onDigitPressed('1')),
                  const SizedBox(width: 8),
                  _buildCalcKey(label: '2', onTap: () => _onDigitPressed('2')),
                  const SizedBox(width: 8),
                  _buildCalcKey(label: '3', onTap: () => _onDigitPressed('3')),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '=',
                    isOperator: true,
                    backgroundColor: widget.accentColor.withValues(alpha: 0.25),
                    textColor: widget.accentColor,
                    onTap: _onEqualsPressed,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 5: 000 / +/-, 0, ., Done
              Row(
                children: [
                  _buildCalcKey(
                    label: _isUsd ? '+/-' : '000',
                    isSpecial: true,
                    onTap: _isUsd
                        ? () => _onOperatorPressed('-')
                        : _onThousandShortcutsPressed,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(label: '0', onTap: () => _onDigitPressed('0')),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    label: '.',
                    isSpecial: true,
                    onTap: _onDotPressed,
                  ),
                  const SizedBox(width: 8),
                  _buildCalcKey(
                    icon: Icons.check_rounded,
                    isAction: true,
                    backgroundColor: widget.accentColor,
                    textColor: Colors.white,
                    onTap: _onDonePressed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalcKey({
    String? label,
    IconData? icon,
    bool isOperator = false,
    bool isSpecial = false,
    bool isAction = false,
    Color? backgroundColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final effectiveBg = backgroundColor ??
        (isOperator
            ? widget.accentColor.withValues(alpha: 0.16)
            : isSpecial
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFF222533));

    final effectiveTextColor = textColor ??
        (isOperator
            ? widget.accentColor
            : isAction
                ? Colors.white
                : Colors.white.withValues(alpha: 0.95));

    return Expanded(
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAction
                ? widget.accentColor
                : isOperator
                    ? widget.accentColor.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.08),
            width: isAction || isOperator ? 1.4 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: isAction
                ? Colors.white.withValues(alpha: 0.25)
                : widget.accentColor.withValues(alpha: 0.25),
            highlightColor: isAction
                ? Colors.white.withValues(alpha: 0.12)
                : widget.accentColor.withValues(alpha: 0.12),
            child: Center(
              child: icon != null
                  ? (label != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 20, color: effectiveTextColor),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                color: effectiveTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      : Icon(icon, size: 22, color: effectiveTextColor))
                  : Text(
                      label ?? '',
                      style: TextStyle(
                        color: effectiveTextColor,
                        fontSize: isOperator ? 23 : (label == '000' ? 17 : 20),
                        fontWeight:
                            isOperator ? FontWeight.w900 : FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MathExpressionEvaluator {
  static double? evaluate(String expression) {
    if (expression.trim().isEmpty) return null;

    String expr = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '');

    while (expr.isNotEmpty &&
        (expr.endsWith('+') ||
            expr.endsWith('-') ||
            expr.endsWith('*') ||
            expr.endsWith('/'))) {
      expr = expr.substring(0, expr.length - 1);
    }
    if (expr.isEmpty) return null;

    try {
      final tokens = <dynamic>[];
      var currentNumber = '';

      for (int i = 0; i < expr.length; i++) {
        final char = expr[i];
        if (char == '+' || char == '-' || char == '*' || char == '/') {
          if (currentNumber.isNotEmpty) {
            final num = double.tryParse(currentNumber);
            if (num == null) return null;
            tokens.add(num);
            currentNumber = '';
          } else if (char == '-' &&
              (tokens.isEmpty || tokens.last is String)) {
            currentNumber = '-';
            continue;
          }
          tokens.add(char);
        } else {
          currentNumber += char;
        }
      }

      if (currentNumber.isNotEmpty) {
        final num = double.tryParse(currentNumber);
        if (num == null) return null;
        tokens.add(num);
      }

      if (tokens.isEmpty) return null;

      // Pass 1: * và /
      final pass1 = <dynamic>[];
      int i = 0;
      while (i < tokens.length) {
        final token = tokens[i];
        if (token == '*' || token == '/') {
          if (pass1.isEmpty ||
              i + 1 >= tokens.length ||
              tokens[i + 1] is! double) {
            return null;
          }
          final prevNum = pass1.removeLast() as double;
          final nextNum = tokens[i + 1] as double;
          if (token == '/') {
            if (nextNum == 0) return null;
            pass1.add(prevNum / nextNum);
          } else {
            pass1.add(prevNum * nextNum);
          }
          i += 2;
        } else {
          pass1.add(token);
          i++;
        }
      }

      // Pass 2: + và -
      if (pass1.isEmpty || pass1.first is! double) return null;
      double result = pass1[0] as double;
      int j = 1;
      while (j < pass1.length) {
        final op = pass1[j] as String;
        if (j + 1 >= pass1.length || pass1[j + 1] is! double) return null;
        final nextNum = pass1[j + 1] as double;
        if (op == '+') {
          result += nextNum;
        } else if (op == '-') {
          result -= nextNum;
        }
        j += 2;
      }

      return result;
    } catch (_) {
      return null;
    }
  }
}
