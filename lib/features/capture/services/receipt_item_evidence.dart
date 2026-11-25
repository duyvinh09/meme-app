import 'receipt_text.dart';

/// Item phrases supplement the bundled model without changing its weights.
class ReceiptItemEvidence {
  static const phrases = {
    'food': [
      'mi 3 mien',
      'mi an lien',
      'mi goi',
      'iced latte',
      'grilled chicken',
      'fried rice',
      'mo hanh',
      'pho mai',
      'sot tieu',
      'sot me',
      'sot chua ngot',
      'hai san',
      'canh chua',
      'canh rau',
      'rau muong',
      'salad',
      'goi cuon',
      'cha gio',
      'nem ran',
      'banh xeo',
      'banh cuon',
      'banh canh',
      'banh bao',
      'banh trang',
      'banh flan',
      'kem dua',
      'bun rieu',
      'bun mam',
      'bun thit nuong',
      'bun dau',
      'mi quang',
      'chao long',
      'chao ga',
      'xoi ga',
      'xoi man',
      'bo kho',
      'lau thai',
      'lau nam',
      'lau bo',
      'lau ca',
      'lau tom',
      'sushi',
      'sashimi',
      'ramen',
      'udon',
      'tokbokki',
      'kim chi',
      'hamburger',
      'burger',
      'spaghetti',
      'pasta',
      'steak',
      'sinh to',
      'nuoc mia',
      'nuoc cam',
      'nuoc dua',
      'nuoc ngot',
      'nuoc suoi',
      'nuoc khoang',
      'tra chanh',
      'tra tac',
      'tra vai',
      'tra o long',
      'matcha',
      'cacao',
      'bac xiu',
      'bia tiger',
      'bia heineken',
      'coca cola',
      'pepsi',
      'aquafina',
      'food',
      'meal',
      'soft drink',
      'orange juice',
      'mineral water',
    ],
    'shopping': [
      'ao thun',
      'ao so mi',
      'ao khoac',
      'quan jean',
      'quan short',
      'giay the thao',
      'tui xach',
      'son moi',
      'kem chong nang',
      'sua rua mat',
      'dau goi',
      'sua tam',
      'nuoc giat',
      'tai nghe',
      'sac du phong',
      'ban phim',
      'chuot may tinh',
      'do gia dung',
      'noi com dien',
      'quat dien',
      'bong den',
      'nuoc hoa',
      'dong ho',
      'op lung',
      'cap sac',
      't shirt',
      'headphones',
      'shampoo',
      'sunscreen',
    ],
    'education': [
      'sach tham khao',
      'sach bai tap',
      'vo ke ngang',
      'vo o ly',
      'but chi',
      'but da quang',
      'thuoc ke',
      'hoc tieng anh',
      'le phi thi',
      'hoc lap trinh',
      'dung cu hoc tap',
      'van phong pham',
      'tap hoc sinh',
      'gom tay',
      'cuc tay',
      'hop but',
      'but muc',
      'compa',
      'sach tieng anh',
      'but long',
      'giay kiem tra',
      'textbook',
      'notebook',
      'ballpoint pen',
      'school supplies',
    ],
    'transport': [
      'phi gui xe',
      'phi do xe',
      'phi cau duong',
      've tau',
      've may bay',
      've xe buyt',
      'dau diesel',
      'xang e5',
      'xang ron',
      'cuoc taxi',
      'phi van chuyen',
      'phi dich vu van tai',
      've xe khach',
      've metro',
      've tau dien',
      'bus ticket',
      'train ticket',
      'parking fee',
      'taxi fare',
    ],
    'entertainment': [
      've khu vui choi',
      've cong vien',
      've ca nhac',
      've bieu dien',
      'gio choi game',
      've bowling',
      've xem kich',
      've concert',
      'gio karaoke',
      've bao tang',
      'movie ticket',
      'cinema ticket',
      'concert ticket',
    ],
    'gift': [
      'hop qua',
      'goi qua',
      'hoa tuoi',
      'thiep chuc mung',
      'qua sinh nhat',
      'qua luu niem',
      'gau bong',
      'gio qua',
      'qua ky niem',
      'gift box',
      'gift wrapping',
      'greeting card',
    ],
    'other': [
      'tien dien',
      'tien nuoc',
      'tien internet',
      'cuoc internet',
      'cuoc vien thong',
      'phi thue nha',
      'tien thue nha',
      'phi quan ly chung cu',
      'electricity bill',
      'water bill',
      'internet bill',
      'house rent',
    ],
  };

  static final Map<String, List<List<String>>> _rules = {
    for (final entry in phrases.entries)
      entry.key: [
        for (final phrase in entry.value) phrase.split(' '),
        if (entry.key == 'food')
          for (final ingredient in [
            'hau',
            'so',
            'oc',
            'ngheu',
            'tom',
            'cua',
            'ghe',
            'muc',
            'bach tuoc',
            'ca',
            'ca hoi',
            'bo',
            'heo',
            'suon',
            'ga',
            'vit',
            'de',
            'ech',
            'dau hu',
            'rau',
            'nam',
            'khoai',
          ])
            for (final method in [
              'nuong',
              'hap',
              'chien',
              'xao',
              'luoc',
              'rang',
              'kho',
            ])
              '$ingredient $method'.split(' '),
      ],
  };

  static Set<String> categories(String normalizedText) {
    final hits = <String>{};
    final clothingNames = <String>{};
    // Never join a merchant/address line to an item on the next line.
    for (final line in normalizeReceiptText(normalizedText).split('\n')) {
      final clothing = _clothingRow.firstMatch(line.trim());
      if (clothing != null) {
        final name =
            clothing.group(2)!.replaceAll('0', 'o').replaceAll('4', 'a');
        final quantity = clothing.group(1);
        final price = clothing.group(3);
        if (quantity != null ||
            (price != null &&
                (int.tryParse(price.replaceAll(RegExp(r'\D'), '')) ?? 0) >=
                    1000)) {
          hits.add('shopping');
        } else if (price == null) {
          clothingNames.add(name);
        }
      }
      for (final entry in _rules.entries) {
        if (entry.value.any((phrase) => matchesLine(line, phrase))) {
          hits.add(entry.key);
        }
      }
    }
    // OCR may return the name column separately from quantities and prices.
    if (clothingNames.length >= 2) hits.add('shopping');
    return hits;
  }

  // Short 'ao/quan/vay' are ambiguous in Vietnamese. Require item-row context
  // rather than matching these words anywhere in addresses or other text.
  static final _clothingRow = RegExp(
      r'^(?:(\d+(?:[.,]\d+)?)\s+)?(quan|ao|a0|vay|v4y|dam|giay|dep|shirt|dress|pants|skirt)(?:\s+([\d., \u202f]+)\s*(?:d|dong|vnd|₫)?)?$');

  /// Try both punctuation-as-noise and common OCR substitutions. Matching
  /// remains inside word boundaries and never crosses a receipt row.
  static bool matchesLine(String line, List<String> phrase) {
    final normalized = normalizeReceiptText(line);
    final variants = {
      normalized,
      normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ''),
      normalized
          .replaceAll('@', 'a')
          .replaceAll('!', 'i')
          .replaceAll('|', 'l')
          .replaceAll(r'$', 's'),
      normalized.replaceAll(RegExp(r'(?<=[a-z])\d(?=[a-z])'), ''),
    };
    final expected = phrase.join();
    for (final variant in variants) {
      final words = RegExp(r'[a-z0-9]+')
          .allMatches(variant)
          .map((match) => match.group(0)!)
          .toList();
      if (matches(words, phrase)) return true;
      // Reconnect words split by OCR, or split words that OCR glued together.
      // Exact compact matching avoids guessing several damaged short words.
      if (expected.length < 5) continue;
      for (var start = 0; start < words.length; start++) {
        var compact = '';
        for (var end = start;
            end < words.length && end < start + phrase.length + 2;
            end++) {
          compact += words[end].replaceAll('0', 'o').replaceAll('1', 'i');
          if (compact == expected) return true;
          if (compact.length > expected.length) break;
        }
      }
    }
    return false;
  }

  /// One damaged word is allowed only with an intact neighbouring word.
  /// Short words and single-word names require exact matches.
  static bool matches(List<String> words, List<String> phrase) {
    for (var start = 0; start + phrase.length <= words.length; start++) {
      var errors = 0;
      var intact = 0;
      for (var i = 0; i < phrase.length; i++) {
        final actual =
            words[start + i].replaceAll('0', 'o').replaceAll('1', 'i');
        final expected = phrase[i];
        if (actual == expected) {
          if (words[start + i] == expected) {
            intact++;
          } else {
            errors++;
          }
        } else if (expected.length >= 4 &&
            actual.length >= 3 &&
            _oneEdit(actual, expected)) {
          errors++;
        } else {
          errors = 2;
          break;
        }
      }
      if (errors == 0 || (errors == 1 && intact > 0)) return true;
    }
    return false;
  }

  static bool _oneEdit(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;
    var i = 0;
    var j = 0;
    var edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
      } else {
        if (++edits > 1) return false;
        if (a.length >= b.length) i++;
        if (b.length >= a.length) j++;
      }
    }
    return edits + a.length - i + b.length - j <= 1;
  }
}
