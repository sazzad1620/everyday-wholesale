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

// ---------------------------------------------------------------------------
// Product search matching
// ---------------------------------------------------------------------------

/// Anything that is not a letter or digit separates words (space, `-`, `/`,
/// `&`, brackets, commas…).
final RegExp _wordSeparators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Hiragana/katakana/kanji (and half-width katakana). Japanese has no spaces
/// between words, so "begins a word" has no meaning there.
final RegExp _japanese = RegExp(r'[\u3040-\u30FF\u3400-\u4DBF\u4E00-\u9FFF\uFF66-\uFF9F]');

List<String> _words(String normalized) => normalized.split(_wordSeparators).where((w) => w.isNotEmpty).toList();

/// How well [names] (a product's name in every language) match [query], or
/// `null` when they don't match. **Lower is better** — sort ascending.
///
/// Word-wise, not substring: every word you type must be the *beginning* of
/// a word in the name. For "Indian Basmati Rice": `indi`, `ric`, `bas ric`
/// and `rice indian` match; `ndi`, `asmati` and `ic` do not. Words may be
/// typed in any order.
///
/// Japanese text has no word boundaries, so a query containing kana or kanji
/// matches anywhere in the name (still after [normalizeForSearch], so
/// `ライス`, `らいす` and `ﾗｲｽ` are the same). An empty query matches
/// everything with rank 0.
int? searchRank(String query, Iterable<String> names) {
  final tokens = _words(normalizeForSearch(query));
  if (tokens.isEmpty) return 0;

  int? best;
  for (final name in names) {
    final rank = _rankInName(tokens, normalizeForSearch(name));
    if (rank != null && (best == null || rank < best)) best = rank;
  }
  return best;
}

/// Convenience for call sites that only need yes/no.
bool matchesSearch(String query, Iterable<String> names) => searchRank(query, names) != null;

int? _rankInName(List<String> tokens, String name) {
  final words = _words(name);
  var position = 0;
  for (final token in tokens) {
    final int index;
    if (_japanese.hasMatch(token)) {
      index = name.indexOf(token);
    } else {
      index = words.indexWhere((word) => word.startsWith(token));
    }
    if (index < 0) return null;
    // Matches earlier in the name rank higher ("rice" beats "…basmati rice").
    position += index;
  }
  // Shorter names win ties, so the closest match comes first.
  return position * 1000 + (name.length < 999 ? name.length : 999);
}

/// Keeps the items whose names match [query] and orders them best-first;
/// equal ranks keep their original order. Returns [items] untouched for an
/// empty query.
List<T> filterBySearch<T>(List<T> items, String query, Iterable<String> Function(T item) namesOf) {
  if (_words(normalizeForSearch(query)).isEmpty) return items;
  final ranked = <(int, int, T)>[];
  for (var i = 0; i < items.length; i++) {
    final rank = searchRank(query, namesOf(items[i]));
    if (rank != null) ranked.add((rank, i, items[i]));
  }
  ranked.sort((a, b) {
    final byRank = a.$1.compareTo(b.$1);
    return byRank != 0 ? byRank : a.$2.compareTo(b.$2);
  });
  return [for (final r in ranked) r.$3];
}
