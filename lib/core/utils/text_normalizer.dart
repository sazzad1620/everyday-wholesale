/// Normalises text for bilingual search so a query matches regardless of
/// how it was typed:
/// - case-insensitive (`Rice` / `rice`);
/// - full-width ASCII → half-width (`ＡＢＣ１２３` → `abc123`, as Japanese
///   IMEs often emit full-width letters and digits);
/// - katakana → hiragana (`ライス` → `らいす`), so either kana script matches
///   a product named in the other;
/// - half-width katakana → full-width, then folded like the above;
/// - whitespace collapsed.
///
/// Both the stored name and the query go through this before `contains`.
String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    buffer.writeCharCode(_fold(rune));
  }
  return buffer.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

int _fold(int rune) {
  // Full-width ASCII block (U+FF01–U+FF5E) maps 1:1 onto U+0021–U+007E.
  if (rune >= 0xFF01 && rune <= 0xFF5E) return rune - 0xFEE0;
  // Ideographic space → ordinary space.
  if (rune == 0x3000) return 0x20;
  // Katakana (U+30A1–U+30F6) → hiragana (U+3041–U+3096): a fixed offset.
  if (rune >= 0x30A1 && rune <= 0x30F6) return rune - 0x60;
  // Half-width katakana → full-width katakana → hiragana. Voiced marks
  // (ﾞ ﾟ) are dropped rather than combined — a rare enough case that the
  // simpler "base character still matches" behaviour is fine for search.
  if (rune >= 0xFF66 && rune <= 0xFF9D) {
    final fullWidth = _halfWidthKatakana[rune - 0xFF66];
    return (fullWidth >= 0x30A1 && fullWidth <= 0x30F6) ? fullWidth - 0x60 : fullWidth;
  }
  if (rune == 0xFF9E || rune == 0xFF9F) return 0x20;
  return rune;
}

// U+FF66 (ｦ) … U+FF9D (ﾝ) → their full-width katakana code points.
const List<int> _halfWidthKatakana = [
  0x30F2, 0x30A1, 0x30A3, 0x30A5, 0x30A7, 0x30A9, 0x30E3, 0x30E5, 0x30E7, 0x30C3, // ｦｧｨｩｪｫｬｭｮｯ
  0x30FC, // ｰ (prolonged sound mark — no hiragana form, kept as-is)
  0x30A2, 0x30A4, 0x30A6, 0x30A8, 0x30AA, // ｱｲｳｴｵ
  0x30AB, 0x30AD, 0x30AF, 0x30B1, 0x30B3, // ｶｷｸｹｺ
  0x30B5, 0x30B7, 0x30B9, 0x30BB, 0x30BD, // ｻｼｽｾｿ
  0x30BF, 0x30C1, 0x30C4, 0x30C6, 0x30C8, // ﾀﾁﾂﾃﾄ
  0x30CA, 0x30CB, 0x30CC, 0x30CD, 0x30CE, // ﾅﾆﾇﾈﾉ
  0x30CF, 0x30D2, 0x30D5, 0x30D8, 0x30DB, // ﾊﾋﾌﾍﾎ
  0x30DE, 0x30DF, 0x30E0, 0x30E1, 0x30E2, // ﾏﾐﾑﾒﾓ
  0x30E4, 0x30E6, 0x30E8, // ﾔﾕﾖ
  0x30E9, 0x30EA, 0x30EB, 0x30EC, 0x30ED, // ﾗﾘﾙﾚﾛ
  0x30EF, 0x30F3, // ﾜﾝ
];
