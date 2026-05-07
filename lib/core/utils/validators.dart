class AppValidators {
  AppValidators._();

  static String? requiredText(
      String value, {
        String message = 'Vui lòng nhập thông tin',
      }) {
    if (value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return 'Vui lòng nhập email';
    }

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!regex.hasMatch(text)) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  static String? password(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }

    if (text.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    return null;
  }

  static String? username(String value) {
    final text = value.trim().toLowerCase();

    if (text.isEmpty) {
      return 'Vui lòng nhập username';
    }

    final regex = RegExp(r'^[a-z0-9._]{3,20}$');

    if (!regex.hasMatch(text)) {
      return 'Username chỉ gồm chữ thường, số, dấu chấm hoặc gạch dưới, từ 3-20 ký tự';
    }

    return null;
  }

  static String? moneyText(String value) {
    final cleaned = value
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '');

    final amount = double.tryParse(cleaned);

    if (amount == null || amount <= 0) {
      return 'Vui lòng nhập số tiền hợp lệ';
    }

    return null;
  }

  static String? positiveAmount(double value) {
    if (value <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }

    return null;
  }
}