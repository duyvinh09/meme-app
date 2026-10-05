class AppValidators {
  AppValidators._();

  static String? requiredText(
      String value, {
        String message = 'Vui lòng nhập thông tin',
      }) {
    if (value.trim().isEmpty) return message;
    return null;
  }

  static String? email(
    String value, {
    String? requiredMessage,
    String? invalidMessage,
  }) {
    final text = value.trim();

    if (text.isEmpty) {
      return requiredMessage ?? 'Vui lòng nhập email';
    }

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!regex.hasMatch(text)) {
      return invalidMessage ?? 'Email không hợp lệ';
    }

    return null;
  }

  static String? password(
    String value, {
    String? requiredMessage,
    String? minLengthMessage,
  }) {
    final text = value.trim();

    if (text.isEmpty) {
      return requiredMessage ?? 'Vui lòng nhập mật khẩu';
    }

    if (text.length < 6) {
      return minLengthMessage ?? 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    return null;
  }

  static String? username(
    String value, {
    String? requiredMessage,
    String? invalidMessage,
  }) {
    final text = value.trim().toLowerCase();

    if (text.isEmpty) {
      return requiredMessage ?? 'Vui lòng nhập username';
    }

    final regex = RegExp(r'^[a-z0-9._]{3,20}$');

    if (!regex.hasMatch(text)) {
      return invalidMessage ??
          'Username chỉ gồm chữ thường, số, dấu chấm hoặc gạch dưới, từ 3-20 ký tự';
    }

    return null;
  }
}