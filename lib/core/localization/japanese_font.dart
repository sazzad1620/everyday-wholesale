import 'package:flutter/services.dart';

/// Noto Sans JP for 日本語 mode, loaded on demand from the app's own assets.
///
/// Replaces `google_fonts`' `notoSansJp()`, which downloaded the *complete*
/// font (~3 MB compressed) separately for every weight the UI used. These
/// are subsets — kana, JIS X 0208 (all level 1 + 2 kanji), Latin and common
/// symbols (see `tool/fonts/subset_noto_sans_jp.js`) — ~1.2 MB compressed
/// per weight, in just Regular and Bold (w500/w600 resolve to the nearest).
///
/// They're plain assets (not a pubspec `fonts:` entry) on purpose: declared
/// fonts are fetched by every visitor before the first frame, even ones who
/// never switch to Japanese. Until they arrive, Flutter's own CJK fallback
/// covers the text, then it re-lays out in Noto Sans JP. The Flutter web
/// engine's fallback alone isn't used for this because it only picks
/// Japanese glyph shapes when `navigator.language` is exactly `ja` — phones
/// report `ja-JP` and would get Chinese-style kanji.
abstract final class JapaneseFont {
  static const String family = 'NotoSansJP';

  static const String _regular = 'assets/fonts/jp/NotoSansJP-Regular.ttf';
  static const String _bold = 'assets/fonts/jp/NotoSansJP-Bold.ttf';

  static Future<void>? _loading;

  /// Starts loading once; later calls are free. Never throws — on failure
  /// text simply stays on the fallback font and the next call retries.
  static Future<void> ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      // Regular first: it covers most on-screen text, so it shouldn't wait
      // behind the bold file's download.
      await (FontLoader(family)..addFont(rootBundle.load(_regular))).load();
      await (FontLoader(family)..addFont(rootBundle.load(_bold))).load();
    } catch (_) {
      _loading = null;
    }
  }
}
