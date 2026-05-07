import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MoneyInputFormatter extends TextInputFormatter {
  final int? maxDigits;
  final VoidCallback? onMaxDigitsExceeded;
  final bool allowDecimal;

  MoneyInputFormatter({
    this.maxDigits,
    this.onMaxDigitsExceeded,
    this.allowDecimal = false,
  });

  final NumberFormat _vndFormatter = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (allowDecimal) {
      return _formatDecimal(newValue);
    }

    return _formatInteger(newValue);
  }

  TextEditingValue _formatInteger(TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (maxDigits != null && digits.length > maxDigits!) {
      digits = digits.substring(0, maxDigits);
      onMaxDigitsExceeded?.call();
    }

    final value = int.tryParse(digits) ?? 0;
    final formatted = _vndFormatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  TextEditingValue _formatDecimal(TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    final firstDotIndex = text.indexOf('.');

    if (firstDotIndex != -1) {
      final beforeDot = text.substring(0, firstDotIndex + 1);
      final afterDot = text.substring(firstDotIndex + 1).replaceAll('.', '');
      text = beforeDot + afterDot;
    }

    final parts = text.split('.');

    var integerPart = parts.isNotEmpty ? parts[0] : '';
    var decimalPart = parts.length > 1 ? parts[1] : '';

    if (maxDigits != null && integerPart.length > maxDigits!) {
      integerPart = integerPart.substring(0, maxDigits);
      onMaxDigitsExceeded?.call();
    }

    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    if (integerPart.isEmpty && text.startsWith('.')) {
      integerPart = '0';
    }

    final formatted = parts.length > 1
        ? '$integerPart.$decimalPart'
        : integerPart;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}