/// Normalizes pinyin for lenient answer comparison: strips tone diacritics,
/// lowercases, maps ü/v → u, and removes spaces, apostrophes and hyphens.
///
/// Users typing pinyin on a standard keyboard can't produce tone marks or the
/// `ü` glyph, so spelling answers are compared on this normalized form.
String normalizePinyin(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final mapped = _toneless[char];
    if (mapped != null) {
      buffer.write(mapped);
      continue;
    }
    if (char == 'v' || char == 'ü') {
      buffer.write('u');
      continue;
    }
    if (RegExp(r'[a-z]').hasMatch(char)) {
      buffer.write(char);
    }
    // Everything else (spaces, apostrophes, hyphens, digits, punctuation) is
    // dropped.
  }
  return buffer.toString();
}

const Map<String, String> _toneless = {
  'ā': 'a', 'á': 'a', 'ǎ': 'a', 'à': 'a',
  'ē': 'e', 'é': 'e', 'ě': 'e', 'è': 'e',
  'ī': 'i', 'í': 'i', 'ǐ': 'i', 'ì': 'i',
  'ō': 'o', 'ó': 'o', 'ǒ': 'o', 'ò': 'o',
  'ū': 'u', 'ú': 'u', 'ǔ': 'u', 'ù': 'u',
  'ǖ': 'u', 'ǘ': 'u', 'ǚ': 'u', 'ǜ': 'u', 'ü': 'u',
  'ń': 'n', 'ň': 'n', 'ǹ': 'n', 'ḿ': 'm',
};
