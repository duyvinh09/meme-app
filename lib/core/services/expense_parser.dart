class ParsedExpenseResult {
  final String caption;
  final double amount;
  final String currency; // 'VND' or 'USD'
  final String category;
  final String categoryKey;
  final String type; // 'expense' or 'income'
  final double confidence;
  final bool hasAmount;
  final bool hasCategory;
  final String originalTranscript;

  const ParsedExpenseResult({
    required this.caption,
    required this.amount,
    this.currency = 'VND',
    required this.category,
    required this.categoryKey,
    this.type = 'expense',
    required this.confidence,
    required this.hasAmount,
    required this.hasCategory,
    required this.originalTranscript,
  });

  bool get isHighConfidence => confidence >= 0.75 && hasAmount && hasCategory;

  ParsedExpenseResult copyWith({
    String? caption,
    double? amount,
    String? currency,
    String? category,
    String? categoryKey,
    String? type,
    double? confidence,
    bool? hasAmount,
    bool? hasCategory,
    String? originalTranscript,
  }) {
    return ParsedExpenseResult(
      caption: caption ?? this.caption,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      categoryKey: categoryKey ?? this.categoryKey,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      hasAmount: hasAmount ?? this.hasAmount,
      hasCategory: hasCategory ?? this.hasCategory,
      originalTranscript: originalTranscript ?? this.originalTranscript,
    );
  }
}

class ExpenseParser {
  ExpenseParser._();

  static const Map<String, String> categoryKeys = {
    'Ăn uống': 'food',
    'Mua sắm': 'shopping',
    'Đi lại': 'transport',
    'Giải trí': 'entertainment',
    'Học tập': 'education',
    'Lương': 'salary',
    'Quà tặng': 'gift',
    'Quỹ nhóm': 'group_fund',
    'Khác': 'other',
  };

  /// Main parse method supporting both Vietnamese & English, and VND/USD
  static ParsedExpenseResult parse(String transcript, {String defaultCurrency = 'VND'}) {
    final raw = transcript.trim();
    if (raw.isEmpty) {
      return ParsedExpenseResult(
        caption: '',
        amount: 0,
        currency: defaultCurrency,
        category: 'Khác',
        categoryKey: 'other',
        confidence: 0.0,
        hasAmount: false,
        hasCategory: false,
        originalTranscript: '',
      );
    }

    final lower = raw.toLowerCase();

    // 1. Parse Amount, Currency, and Matched money span
    final amountResult = _parseAmount(lower, defaultCurrency);
    final double amount = amountResult.amount;
    final String currency = amountResult.currency;
    final bool hasAmount = amountResult.hasAmount;
    final String? moneyMatch = amountResult.matchedString;

    // 2. Classify Category and Type (Bilingual)
    final categoryResult = _classifyCategory(lower);
    final String category = categoryResult.category;
    final String categoryKey = categoryKeys[category] ?? 'food';
    final String type = categoryResult.type;
    final bool hasCategory = categoryResult.hasCategory;

    // 3. Clean Caption (Vietnamese & English)
    final String caption = _cleanCaption(raw, moneyMatch);

    // 4. Calculate Confidence
    double confidence = 0.5;
    if (hasAmount && hasCategory) {
      confidence = 0.95;
      if (categoryResult.matchCount > 1) {
        confidence = 0.98;
      }
    } else if (hasAmount && !hasCategory) {
      confidence = 0.65;
    } else if (!hasAmount && hasCategory) {
      confidence = 0.60;
    } else {
      confidence = 0.30;
    }

    return ParsedExpenseResult(
      caption: caption.isNotEmpty ? caption : raw,
      amount: amount,
      currency: currency,
      category: category,
      categoryKey: categoryKey,
      type: type,
      confidence: confidence,
      hasAmount: hasAmount,
      hasCategory: hasCategory,
      originalTranscript: raw,
    );
  }

  static _AmountParseResult _parseAmount(String text, String defaultCurrency) {
    // 0. English / USD patterns: "$45", "45 dollars", "45 dollar", "45 usd", "45 bucks", "45 đô"
    final usdRegex1 = RegExp(r'\$\s*(\d+(?:[\.,]\d+)?)', caseSensitive: false);
    final matchUsd1 = usdRegex1.firstMatch(text);
    if (matchUsd1 != null) {
      final val = double.tryParse(matchUsd1.group(1)!.replaceAll(',', '.')) ?? 0;
      if (val > 0) {
        return _AmountParseResult(
          amount: val,
          currency: 'USD',
          hasAmount: true,
          matchedString: matchUsd1.group(0),
        );
      }
    }

    final usdRegex2 = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*(?:dollars|dollar|usd|bucks|buck|đô|usd)\b',
      caseSensitive: false,
    );
    final matchUsd2 = usdRegex2.firstMatch(text);
    if (matchUsd2 != null) {
      final val = double.tryParse(matchUsd2.group(1)!.replaceAll(',', '.')) ?? 0;
      if (val > 0) {
        return _AmountParseResult(
          amount: val,
          currency: 'USD',
          hasAmount: true,
          matchedString: matchUsd2.group(0),
        );
      }
    }

    // Normalization for Vietnamese speech STT quirks
    String normalized = text
        .replaceAll('ngàn', 'nghìn')
        .replaceAll('nghin', 'nghìn')
        .replaceAll('trieu', 'triệu')
        .replaceAll('kilo', 'k')
        .replaceAll('trắm', 'trăm')
        .replaceAll('tram', 'trăm')
        .replaceAll('tỉ', 'tỷ')
        .replaceAll(RegExp(r'\bti\b'), 'tỷ');

    // 1. Split formatted numbers (STT split artifact: e.g. "3.500.000 50.000", "2.000.000 80.000", "3 triệu 50.000", "3 triệu 500 50.000", "3.500.000 50k", "3.500.000 50 nghìn")
    final splitFormattedRegex = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+|\d+\s*(?:triệu|tr|củ)(?:\s*\d+(?:\s*trăm)?)?)\s+(\d{1,3}(?:[.,]\d{3})+|\d{1,3}\s*(?:k|nghìn|ngàn))(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|dollars|dollar|bucks|buck|vnđ|vnd|đồng|đô|nghìn|ngàn|triệu|tr|tỷ|ty|bil|usd|k|đ|₫|d))?',
      caseSensitive: false,
    );
    final matchSplit = splitFormattedRegex.firstMatch(normalized);
    if (matchSplit != null) {
      final part1Str = matchSplit.group(1)!;
      final part2Str = matchSplit.group(2)!;
      double part1 = 0;
      if (part1Str.contains('triệu') || part1Str.contains('tr') || part1Str.contains('củ')) {
        final trieuMatch = RegExp(r'(\d+)\s*(?:triệu|tr|củ)(?:\s*(\d+)(?:\s*trăm)?)?').firstMatch(part1Str);
        if (trieuMatch != null) {
          final m = double.tryParse(trieuMatch.group(1)!) ?? 0;
          final subStr = trieuMatch.group(2);
          double sub = 0;
          if (subStr != null) {
            final val = double.tryParse(subStr) ?? 0;
            if (val > 0) {
              if (subStr.length == 1) {
                sub = val * 100000;
              } else if (subStr.length == 2) {
                sub = val * 10000;
              } else if (subStr.length == 3) {
                sub = val * 1000;
              }
            }
          }
          part1 = (m * 1000000) + sub;
        }
      } else {
        part1 = double.tryParse(part1Str.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      }

      double part2 = 0;
      if (part2Str.contains('k') || part2Str.contains('nghìn') || part2Str.contains('ngàn')) {
        final kVal = double.tryParse(part2Str.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        part2 = kVal * 1000;
      } else {
        part2 = double.tryParse(part2Str.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      }

      final total = part1 + part2;
      if (total > 0) {
        return _AmountParseResult(
          amount: total,
          currency: 'VND',
          hasAmount: true,
          matchedString: matchSplit.group(0),
        );
      }
    }

    // 2. Spoken Word-based / Compound amount representations in Vietnamese
    // Evaluated first so composite spoken numbers like "2 triệu không trăm tám chục ngàn",
    // "ba triệu năm trăm năm mươi nghìn", "1 triệu 200k", "2 triệu rưỡi"
    // are parsed completely before simple regexes can greedily consume just "2 triệu".
    final wordAmount = _parseVietnameseWordAmount(normalized);
    if (wordAmount != null) {
      return wordAmount;
    }

    // 2. Billions combinations (Trăm tỷ, chục tỷ, tỷ)
    // 2a. "X tỷ rưỡi" / "X billion and a half"
    final ruoiTyRegex = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*(?:tỷ|ty|billion|bil)\s*(?:rưỡi|and a half)(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?',
      caseSensitive: false,
    );
    final matchRuoiTy = ruoiTyRegex.firstMatch(normalized);
    if (matchRuoiTy != null) {
      final base = double.tryParse(matchRuoiTy.group(1)!.replaceAll(',', '.')) ?? 0;
      final total = (base * 1000000000) + 500000000;
      return _AmountParseResult(
        amount: total,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchRuoiTy.group(0),
      );
    }

    // 2b. "nửa tỷ" / "half a billion"
    final nuaTyRegex = RegExp(
      r'(?:nửa|nủa|half a)\s*(?:tỷ|ty|billion)(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?',
      caseSensitive: false,
    );
    final matchNuaTy = nuaTyRegex.firstMatch(normalized);
    if (matchNuaTy != null) {
      return _AmountParseResult(
        amount: 500000000,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchNuaTy.group(0),
      );
    }

    // 2c. "X tỷ Y triệu" / "X tỷ Y"
    final tyLeRegex = RegExp(
      r'(\d+)\s*(?:tỷ|ty|billion)\s*(\d+)(?:\s*triệu|\s*tr|\s*million)?(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?',
      caseSensitive: false,
    );
    final matchTyLe = tyLeRegex.firstMatch(normalized);
    if (matchTyLe != null) {
      final billions = double.tryParse(matchTyLe.group(1)!) ?? 0;
      final subStr = matchTyLe.group(2)!;
      double sub = double.tryParse(subStr) ?? 0;
      if (sub > 0) {
        if (subStr.length == 1) {
          sub = sub * 100000000; // e.g. 1 tỷ 2 -> 1,200,000,000
        } else if (subStr.length == 2) {
          sub = sub * 10000000; // e.g. 1 tỷ 20 -> 1,020,000,000
        } else if (subStr.length == 3) {
          sub = sub * 1000000; // e.g. 1 tỷ 200 -> 1,200,000,000
        }
      }
      final total = (billions * 1000000000) + sub;
      return _AmountParseResult(
        amount: total,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchTyLe.group(0),
      );
    }

    // 2d. Decimal billions / "1.5 tỷ" / "100.5 billion"
    final tyDecimalRegex = RegExp(
      r'(\d+[,\.]\d+)\s*(?:tỷ|ty|billion|bil)(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?(?!\w)',
      caseSensitive: false,
    );
    final matchTyDec = tyDecimalRegex.firstMatch(normalized);
    if (matchTyDec != null) {
      final val = double.tryParse(matchTyDec.group(1)!.replaceAll(',', '.')) ?? 0;
      return _AmountParseResult(
        amount: val * 1000000000,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchTyDec.group(0),
      );
    }

    // 2e. Pure billions / "100 tỷ" / "500 tỷ" / "1 billion"
    final tyPureRegex = RegExp(
      r'(\d+)\s*(?:tỷ|ty|billion|bil)(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?(?!\w)',
      caseSensitive: false,
    );
    final matchTyPure = tyPureRegex.firstMatch(normalized);
    if (matchTyPure != null) {
      final val = double.tryParse(matchTyPure.group(1)!) ?? 0;
      return _AmountParseResult(
        amount: val * 1000000000,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchTyPure.group(0),
      );
    }

    // 3. Millions combinations
    // 3a. "X triệu rưỡi" / "X tr rưỡi"
    final ruoiTrieuRegex = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*(?:triệu|tr|million|mil|củ)\s*(?:rưỡi|and a half)(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?',
      caseSensitive: false,
    );
    final matchRuoiTrieu = ruoiTrieuRegex.firstMatch(normalized);
    if (matchRuoiTrieu != null) {
      final base = double.tryParse(matchRuoiTrieu.group(1)!.replaceAll(',', '.')) ?? 0;
      final total = (base * 1000000) + 500000;
      return _AmountParseResult(
        amount: total,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchRuoiTrieu.group(0),
      );
    }

    // 3b. "nửa triệu" / "half a million"
    final nuaTrieuRegex = RegExp(
      r'(?:nửa|nủa|half a)\s*(?:triệu|tr|million|mil)(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?',
      caseSensitive: false,
    );
    final matchNua = nuaTrieuRegex.firstMatch(normalized);
    if (matchNua != null) {
      return _AmountParseResult(
        amount: 500000,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchNua.group(0),
      );
    }

    // 3c. "X triệu Y trăm" / "X triệu Y" / "XtrY"
    final trieuLeRegex = RegExp(
      r'(\d+)\s*(?:triệu|tr|million|mil|củ)\s*(\d+)(?:\s*nghìn|\s*ngàn|\s*k|\s*thousand)?(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?',
      caseSensitive: false,
    );
    final matchTrieuLe = trieuLeRegex.firstMatch(normalized);
    if (matchTrieuLe != null) {
      final millions = double.tryParse(matchTrieuLe.group(1)!) ?? 0;
      final subStr = matchTrieuLe.group(2)!;
      double sub = double.tryParse(subStr) ?? 0;
      if (sub > 0) {
        if (subStr.length == 1) {
          sub = sub * 100000;
        } else if (subStr.length == 2) {
          sub = sub * 10000;
        } else if (subStr.length == 3) {
          sub = sub * 1000;
        }
      }
      final total = (millions * 1000000) + sub;
      return _AmountParseResult(
        amount: total,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchTrieuLe.group(0),
      );
    }

    // 3d. Decimal millions / "1.5 million"
    final trieuDecimalRegex = RegExp(
      r'(\d+[,\.]\d+)\s*(?:triệu|tr|million|mil|củ)(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?(?!\w)',
      caseSensitive: false,
    );
    final matchTrieuDec = trieuDecimalRegex.firstMatch(normalized);
    if (matchTrieuDec != null) {
      final val = double.tryParse(matchTrieuDec.group(1)!.replaceAll(',', '.')) ?? 0;
      return _AmountParseResult(
        amount: val * 1000000,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchTrieuDec.group(0),
      );
    }

    // 3e. Pure millions / "2 million"
    final trieuPureRegex = RegExp(
      r'(\d+)\s*(?:triệu|tr|million|mil|củ)(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?(?!\w)',
      caseSensitive: false,
    );
    final matchTrieuPure = trieuPureRegex.firstMatch(normalized);
    if (matchTrieuPure != null) {
      final val = double.tryParse(matchTrieuPure.group(1)!) ?? 0;
      return _AmountParseResult(
        amount: val * 1000000,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchTrieuPure.group(0),
      );
    }

    // 4. Thousands with 'k' / 'K' / 'cành' / 'lít': "45k", "45 K", "350k", "50 cành", "20 lít"
    final kRegex = RegExp(
      r'(\d+(?:[,\.]\d+)?)\s*(?:k|cành|lít)\b(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?',
      caseSensitive: false,
    );
    final matchK = kRegex.firstMatch(normalized);
    if (matchK != null) {
      final val = double.tryParse(matchK.group(1)!.replaceAll(',', '.')) ?? 0;
      return _AmountParseResult(
        amount: val * 1000,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchK.group(0),
      );
    }

    // 5. Thousands with 'nghìn' / 'ngàn' / 'thousand'
    final tramNghinRegex = RegExp(
      r'(\d+)\s*(?:trăm)\s*(?:nghìn|ngàn|k)?(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?(?!\w)',
      caseSensitive: false,
    );
    final matchTram = tramNghinRegex.firstMatch(normalized);
    if (matchTram != null && (normalized.contains('nghìn') || normalized.contains('ngàn'))) {
      final val = double.tryParse(matchTram.group(1)!) ?? 0;
      return _AmountParseResult(
        amount: val * 100000,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchTram.group(0),
      );
    }

    // 5b. "45 nghìn", "45 ngàn", "45 nghìn đồng", "45 ngàn đồng", "45 nghìn việt nam đồng"
    final nghinRegex = RegExp(
      r'(\d+(?:[,\.]\d+)?)\s*(?:nghìn|ngàn|thousand|nghin|ngan)(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?(?!\w)',
      caseSensitive: false,
    );
    final matchNghin = nghinRegex.firstMatch(normalized);
    if (matchNghin != null) {
      final numStr = matchNghin.group(1)!.replaceAll(',', '.');
      final val = double.tryParse(numStr) ?? 0;
      if (val >= 10000) {
        return _AmountParseResult(
          amount: val,
          currency: 'VND',
          hasAmount: true,
          matchedString: matchNghin.group(0),
        );
      }
      return _AmountParseResult(
        amount: val * 1000,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchNghin.group(0),
      );
    }

    // 6. Formatted numbers: "25.000 đồng", "25.000 ₫", "45.000", "45,000", "120.000", "45000đ", "45000 vnd", "50.000 vnđ"
    final formattedNumberRegex = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})+(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?)',
      caseSensitive: false,
    );
    final matchFormatted = formattedNumberRegex.firstMatch(normalized);
    if (matchFormatted != null) {
      final cleanNum = matchFormatted.group(1)!
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(RegExp(r'[^\d]'), '');
      final val = double.tryParse(cleanNum) ?? 0;
      if (val > 0) {
        return _AmountParseResult(
          amount: val,
          currency: 'VND',
          hasAmount: true,
          matchedString: matchFormatted.group(0),
        );
      }
    }

    // 7. Plain numbers >= 1000 up to hundreds of billions (14 digits): "90000đ", "90000 đồng", "90000"
    final plainNumberRegex = RegExp(
      r'(\d{4,14}(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|đ|₫|d))?)(?!\d)',
      caseSensitive: false,
    );
    final matchPlain = plainNumberRegex.firstMatch(normalized);
    if (matchPlain != null) {
      final cleanNum = matchPlain.group(1)!
          .replaceAll(RegExp(r'[^\d]'), '');
      final val = double.tryParse(cleanNum) ?? 0;
      if (val > 0) {
        return _AmountParseResult(
          amount: val,
          currency: 'VND',
          hasAmount: true,
          matchedString: matchPlain.group(0),
        );
      }
    }

    // 8. If default currency is USD and there's a standalone number, e.g. "Lunch 15" or "Spent 25 on shoes"
    if (defaultCurrency == 'USD') {
      final standaloneNum = RegExp(r'\b(\d+(?:\.\d{1,2})?)\b').firstMatch(normalized);
      if (standaloneNum != null) {
        final val = double.tryParse(standaloneNum.group(1)!) ?? 0;
        if (val > 0 && val < 5000) {
          return _AmountParseResult(
            amount: val,
            currency: 'USD',
            hasAmount: true,
            matchedString: standaloneNum.group(0),
          );
        }
      }
    }

    return _AmountParseResult(
      amount: 0,
      currency: defaultCurrency,
      hasAmount: false,
      matchedString: null,
    );
  }

  static double? _wordToDigit(String word) {
    switch (word.toLowerCase().trim()) {
      case '1':
      case 'một':
      case 'mốt':
        return 1;
      case '2':
      case 'hai':
      case 'hăm':
        return 2;
      case '3':
      case 'ba':
        return 3;
      case '4':
      case 'bốn':
      case 'tư':
        return 4;
      case '5':
      case 'năm':
      case 'lăm':
      case 'nhăm':
      case 'rưỡi':
        return 5;
      case '6':
      case 'sáu':
        return 6;
      case '7':
      case 'bảy':
      case 'bẩy':
        return 7;
      case '8':
      case 'tám':
        return 8;
      case '9':
      case 'chín':
        return 9;
      case '10':
      case 'mười':
      case 'chục':
        return 10;
      default:
        return double.tryParse(word);
    }
  }

  static double _parseWordNumber(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return 0;
    final numDirect = double.tryParse(t);
    if (numDirect != null) return numDirect;

    if (t.startsWith('mười')) {
      final sub = t.substring(4).trim();
      if (sub.isEmpty) return 10;
      return 10 + (_wordToDigit(sub) ?? 0);
    }
    if (t.contains('mươi')) {
      final parts = t.split('mươi');
      final tens = _wordToDigit(parts[0].trim()) ?? 0;
      final units = parts.length > 1 && parts[1].trim().isNotEmpty ? (_wordToDigit(parts[1].trim()) ?? 0) : 0;
      return (tens * 10) + units;
    }
    return _wordToDigit(t) ?? 0;
  }

  static _AmountParseResult? _parseVietnameseWordAmount(String text) {
    // 1. Billions in words (Trăm tỷ, chục tỷ, tỷ)
    // 1a. Billions + rưỡi (e.g. "1 tỷ rưỡi", "một tỷ rưỡi", "100 tỷ rưỡi")
    final pBillionsRuoi = RegExp(
      r'\b(một\s*trăm|hai\s*trăm|ba\s*trăm|bốn\s*trăm|năm\s*trăm|sáu\s*trăm|bảy\s*trăm|bẩy\s*trăm|tám\s*trăm|chín\s*trăm|mười|hai\s*mươi|ba\s*mươi|bốn\s*mươi|năm\s*mươi|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*tỷ\s+rưỡi(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mBRuoi = pBillionsRuoi.firstMatch(text);
    if (mBRuoi != null) {
      final bVal = _parseWordNumber(mBRuoi.group(1)!);
      final total = (bVal * 1000000000) + 500000000;
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mBRuoi.group(0));
    }

    // 1b. Billions + Millions (e.g. "100 tỷ 500 triệu", "1 tỷ 200 triệu", "một tỷ hai trăm triệu")
    final pBillionsMillions = RegExp(
      r'\b(một\s*trăm|hai\s*trăm|ba\s*trăm|bốn\s*trăm|năm\s*trăm|sáu\s*trăm|bảy\s*trăm|bẩy\s*trăm|tám\s*trăm|chín\s*trăm|mười|hai\s*mươi|ba\s*mươi|bốn\s*mươi|năm\s*mươi|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*tỷ\s+(\d+|một\s*trăm|hai\s*trăm|ba\s*trăm|bốn\s*trăm|năm\s*trăm|sáu\s*trăm|bảy\s*trăm|bẩy\s*trăm|tám\s*trăm|chín\s*trăm|mười|hai\s*mươi|ba\s*mươi|bốn\s*mươi|năm\s*mươi|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín)\s*(?:triệu|tr)(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mBMil = pBillionsMillions.firstMatch(text);
    if (mBMil != null) {
      final bVal = _parseWordNumber(mBMil.group(1)!);
      final mVal = _parseWordNumber(mBMil.group(2)!);
      final total = (bVal * 1000000000) + (mVal * 1000000);
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mBMil.group(0));
    }

    final billionWordPatterns = <RegExp, double>{
      RegExp(r'\b(một|1)\s*trăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 100000000000,
      RegExp(r'\b(hai|2)\s*trăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 200000000000,
      RegExp(r'\b(ba|3)\s*trăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 300000000000,
      RegExp(r'\b(bốn|4)\s*trăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 400000000000,
      RegExp(r'\b(năm|5)\s*trăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 500000000000,
      RegExp(r'\b(sáu|6)\s*trăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 600000000000,
      RegExp(r'\b(bảy|7)\s*trăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 700000000000,
      RegExp(r'\b(tám|8)\s*trăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 800000000000,
      RegExp(r'\b(chín|9)\s*trăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 900000000000,
      RegExp(r'\btrăm\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 100000000000,
      RegExp(r'\b(mười|10)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 10000000000,
      RegExp(r'\b(hai|2)\s*mươi\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 20000000000,
      RegExp(r'\b(ba|3)\s*mươi\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 30000000000,
      RegExp(r'\b(bốn|4)\s*mươi\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 40000000000,
      RegExp(r'\b(năm|5)\s*mươi\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 50000000000,
      RegExp(r'\b(sáu|6)\s*mươi\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 60000000000,
      RegExp(r'\b(bảy|7)\s*mươi\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 70000000000,
      RegExp(r'\b(tám|8)\s*mươi\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 80000000000,
      RegExp(r'\b(chín|9)\s*mươi\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 90000000000,
      RegExp(r'\b(một|1)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 1000000000,
      RegExp(r'\b(hai|2)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 2000000000,
      RegExp(r'\b(ba|3)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 3000000000,
      RegExp(r'\b(bốn|4)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 4000000000,
      RegExp(r'\b(năm|5)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 5000000000,
      RegExp(r'\b(sáu|6)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 6000000000,
      RegExp(r'\b(bảy|7)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 7000000000,
      RegExp(r'\b(tám|8)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 8000000000,
      RegExp(r'\b(chín|9)\s*tỷ(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])'): 9000000000,
    };
    for (final entry in billionWordPatterns.entries) {
      final match = entry.key.firstMatch(text);
      if (match != null) {
        return _AmountParseResult(
          amount: entry.value,
          currency: 'VND',
          hasAmount: true,
          matchedString: match.group(0),
        );
      }
    }

    // 2. Composite Millions + Sub-thousands
    // Pattern A1: Millions + Hundreds + Tens + Units (e.g. "ba triệu năm trăm năm mươi nghìn", "hai triệu ba trăm bốn lăm nghìn", "3 triệu 5 trăm 50 nghìn")
    final pMillionsFull = RegExp(
      r'\b(mười(?:\s*(?:một|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|hai\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|ba\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|bốn\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|năm\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*(?:triệu|tr|củ)\s+(một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*trăm\s+(một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|hăm|\d+)\s*(?:mươi|chục|lăm|nhăm)?(?:\s+(mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín|\d+))?(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mA = pMillionsFull.firstMatch(text);
    if (mA != null) {
      final mVal = _parseWordNumber(mA.group(1)!);
      final hVal = _wordToDigit(mA.group(2)!) ?? 0;
      final tensWord = mA.group(3)!;
      double tensVal = 0;
      if (tensWord == 'hăm') {
        tensVal = 20;
      } else if (tensWord == 'mười') {
        tensVal = 10;
      } else {
        final d = _wordToDigit(tensWord) ?? 0;
        tensVal = d >= 10 ? d : d * 10;
      }
      final uVal = mA.group(4) != null ? (_wordToDigit(mA.group(4)!) ?? 0) : (mA.group(0)!.contains('lăm') || mA.group(0)!.contains('nhăm') ? 5 : 0);
      final total = (mVal * 1000000) + (hVal * 100000) + (tensVal * 1000) + (uVal * 1000);
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mA.group(0));
    }

    // Pattern A2: Millions + Hundreds + Lẻ/Linh + Units (e.g. "ba triệu năm trăm lẻ năm nghìn", "3 triệu 5 trăm linh tám nghìn")
    final pMillionsHundredsLe = RegExp(
      r'\b(mười(?:\s*(?:một|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|hai\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|ba\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|bốn\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|năm\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*(?:triệu|tr|củ)\s+(một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*trăm\s+(?:lẻ|linh)\s+(một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mALe = pMillionsHundredsLe.firstMatch(text);
    if (mALe != null) {
      final mVal = _parseWordNumber(mALe.group(1)!);
      final hVal = _wordToDigit(mALe.group(2)!) ?? 0;
      final uVal = _wordToDigit(mALe.group(3)!) ?? 0;
      final total = (mVal * 1000000) + (hVal * 100000) + (uVal * 1000);
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mALe.group(0));
    }

    // Pattern B1: Millions + không trăm (hoặc 0 trăm) + Tens + Units (e.g. "hai triệu không trăm tám chục nghìn", "2 triệu không trăm tám chục ngàn", "2 triệu 0 trăm 80 ngàn")
    final pMillionsKhongTram = RegExp(
      r'\b(mười(?:\s*(?:một|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|hai\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|ba\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|bốn\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|năm\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*(?:triệu|tr|củ)\s+(?:không|0)\s*trăm\s+(một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|hăm|\d+)\s*(?:mươi|chục|lăm|nhăm)?(?:\s+(mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín|\d+))?(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mB = pMillionsKhongTram.firstMatch(text);
    if (mB != null) {
      final mVal = _parseWordNumber(mB.group(1)!);
      final tensWord = mB.group(2)!;
      double tensVal = 0;
      if (tensWord == 'hăm') {
        tensVal = 20;
      } else if (tensWord == 'mười') {
        tensVal = 10;
      } else {
        final d = _wordToDigit(tensWord) ?? 0;
        tensVal = d >= 10 ? d : d * 10;
      }
      final uVal = mB.group(3) != null ? (_wordToDigit(mB.group(3)!) ?? 0) : (mB.group(0)!.contains('lăm') || mB.group(0)!.contains('nhăm') ? 5 : 0);
      final total = (mVal * 1000000) + (tensVal * 1000) + (uVal * 1000);
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mB.group(0));
    }

    // Pattern B2: Millions + không trăm + (lẻ|linh) + Units (e.g. "hai triệu không trăm lẻ tám nghìn", "2 triệu không trăm linh năm nghìn")
    final pMillionsKhongTramLe = RegExp(
      r'\b(mười(?:\s*(?:một|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|hai\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|ba\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|bốn\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|năm\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*(?:triệu|tr|củ)\s+(?:không|0)\s*trăm\s+(?:lẻ|linh)\s+(một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mBLe = pMillionsKhongTramLe.firstMatch(text);
    if (mBLe != null) {
      final mVal = _parseWordNumber(mBLe.group(1)!);
      final uVal = _wordToDigit(mBLe.group(2)!) ?? 0;
      final total = (mVal * 1000000) + (uVal * 1000);
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mBLe.group(0));
    }

    // Pattern C: Millions + Hundreds (e.g. "một triệu hai trăm nghìn", "ba triệu năm trăm", "một triệu hai trăm rưỡi", "2 triệu 5 trăm")
    final pMillionsHundreds = RegExp(
      r'\b(mười(?:\s*(?:một|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|hai\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|ba\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|bốn\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|năm\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*(?:triệu|tr|củ)\s+(một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*trăm(?:\s+(rưỡi))?(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mC = pMillionsHundreds.firstMatch(text);
    if (mC != null) {
      final mVal = _parseWordNumber(mC.group(1)!);
      final hVal = _wordToDigit(mC.group(2)!) ?? 0;
      final ruoiVal = mC.group(3) != null ? 50000 : 0;
      final total = (mVal * 1000000) + (hVal * 100000) + ruoiVal;
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mC.group(0));
    }

    // Pattern D: Millions + rưỡi (e.g. "hai triệu rưỡi", "3 tr rưỡi")
    final pMillionsRuoi = RegExp(
      r'\b(mười(?:\s*(?:một|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|hai\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|ba\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|bốn\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|năm\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*(?:triệu|tr|củ)\s+rưỡi(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mD = pMillionsRuoi.firstMatch(text);
    if (mD != null) {
      final mVal = _parseWordNumber(mD.group(1)!);
      final total = (mVal * 1000000) + 500000;
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mD.group(0));
    }

    // Pattern E: Millions + \d{1,3}k / nghìn (e.g. "2 triệu 200k", "1 triệu 50k", "2 triệu 80 nghìn", "2 triệu 200 nghìn")
    final pMillionsDigitK = RegExp(
      r'\b(mười(?:\s*(?:một|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|hai\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|ba\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|bốn\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|năm\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*(?:triệu|tr|củ)\s+(\d{1,3})\s*(?:nghìn|ngàn|k)?(?:\s*(?:đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mE = pMillionsDigitK.firstMatch(text);
    if (mE != null) {
      final mVal = _parseWordNumber(mE.group(1)!);
      final subStr = mE.group(2)!;
      double kVal = double.tryParse(subStr) ?? 0;
      if (kVal > 0) {
        if (subStr.length == 1) {
          kVal = kVal * 100; // e.g. "2 triệu 8" -> 2.800.000 (handled also in F, but if matched here)
        } else if (subStr.length == 2 && kVal < 100 && !mE.group(0)!.contains('k') && !mE.group(0)!.contains('nghìn') && !mE.group(0)!.contains('ngàn')) {
          kVal = kVal * 10; // e.g. "2 triệu 80" -> 2.800.000 vs "2 triệu 80k" -> 2.080.000
        }
      }
      final total = (mVal * 1000000) + (kVal * 1000);
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mE.group(0));
    }

    // Pattern F: Millions + single digit/word (e.g. "một triệu hai", "hai triệu tám", "2 triệu 8")
    final pMillionsSingle = RegExp(
      r'\b(mười(?:\s*(?:một|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|hai\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|ba\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|bốn\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|năm\s*mươi(?:\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín))?|một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|\d+)\s*(?:triệu|tr|củ)\s+(hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|1|2|3|4|5|6|7|8|9)\b(?:\s*(?:đồng|đ|₫|d|vnd|vnđ))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final mF = pMillionsSingle.firstMatch(text);
    if (mF != null) {
      final mVal = _parseWordNumber(mF.group(1)!);
      final subD = _wordToDigit(mF.group(2)!) ?? 0;
      final total = (mVal * 1000000) + (subD * 100000);
      return _AmountParseResult(amount: total, currency: 'VND', hasAmount: true, matchedString: mF.group(0));
    }

    // 3. Single Millions in words (Trăm triệu, chục triệu, triệu)
    final millionWordPatterns = <RegExp, double>{
      RegExp(r'\b(một|1)\s*trăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 100000000,
      RegExp(r'\b(hai|2)\s*trăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 200000000,
      RegExp(r'\b(ba|3)\s*trăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 300000000,
      RegExp(r'\b(bốn|4)\s*trăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 400000000,
      RegExp(r'\b(năm|5)\s*trăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 500000000,
      RegExp(r'\b(sáu|6)\s*trăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 600000000,
      RegExp(r'\b(bảy|7)\s*trăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 700000000,
      RegExp(r'\b(tám|8)\s*trăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 800000000,
      RegExp(r'\b(chín|9)\s*trăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 900000000,
      RegExp(r'\btrăm\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 100000000,
      RegExp(r'\b(một|1)\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 1000000,
      RegExp(r'\b(hai|2)\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 2000000,
      RegExp(r'\b(ba|3)\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 3000000,
      RegExp(r'\b(bốn|4)\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 4000000,
      RegExp(r'\b(năm|5)\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 5000000,
      RegExp(r'\b(sáu|6)\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 6000000,
      RegExp(r'\b(bảy|7)\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 7000000,
      RegExp(r'\b(tám|8)\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 8000000,
      RegExp(r'\b(chín|9)\s*(?:triệu|tr(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))'): 9000000,
    };
    for (final entry in millionWordPatterns.entries) {
      final match = entry.key.firstMatch(text);
      if (match != null) {
        return _AmountParseResult(
          amount: entry.value,
          currency: 'VND',
          hasAmount: true,
          matchedString: match.group(0),
        );
      }
    }

    // 3. Composite Hundreds with "mươi": e.g. "một trăm hai mươi lăm nghìn" = 125,000; "hai trăm ba mươi nghìn" = 230,000
    final compositeHundredFullRegex = RegExp(
      r'\b(một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|1|2|3|4|5|6|7|8|9)?\s*trăm\s*(hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|1|2|3|4|5|6|7|8|9)\s*(?:mươi|chục)\s*(mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín|1|2|3|4|5|6|7|8|9)?(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final matchHundredFull = compositeHundredFullRegex.firstMatch(text);
    if (matchHundredFull != null) {
      final hundredDigit = _wordToDigit(matchHundredFull.group(1) ?? '1') ?? 1;
      final tensDigit = _wordToDigit(matchHundredFull.group(2) ?? '0') ?? 0;
      final unitDigit = matchHundredFull.group(3) != null ? (_wordToDigit(matchHundredFull.group(3)!) ?? 0) : 0;
      final total = (hundredDigit * 100000) + (tensDigit * 10000) + (unitDigit * 1000);
      return _AmountParseResult(
        amount: total,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchHundredFull.group(0),
      );
    }

    // 4. Colloquial Composite Hundreds: e.g. "một trăm tám nghìn" = 180,000; "một trăm hai nghìn" = 120,000; "một trăm rưỡi" = 150,000; "trăm tám" = 180,000; "hai trăm rưỡi" = 250,000; "trăm rưỡi" = 150,000
    final compositeHundredColloquialRegex = RegExp(
      r'\b(?:(một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|1|2|3|4|5|6|7|8|9)\s*)?trăm\s*(mốt|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|rưỡi|1|2|3|4|5|6|7|8|9)(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final matchHundredColloquial = compositeHundredColloquialRegex.firstMatch(text);
    if (matchHundredColloquial != null) {
      final hundredDigit = _wordToDigit(matchHundredColloquial.group(1) ?? '1') ?? 1;
      final subWord = matchHundredColloquial.group(2)!;
      double subValue = 0;
      if (subWord == 'rưỡi') {
        subValue = 50000;
      } else {
        final d = _wordToDigit(subWord) ?? 0;
        subValue = d * 10000; // e.g. "trăm tám" = 100,000 + 80,000 = 180,000
      }
      final total = (hundredDigit * 100000) + subValue;
      return _AmountParseResult(
        amount: total,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchHundredColloquial.group(0),
      );
    }

    // 5. Colloquial tens with lăm/nhăm: e.g. "ba lăm nghìn" = 35,000; "hăm lăm nghìn" = 25,000; "bốn lăm k" = 45,000; "năm lăm nghìn" = 55,000; "mười lăm nghìn" = 15,000
    final lamNhamRegex = RegExp(
      r'\b(?:(mười|hai|ba|bốn|năm|sáu|bảy|bẩy|tám|chín|hăm|1|2|3|4|5|6|7|8|9)\s*(?:mươi\s*)?)?(lăm|nhăm)(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final matchLam = lamNhamRegex.firstMatch(text);
    if (matchLam != null) {
      final tensWord = matchLam.group(1);
      final double tensDigit = tensWord != null ? (_wordToDigit(tensWord) ?? 0) : 0;
      final double total = (tensDigit * 10000) + 5000;
      return _AmountParseResult(
        amount: total,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchLam.group(0),
      );
    }

    // 6. Tens with chục/mươi: e.g. "hai chục" = 20,000; "ba chục nghìn" = 30,000; "năm chục" = 50,000; "hăm nghìn" = 20,000
    final chucRegex = RegExp(
      r'\b(một|hai|ba|bốn|năm|sáu|bảy|bẩy|tám|chín|hăm|1|2|3|4|5|6|7|8|9)\s*(?:chục|mươi|mươi nghìn|chục nghìn|chục k)(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final matchChuc = chucRegex.firstMatch(text);
    if (matchChuc != null) {
      final double tensDigit = _wordToDigit(matchChuc.group(1)!) ?? 0;
      final double total = tensDigit * 10000;
      return _AmountParseResult(
        amount: total,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchChuc.group(0),
      );
    }

    // 7. Pure hundreds in words: e.g. "một trăm nghìn" = 100,000; "hai trăm nghìn" = 200,000; "năm trăm k" = 500,000
    final pureHundredRegex = RegExp(
      r'\b(một|hai|ba|bốn|năm|sáu|bảy|bẩy|tám|chín|1|2|3|4|5|6|7|8|9)\s*trăm(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|d))?(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9])',
      caseSensitive: false,
    );
    final matchPureHundred = pureHundredRegex.firstMatch(text);
    if (matchPureHundred != null) {
      final double hundredDigit = _wordToDigit(matchPureHundred.group(1)!) ?? 0;
      final double total = hundredDigit * 100000;
      return _AmountParseResult(
        amount: total,
        currency: 'VND',
        hasAmount: true,
        matchedString: matchPureHundred.group(0),
      );
    }

    return null;
  }

  static final RegExp _nonWordRegExp = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  static _CategoryClassification _classifyCategory(String text) {
    final String cleanText = text.replaceAll(_nonWordRegExp, ' ').toLowerCase().trim();
    final String paddedText = ' $cleanText ';
    final Set<String> tokensSet = cleanText.isEmpty ? <String>{} : Set<String>.from(cleanText.split(' '));

    // 1. Quỹ nhóm (group_fund)
    final groupFundKeywords = [
      'quỹ nhóm', 'nạp quỹ', 'tiền quỹ', 'đóng quỹ', 'quỹ chung',
      'nạp quỹ nhóm', 'đóng quỹ nhóm', 'góp quỹ', 'góp quỹ nhóm',
      'quỹ phòng', 'quỹ lớp', 'quỹ hội', 'quỹ cty', 'quỹ công ty', 'quỹ sinh hoạt',
      'group fund', 'fund deposit', 'deposit to fund', 'team fund', 'class fund',
      'fund contribution', 'group contribution', 'club fund', 'room fund',
    ];
    final int groupFundScore = _keywordScore(paddedText, tokensSet, groupFundKeywords);
    if (groupFundScore > 0) {
      return _CategoryClassification(
        category: 'Quỹ nhóm',
        type: 'expense',
        hasCategory: true,
        matchCount: groupFundScore,
      );
    }

    // 2. Lương (salary) -> income (Vietnamese + English)
    final salaryKeywords = [
      'lương', 'tiền lương', 'trả lương', 'lương về', 'nhận lương', 'lãnh lương', 'gửi lương',
      'lương cơ bản', 'lương net', 'lương gross', 'lương thực nhận', 'lương cứng', 'lương tháng',
      'tiền công', 'tiền làm thêm', 'tiền tăng ca', 'tăng ca', 'làm thêm giờ', 'tiền ot', 'ot',
      'bảng lương', 'phiếu lương', 'kỳ lương',
      'tiền thưởng', 'thưởng tết', 'thưởng kpi', 'thưởng hiệu suất', 'thưởng nóng', 'thưởng tháng', 'thưởng quý', 'thưởng năm', 'thưởng dự án',
      'tháng 13', 'lương tháng 13',
      'phụ cấp', 'trợ cấp', 'phụ cấp ăn trưa', 'phụ cấp xăng xe', 'phụ cấp đi lại', 'phụ cấp điện thoại', 'phụ cấp nhà ở',
      'hoa hồng', 'tiền hoa hồng', 'tiền boa', 'tiền tip', 'thu nhập', 'doanh thu', 'tiền lãi', 'cổ tức',
      'salary', 'paycheck', 'pay day', 'payday', 'wage', 'wages', 'income', 'earnings',
      'got paid', 'getting paid', 'paid salary', 'monthly salary', 'base salary', 'net salary', 'gross salary',
      'payroll', 'compensation', 'stipend', 'allowance', 'overtime pay', 'overtime', 'freelance income', 'side income', 'commission',
      'annual bonus', 'performance bonus', 'year-end bonus', 'holiday bonus', '13th salary', 'dividend', 'profit'
    ];
    final int salaryScore = _keywordScore(paddedText, tokensSet, salaryKeywords);
    if (salaryScore > 0) {
      return _CategoryClassification(
        category: 'Lương',
        type: 'income',
        hasCategory: true,
        matchCount: salaryScore,
      );
    }

    // 3. Quà tặng (gift)
    final giftKeywords = [
      'quà', 'quà tặng', 'mua quà', 'tặng quà', 'đặt quà', 'gửi quà', 'biếu quà', 'biếu', 'phần quà',
      'sinh nhật', 'quà sinh nhật', 'tặng sinh nhật', 'mừng sinh nhật', 'tiền sinh nhật',
      'mừng cưới', 'đám cưới', 'quà cưới', 'mừng ngày cưới', 'tiền mừng cưới', 'thiệp cưới', 'phong bì cưới',
      'kỷ niệm', 'quà kỷ niệm', 'anniversary gift', 'lì xì', 'mừng tuổi', 'tiền lì xì', 'lì xì tết', 'chúc tết', 'phong bao lì xì', 'tiền mừng', 'mừng thọ', 'quà mừng thọ',
      'quà tân gia', 'tân gia', 'mừng tân gia', 'quà khai trương', 'khai trương', 'mừng khai trương', 'quà tốt nghiệp', 'tốt nghiệp', 'mừng tốt nghiệp',
      'quà valentine', 'valentine', 'quà 8/3', 'quà 20/10', 'quà 14/2', 'quà giáng sinh', 'noel', 'quà noel', 'quà trung thu', 'quà tết',
      'từ thiện', 'ủng hộ từ thiện', 'quyên góp', 'donate', 'donation', 'charity', 'tiền từ thiện', 'tiền ủng hộ', 'tiền quyên góp', 'cứu trợ',
      'gift', 'gifts', 'present', 'presents', 'birthday gift', 'wedding gift', 'anniversary gift', 'graduation gift',
      'housewarming', 'housewarming gift', 'lucky money', 'red envelope', 'red packet',
      'gift for mom', 'gift for dad', 'gift for friend', 'gift for girlfriend', 'gift for boyfriend', 'gift for wife', 'gift for husband',
      'valentine gift', 'christmas gift', 'holiday gift', 'donations', 'fundraiser', 'được cho', 'cho', 'gửi', 'gửi cho'
    ];
    final int giftScore = _keywordScore(paddedText, tokensSet, giftKeywords);

    // 4. Giáo dục / Học tập (education)
    final educationKeywords = [
      'học phí', 'tiền học', 'đóng học phí', 'đóng học', 'nộp học phí', 'học phí kỳ', 'học phí học kỳ', 'tiền trường', 'đóng tiền học',
      'lệ phí', 'lệ phí thi', 'lệ phí đăng ký', 'đại học', 'cao đẳng', 'trường học', 'campus',
      'đăng ký tín chỉ', 'đk tín', 'đk tín chỉ', 'đăng ký học', 'đăng ký môn', 'đăng ký môn học',
      'tín chỉ', 'học phần', 'môn học', 'học lại', 'thi lại', 'học cải thiện', 'cải thiện điểm',
      'khóa học', 'khoá học', 'khóa đào tạo', 'lớp học', 'học thêm', 'tiền học thêm', 'tiền gia sư', 'gia sư',
      'dạy thêm', 'học tiếng', 'học ngoại ngữ', 'lớp luyện thi', 'luyện thi', 'ôn thi', 'đào tạo', 'đào tạo nghề',
      'ielts', 'toeic', 'toefl', 'sat', 'hsk', 'topik', 'jlpt', 'tiếng anh',
      'tiếng trung', 'tiếng nhật', 'tiếng hàn', 'ngoại ngữ',
      'sách', 'sách giáo khoa', 'sách tham khảo', 'giáo trình', 'tài liệu học',
      'tài liệu học tập', 'tài liệu ôn thi', 'đề thi', 'đề cương', 'vở', 'vở viết', 'vở bài tập',
      'dụng cụ học tập', 'đồ dùng học tập',
      'thi cử', 'kỳ thi', 'kỳ thi cuối kỳ', 'thi giữa kỳ', 'thi cuối kỳ',
      'đăng ký thi', 'chứng chỉ', 'chứng nhận', 'certificate', 'certification',
      'học lái xe', 'bằng lái', 'thi bằng lái', 'bằng lái xe', 'trung tâm đào tạo', 'học nghề',
      'coursera', 'udemy', 'duolingo', 'edx', 'skillshare', 'khan academy',
      'online course', 'online learning', 'e-learning',
      'tuition', 'tuition fee', 'school fee', 'college tuition', 'university tuition', 'course',
      'courses', 'course fee', 'class', 'classes', 'study', 'studying', 'education', 'learning',
      'textbook', 'textbooks', 'study materials', 'tutor', 'tutoring',
      'exam', 'examination', 'test fee', 'exam fee', 'lesson', 'lecture', 'semester',
      'credit', 'credits', 'enrollment', 'enrolment', 'stationery', 'school supplies', 'notebook'
    ];
    final int educationScore = _keywordScore(paddedText, tokensSet, educationKeywords);

    // 5. Giải trí (entertainment)
    final entertainmentKeywords = [
      'xem phim', 'vé xem phim', 'vé phim', 'rạp phim', 'rạp chiếu phim', 'cgv', 'lotte cinema', 'galaxy cinema', 'bhd cinema', 'cinema',
      'netflix', 'spotify', 'youtube premium', 'disney+', 'disney plus', 'fpt play', 'vieon', 'k+', 'hbo max', 'galaxy play', 'apple music', 'zing mp3', 'soundcloud',
      'box office', 'thuê phim', 'streaming', 'gói xem phim', 'gói nghe nhạc',
      'movie', 'movies', 'film ticket', 'movie ticket', 'theater',
      'karaoke', 'hát karaoke', 'quán karaoke', 'phòng karaoke', 'quán hát',
      'concert', 'vé ca nhạc', 'vé concert', 'show âm nhạc', 'liveshow', 'festival', 'live music', 'concert ticket', 'music show',
      'game', 'gaming', 'nạp game', 'chơi game', 'mua game', 'thẻ game', 'nạp thẻ game', 'nạp thẻ',
      'steam', 'playstation', 'ps5', 'ps4', 'xbox', 'nintendo', 'nintendo switch', 'switch',
      'riot', 'garena', 'vng', 'genshin', 'pubg', 'free fire', 'liên quân', 'valorant', 'minecraft', 'roblox',
      'battle pass', 'skin game', 'gamepass', 'game pass', 'in-game', 'in game', 'top up game',
      'bowling', 'bida', 'billiards', 'bi-a', 'pool', 'arcade', 'game center',
      'khu vui chơi', 'khu giải trí', 'trò chơi', 'escape room', 'phòng escape', 'board game', 'boardgame', 'quán board game', 'gắp thú',
      'paintball', 'bắn súng sơn', 'trượt patin', 'roller skating', 'trượt băng', 'ice skating',
      'climbing', 'leo núi trong nhà', 'đua xe', 'go-kart', 'karting',
      'water park', 'công viên nước', 'amusement park', 'theme park',
      'bar', 'pub', 'club', 'quán bar', 'nightclub', 'lounge', 'beer club', 'rooftop bar', 'vũ trường',
      'party', 'tiệc tùng', 'đi quẩy', 'quẩy', 'đi club', 'đi bar', 'đi pub',
      'vé tham quan', 'tham quan', 'công viên', 'công viên giải trí', 'vinwonders', 'sun world', 'bà nà hills', 'vinpearl',
      'thảo cầm viên', 'sở thú', 'zoo', 'aquarium', 'thủy cung',
      'bảo tàng', 'museum', 'triển lãm', 'exhibition', 'khu du lịch', 'vé vào cửa', 'vé vào cổng', 'vé vui chơi'
    ];
    final int entertainmentScore = _keywordScore(paddedText, tokensSet, entertainmentKeywords);

    // 6. Di chuyển / Đi lại (transport)
    final transportKeywords = [
      'xăng', 'đổ xăng', 'tiền xăng', 'nạp xăng', 'trạm xăng', 'cây xăng', 'xăng xe',
      'dầu diesel', 'nhiên liệu', 'gas', 'gasoline', 'petrol', 'fuel', 'diesel', 'refuel', 'gas station',
      'grab', 'grabcar', 'grabbike', 'grab bike', 'grab car', 'gojek', 'be', 'be bike', 'be car', 'bebike', 'becar',
      'xanh sm', 'uber', 'taxi', 'xe ôm', 'xe ôm công nghệ', 'xe công nghệ', 'đặt xe', 'cuốc xe', 'tiền xe', 'ride', 'cab', 'rideshare', 'taxi fare', 'cab fare',
      'xe bus', 'xe buýt', 'vé bus', 'vé xe bus', 'vé xe buýt', 'bus', 'bus ticket', 'bus fare',
      'xe khách', 'nhà xe', 'vé xe khách', 'vé tàu', 'tàu hỏa', 'train', 'train ticket', 'railway',
      'vé máy bay', 'máy bay', 'flight', 'airplane', 'plane ticket', 'flight ticket', 'airport', 'airline ticket',
      'subway', 'metro', 'tàu điện', 'vé metro', 'subway ticket',
      'gửi xe', 'tiền gửi xe', 'phí gửi xe', 'vé gửi xe', 'phí đỗ xe', 'tiền đỗ xe', 'đỗ xe', 'bãi đỗ xe', 'bãi giữ xe', 'parking', 'parking fee', 'parking ticket',
      'vá xe', 'sửa xe', 'tiền sửa xe', 'rửa xe', 'tiền rửa xe', 'car wash', 'thay nhớt', 'thay dầu', 'oil change',
      'bảo dưỡng xe', 'bảo trì xe', 'sửa xe máy', 'sửa ô tô', 'car maintenance', 'car repair', 'bike repair',
      'thay lốp', 'thay vỏ xe', 'thay vỏ', 'lốp xe', 'vỏ xe', 'ắc quy', 'bình xe', 'tire change', 'flat tire',
      'cầu đường', 'phí cầu đường', 'bot', 'trạm thu phí', 'phí đường', 'phí cao tốc', 'cao tốc', 'toll', 'toll fee', 'road toll', 'highway toll', 'phí etc', 'nạp etc',
      'đi lại', 'đi xe', 'di chuyển', 'phương tiện', 'transport', 'transportation', 'commute', 'commuting'
    ];
    final int transportScore = _keywordScore(paddedText, tokensSet, transportKeywords);

    // 7. Ăn uống (food)
    final foodKeywords = [
      'ăn', 'uống', 'đi ăn', 'đi uống', 'mua đồ ăn', 'đặt đồ ăn', 'ship đồ ăn', 'gọi đồ ăn', 'tiền ăn', 'bữa ăn', 'tiền cơm', 'ăn ngoài',
      'ăn sáng', 'bữa sáng', 'điểm tâm', 'ăn trưa', 'bữa trưa', 'cơm trưa', 'ăn tối', 'bữa tối', 'cơm tối', 'ăn đêm', 'ăn khuya', 'ăn vặt', 'đồ ăn vặt',
      'phở', 'bún', 'bún bò', 'bún chả', 'bún đậu', 'bún riêu', 'bún thịt nướng', 'bún mắm', 'bún chả cá', 'bánh canh', 'hủ tiếu', 'miến',
      'mì', 'mì tôm', 'mì gói', 'mì quảng', 'mì cay', 'mì ý', 'mì xào', 'nui', 'hải sản', 'ốc', 'quán ốc', 'thịt', 'gà', 'gà rán', 'nem', 'chả',
      'cơm', 'cơm tấm', 'cơm gà', 'cơm rang', 'cơm chiên', 'cơm bình dân', 'cơm niêu', 'cơm sườn', 'cơm hộp',
      'cháo', 'cháo lòng', 'cháo gà', 'cháo vịt', 'cháo sườn', 'xôi', 'xôi gà', 'xôi xéo',
      'bánh mì', 'bánh mì thịt', 'bánh mì chảo', 'bánh bao', 'bánh cuốn', 'bánh ướt', 'bánh xèo', 'bánh khọt', 'bánh tráng', 'bánh tráng trộn', 'bánh tráng nướng',
      'lẩu', 'nướng', 'bbq', 'nhậu', 'tiệc nhậu', 'quán nhậu', 'lẩu thái', 'lẩu bò', 'lẩu gà', 'lẩu dê', 'thịt nướng',
      'trái cây', 'hoa quả', 'đồ ăn', 'thức ăn',
      'trà sữa', 'cà phê', 'cafe', 'cf', 'bạc xỉu', 'cà phê sữa', 'espresso', 'cappuccino', 'latte',
      'nước ngọt', 'nước ép', 'sinh tố', 'trà', 'trà đào', 'trà tắc', 'trà chanh', 'nước mía', 'nước dừa', 'cacao', 'matcha',
      'bia', 'rượu', 'cocktail', 'đồ uống', 'thức uống',
      'coffee', 'tea', 'milk tea', 'boba', 'drink', 'drinks', 'juice', 'smoothie', 'soda', 'beer', 'wine', 'beverage', 'soft drink',
      'pizza', 'burger', 'hamburger', 'sandwich', 'taco', 'burrito', 'pasta', 'steak', 'salad', 'soup', 'noodle', 'noodles', 'ramen', 'sushi', 'sashimi', 'tempura', 'udon', 'tokbokki', 'kimbap', 'fried chicken', 'hot dog', 'fries', 'fast food',
      'snack', 'snacks', 'bánh kẹo', 'kẹo', 'chocolate', 'socola', 'kem', 'chè', 'chè thái', 'sữa chua', 'pudding', 'donut', 'cookie', 'cookies', 'cake', 'dessert', 'ice cream', 'sweet', 'bakery',
      'breakfast', 'lunch', 'dinner', 'brunch', 'supper', 'meal', 'meals', 'dining', 'dine out', 'eating', 'ate', 'eat', 'food',
      'nhà hàng', 'quán ăn', 'quán cơm', 'quán phở', 'quán bún', 'quán cafe', 'quán cà phê', 'quán nước', 'quán ăn vặt', 'restaurant', 'coffee shop', 'food court', 'food delivery',
      'grabfood', 'shopeefood', 'befood', 'baemin', 'cà phê',
      'starbucks', 'highlands', 'phúc long', 'the coffee house', 'gong cha', 'toco toco', 'mixue', 'kfc', 'lotteria', 'jollibee', 'mcdonalds', 'mcdonald', 'burger king', 'five guys', 'pizza hut', 'dominos', 'subway'
    ];
    final int foodScore = _keywordScore(paddedText, tokensSet, foodKeywords);

    // 8. Mua sắm (shopping)
    final shoppingKeywords = [
      'mua sắm', 'đi shopping', 'mua đồ','shopping', 'đặt hàng', 'mua hàng', 'đơn hàng', 'đơn mua hàng', 'mua', 'bought', 'buy', 'purchase', 'purchased', 'ordered',
      'shopee', 'lazada', 'tiki', 'tiktok shop', 'sendo', 'amazon', 'aliexpress', 'siêu thị', 'đi chợ', 'bách hóa xanh', 'winmart', 'coopmart', 'big c', 'aeon mall', 'tạp hóa', 'mall', 'supermarket', 'convenience store', 'store', 'grocery', 'groceries',
      'quần áo', 'áo', 'áo thun', 'áo phông', 'áo sơ mi', 'áo khoác', 'áo len', 'áo hoodie', 'áo polo', 'quần', 'quần jean', 'quần jeans', 'quần tây', 'quần đùi', 'quần short', 'váy', 'đầm', 'chân váy', 'đồ ngủ', 'đồ lót', 'hoodie', 'jacket',
      'giày', 'dép', 'sandal', 'sandals', 'sneakers', 'sneaker', 'giày thể thao', 'giày cao gót', 'ủng', 'tất', 'vớ', 'boots', 'slippers', 'socks',
      'túi', 'túi xách', 'ba lô', 'balo', 'ví', 'ví tiền', 'bóp', 'thắt lưng', 'dây nịt', 'mũ', 'nón', 'kính', 'kính mắt', 'mắt kính', 'kính mát', 'kính râm', 'phụ kiện thời trang',
      'trang sức', 'khuyên tai', 'nhẫn', 'vòng tay', 'dây chuyền', 'đồng hồ', 'đồng hồ đeo tay', 'smartwatch', 'đồng hồ thông minh',
      'clothes', 'clothing', 'shirt', 't-shirt', 'pants', 'jeans', 'trousers', 'shorts', 'dress', 'skirt', 'coat', 'sweater', 'underwear', 'shoes', 'bag', 'handbag', 'backpack', 'wallet', 'purse', 'belt', 'hat', 'cap', 'sunglasses', 'glasses', 'jewelry', 'necklace', 'ring', 'earrings', 'watch', 'fashion',
      'mỹ phẩm', 'skincare', 'son', 'son môi', 'kem dưỡng', 'kem chống nắng', 'sữa rửa mặt', 'tẩy trang', 'serum', 'toner', 'nước hoa', 'dầu gội', 'sữa tắm', 'dầu xả', 'kem body', 'kem đánh răng', 'bàn chải', 'makeup',
      'cosmetics', 'lipstick', 'perfume', 'parfum', 'moisturizer', 'sunscreen', 'shampoo', 'body wash', 'lotion',
      'điện thoại', 'smartphone', 'iphone', 'samsung', 'xiaomi', 'oppo', 'ipad', 'laptop', 'máy tính', 'máy tính bảng', 'tablet',
      'tai nghe', 'headphone', 'headphones', 'earphone', 'earphones', 'airpods', 'loa', 'loa bluetooth',
      'bàn phím', 'bàn phím cơ', 'chuột', 'chuột máy tính', 'mouse', 'keyboard', 'màn hình', 'monitor',
      'sạc', 'cáp sạc', 'củ sạc', 'power bank', 'pin dự phòng', 'sạc dự phòng', 'usb', 'webcam', 'microphone', 'ốp lưng', 'cường lực', 'phụ kiện điện thoại', 'phụ kiện máy tính',
      'đồ dùng', 'đồ gia dụng', 'đồ dùng cá nhân', 'đồ dùng gia đình', 'vật dụng', 'dụng cụ', 'nội thất', 'đồ nội thất', 'chăn', 'gối', 'ga giường', 'khăn', 'bình nước', 'ly', 'cốc', 'hộp cơm', 'ô', 'dù', 'đèn', 'đồ trang trí', 'decor', 'bàn ghế', 'giường', 'nệm', 'quạt', 'nồi cơm', 'chảo', 'bát đĩa', 'nước rửa chén', 'bột giặt',
      'household', 'home goods', 'furniture', 'appliance', 'bedding', 'pillow', 'blanket', 'kitchenware'
    ];
    final int shoppingScore = _keywordScore(paddedText, tokensSet, shoppingKeywords);

    // 9. Khác (other)
    final otherKeywords = ['khác', 'chi khác', 'khoản khác', 'tiền khác', 'other', 'misc', 'miscellaneous', 'others'];
    final int otherScore = _keywordScore(paddedText, tokensSet, otherKeywords);
    if (otherScore > 0) {
      return _CategoryClassification(
        category: 'Khác',
        type: 'expense',
        hasCategory: true,
        matchCount: otherScore,
      );
    }

    final scores = <String, int>{
      'Quà tặng': giftScore,
      'Học tập': educationScore,
      'Giải trí': entertainmentScore,
      'Đi lại': transportScore,
      'Mua sắm': shoppingScore,
      'Ăn uống': foodScore,
    };

    String bestCategory = 'Khác';
    int maxScore = 0;
    scores.forEach((cat, score) {
      if (score > maxScore) {
        maxScore = score;
        bestCategory = cat;
      }
    });

    if (maxScore > 0) {
      return _CategoryClassification(
        category: bestCategory,
        type: 'expense',
        hasCategory: true,
        matchCount: maxScore,
      );
    }

    return const _CategoryClassification(
      category: 'Khác',
      type: 'expense',
      hasCategory: false,
      matchCount: 0,
    );
  }

  static int _keywordScore(String paddedText, Set<String> tokensSet, List<String> keywords) {
    if (tokensSet.isEmpty) return 0;
    int score = 0;
    for (final kw in keywords) {
      final trimmedKw = kw.toLowerCase().trim();
      if (trimmedKw.isEmpty) continue;

      if (trimmedKw.contains(' ')) {
        // Multi-word phrase: check if paddedText contains ' $trimmedKw '
        if (paddedText.contains(' $trimmedKw ')) {
          score += 6 + (trimmedKw.length > 8 ? 4 : 2);
        }
      } else {
        // Single word token: check O(1) set lookup
        if (tokensSet.contains(trimmedKw)) {
          score += 4;
        }
      }
    }
    return score;
  }

  static String _cleanCaption(String original, String? moneyMatch) {
    String cleaned = original;

    // 1. Remove the money match if present
    if (moneyMatch != null && moneyMatch.isNotEmpty) {
      final String pattern = RegExp.escape(moneyMatch)
          .replaceAll('nghìn', r'(?:nghìn|ngàn|nghin|ngan)')
          .replaceAll('triệu', r'(?:triệu|trieu|tr|củ)')
          .replaceAll('trăm', r'(?:trăm|trắm|tram)')
          .replaceAll('tỷ', r'(?:tỷ|tỉ|ti)')
          .replaceAll('không', r'(?:không|khong|0)')
          .replaceAll('một', r'(?:1|một|mốt)')
          .replaceAll('hai', r'(?:2|hai|hăm)')
          .replaceAll('ba', r'(?:3|ba)')
          .replaceAll('bốn', r'(?:4|bốn|tư)')
          .replaceAll('năm', r'(?:5|năm|lăm|nhăm)')
          .replaceAll('sáu', r'(?:6|sáu)')
          .replaceAll('bảy', r'(?:7|bảy|bẩy)')
          .replaceAll('bẩy', r'(?:7|bảy|bẩy)')
          .replaceAll('tám', r'(?:8|tám)')
          .replaceAll('chín', r'(?:9|chín)')
          .replaceAll('mười', r'(?:10|mười)')
          .replaceAll(RegExp(r'\b1\b'), r'(?:1|một|mốt)')
          .replaceAll(RegExp(r'\b2\b'), r'(?:2|hai|hăm)')
          .replaceAll(RegExp(r'\b3\b'), r'(?:3|ba)')
          .replaceAll(RegExp(r'\b4\b'), r'(?:4|bốn|tư)')
          .replaceAll(RegExp(r'\b5\b'), r'(?:5|năm|lăm|nhăm)')
          .replaceAll(RegExp(r'\b6\b'), r'(?:6|sáu)')
          .replaceAll(RegExp(r'\b7\b'), r'(?:7|bảy|bẩy)')
          .replaceAll(RegExp(r'\b8\b'), r'(?:8|tám)')
          .replaceAll(RegExp(r'\b9\b'), r'(?:9|chín)')
          .replaceAll(RegExp(r'\b10\b'), r'(?:10|mười)');
      final moneyRegex = RegExp(
        r'(?:hết|hát|hét|mất|tốn|khoản|khoảng|giá|tổng cộng|for|spent|cost|chi|trả)?\s*' +
            pattern +
            r'(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|dollars|dollar|bucks|buck|vnđ|vnd|đồng|đô|nghìn|ngàn|triệu|tr|tỷ|ty|bil|usd|k|đ|₫|d)(?![a-zA-Z0-9\u00C0-\u024F\u1EA0-\u1EF9]))?',
        caseSensitive: false,
      );
      cleaned = cleaned.replaceAll(moneyRegex, ' ');
    }

    // 1b. Remove any residual formatted numbers or dot/comma fragments left behind (e.g. "3.500.000", "50.000", " .000", " ,000", "50k", "50000đ")
    final residualNumbersRegex = RegExp(
      r'(?:\b\d{1,3}(?:[.,]\d{3})+(?:\s*(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|dollars|dollar|bucks|buck|vnđ|vnd|đồng|đô|nghìn|ngàn|triệu|tỷ|ty|bil|usd|k|đ|₫|d))?)|' +
          r'(?:\s*[.,]\d{3,}\b(?:\s*[đ₫d])?)|' +
          r'(?:\b\d+\s*(?:k|cành|lít|nghìn|ngàn|triệu|\btr\b|củ|tỷ|usd|đồng|đ|₫|vnd|vnđ)\b)',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceAll(residualNumbersRegex, ' ');

    // 1c. Remove any residual Vietnamese spoken amount word fragments left behind
    // (e.g. "không trăm tám chục nghìn", "năm mươi nghìn", "năm trăm nghìn", "hai triệu", "trăm rưỡi", "ba lăm nghìn")
    final residualWordAmountsRegex = RegExp(
      r'(?:hết|hát|hét|mất|tốn|khoản|khoảng|giá)?\s*\b(?:một|hai|ba|bốn|tư|năm|sáu|bảy|bẩy|tám|chín|mười|hăm|\d+)?\s*(?:không\s*trăm|trăm|triệu|tỷ|chục|mươi|rưỡi|lẻ|linh)+\s*(?:mốt|hai|ba|bốn|tư|lăm|nhăm|sáu|bảy|bẩy|tám|chín|\d+)?(?:\s*(?:nghìn|ngàn|k|đồng|đ|₫|vnd|vnđ))?\b',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceAll(residualWordAmountsRegex, ' ');

    // 1d. Remove any residual currency keywords or symbols left behind
    final residualCurrencyRegex = RegExp(
      r'(?:\b(?:việt nam đồng|viet nam dong|nghìn đồng|ngàn đồng|triệu đồng|tỷ đồng|vnđ|vnd|đồng|nghìn|ngàn|triệu|dollars|dollar|bucks|buck|usd)\b)|(?:\s+[đ₫d]\s+)|(?:\s+[đ₫d]$)|(?:\b[đ₫]\b)',
      caseSensitive: false,
    );
    cleaned = cleaned.replaceAll(residualCurrencyRegex, ' ');

    // 2. Remove speech fillers (Vietnamese & English)
    final fillerPrefixes = [
      RegExp(r'^(?:à|ờ|ừm|ừ|này|thì|á|dạ|ê|um|uh|hey|well)\s+', caseSensitive: false),
      RegExp(r'^(?:hôm nay|sáng nay|trưa nay|chiều nay|tối nay|hôm qua|tối qua|sáng qua|trưa qua|chiều qua|today|yesterday|this morning|this afternoon|tonight)\s+(?:mình|em|anh|tôi|con|cháu|i)?\s*', caseSensitive: false),
      RegExp(r'^(?:mình|tôi|em|anh|con|cháu|i)\s+(?:vừa|mới|vừa mới|đã|có|được|just|had|paid|spent|got)?\s*', caseSensitive: false),
      RegExp(r'^(?:vừa|mới|vừa mới|đã|lại|just)\s+', caseSensitive: false),
      RegExp(r'^(?:chi|thanh toán|khoản|trả tiền|chi trả|tiêu hết|tiêu|spent on|paid for|bought)\s+', caseSensitive: false),
    ];

    bool changed = true;
    int iterations = 0;
    while (changed && iterations < 5) {
      changed = false;
      iterations++;
      for (final regex in fillerPrefixes) {
        if (regex.hasMatch(cleaned)) {
          final after = cleaned.replaceFirst(regex, '').trim();
          if (after.isNotEmpty) {
            cleaned = after;
            changed = true;
          }
        }
      }
    }

    final fillerSuffixes = [
      RegExp(r'\s+(?:nhé|nha|ạ|nè|nhen|hết|nhá|vậy|thôi|luôn|đó|rồi|please|already)$', caseSensitive: false),
      RegExp(r'\s+(?:luôn nhé|nha nhé|luôn nha|rồi nhé|rồi nha|for me)$', caseSensitive: false),
    ];

    changed = true;
    iterations = 0;
    while (changed && iterations < 5) {
      changed = false;
      iterations++;
      for (final regex in fillerSuffixes) {
        if (regex.hasMatch(cleaned)) {
          final after = cleaned.replaceFirst(regex, '').trim();
          if (after.isNotEmpty) {
            cleaned = after;
            changed = true;
          }
        }
      }
    }

    // Clean whitespace and any stray punctuation left at boundaries (e.g. leftover dots, commas, hyphens)
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[.,;:–\-\s]+|[.,;:–\-\s]+$'), '').trim();

    if (cleaned.isEmpty) {
      cleaned = original.trim();
    }

    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }

    return cleaned;
  }
}

class _AmountParseResult {
  final double amount;
  final String currency;
  final bool hasAmount;
  final String? matchedString;

  const _AmountParseResult({
    required this.amount,
    required this.currency,
    required this.hasAmount,
    this.matchedString,
  });
}

class _CategoryClassification {
  final String category;
  final String type;
  final bool hasCategory;
  final int matchCount;

  const _CategoryClassification({
    required this.category,
    required this.type,
    required this.hasCategory,
    required this.matchCount,
  });
}
