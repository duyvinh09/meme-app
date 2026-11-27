import '../../../core/services/tflite_service.dart';

/// An image suggestion must not override a manual edit, bill OCR or type.
class ImageCategoryPolicy {
  static String? categoryFor(
    AiCategoryResult result, {
    required String type,
    required bool manualEdit,
    required bool isBill,
    required bool isContribution,
  }) {
    if (manualEdit ||
        isBill ||
        isContribution ||
        !result.confidence.isFinite ||
        result.confidence < 0.40) {
      return null;
    }
    final mapped = const {
          'Di chuyển': 'Đi lại',
          'Giáo dục': 'Học tập',
        }[result.label] ??
        result.label;
    final allowed = type == 'income'
        ? const {'Lương', 'Quà tặng', 'Khác'}
        : const {'Ăn uống', 'Mua sắm', 'Đi lại', 'Giải trí', 'Học tập', 'Khác'};
    return allowed.contains(mapped) ? mapped : null;
  }
}
