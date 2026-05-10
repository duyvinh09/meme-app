import 'package:translator/translator.dart';

class BudgetTranslationService {
  BudgetTranslationService._();

  static final GoogleTranslator _translator = GoogleTranslator();

  static Future<String?> translateVietnameseToEnglish(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    try {
      final translated = await _translator.translate(
        trimmed,
        from: 'vi',
        to: 'en',
      );
      final output = translated.text.trim();
      if (output.isEmpty) return null;
      return sentenceCase(output);
    } catch (_) {
      return null;
    }
  }

  /// English UI: user types English → stored Vietnamese `name`, English `nameEn`.
  static Future<String?> translateEnglishToVietnamese(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    try {
      final translated = await _translator.translate(
        trimmed,
        from: 'en',
        to: 'vi',
      );
      final output = translated.text.trim();
      if (output.isEmpty) return null;
      return output;
    } catch (_) {
      return null;
    }
  }

  static String sentenceCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
