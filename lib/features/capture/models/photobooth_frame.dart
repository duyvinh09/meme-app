import 'dart:convert';

import 'package:flutter/services.dart';

enum PhotoboothTheme { film, cute, love, celebration, personality, comments }

class PhotoboothFrame {
  const PhotoboothFrame({
    required this.id,
    required this.name,
    required this.asset,
    required this.thumbnail,
    required this.slots,
    this.masks = const [],
    this.theme = PhotoboothTheme.personality,
  });

  final String id;
  final String name;
  final String asset;
  final String thumbnail;

  /// Ordered source coordinates on a 1080 × 1080 canvas.
  final List<Rect> slots;
  final List<String> masks;
  final PhotoboothTheme theme;
  int get shotCount => slots.length;

  static Future<List<PhotoboothFrame>> loadCatalog() async {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/photobooth/catalog.json'),
    ) as Map<String, dynamic>;
    if (raw['version'] != 1 || raw['canvasSize'] != 1080) {
      throw const FormatException('Unsupported photobooth catalog');
    }
    return List.unmodifiable((raw['frames'] as List<dynamic>).map((entry) {
      final value = entry as Map<String, dynamic>;
      final slots = (value['slots'] as List<dynamic>).map((slot) {
        final rect = (slot as List<dynamic>).cast<num>();
        return Rect.fromLTWH(rect[0].toDouble(), rect[1].toDouble(),
            rect[2].toDouble(), rect[3].toDouble());
      }).toList(growable: false);
      if (slots.isEmpty ||
          slots.length > 4 ||
          slots.any((rect) =>
              rect.isEmpty ||
              rect.left < 0 ||
              rect.top < 0 ||
              rect.right > 1080 ||
              rect.bottom > 1080)) {
        throw FormatException('Invalid slots: ${value['id']}');
      }
      return PhotoboothFrame(
        id: value['id'] as String,
        name: value['name'] as String,
        asset: value['asset'] as String,
        thumbnail: value['thumbnail'] as String,
        theme: PhotoboothTheme.values
            .byName(value['theme'] as String? ?? 'personality'),
        slots: List.unmodifiable(slots),
        masks:
            List.unmodifiable((value['masks'] as List<dynamic>).cast<String>()),
      );
    }));
  }
}
