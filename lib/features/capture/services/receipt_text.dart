String normalizeReceiptText(String input) {
  var text =
      input.toLowerCase().replaceAll(RegExp(r'[\u00a0\u2007\u202f]'), ' ');
  const accents = [
    'aàáảãạăằắẳẵặâầấẩẫậ',
    'eèéẻẽẹêềếểễệ',
    'iìíỉĩị',
    'oòóỏõọôồốổỗộơờớởỡợ',
    'uùúủũụưừứửữự',
    'yỳýỷỹỵ',
    'dđ',
  ];
  for (final group in accents) {
    for (final rune in group.runes) {
      text = text.replaceAll(String.fromCharCode(rune), group[0]);
    }
  }
  return text
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
}
