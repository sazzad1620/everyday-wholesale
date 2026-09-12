import 'package:easy_localization/easy_localization.dart';

/// Product origin countries — ISO 3166-1 alpha-2 codes, stored on the
/// product doc as-is and translated at display time (`country.<CODE>` in the
/// translation files). Deliberately a short list of where the client
/// actually sources from; adding one is a line here plus a key in each
/// translation file.
abstract final class Countries {
  static const List<String> codes = [
    'BD', // Bangladesh
    'IN', // India
    'BR', // Brazil
    'JP', // Japan
    'TH', // Thailand
    'VN', // Vietnam
    'PH', // Philippines
    'ID', // Indonesia
    'NP', // Nepal
    'LK', // Sri Lanka
    'PK', // Pakistan
    'CN', // China
    'US', // United States
    'AU', // Australia
  ];

  static bool isKnown(String code) => codes.contains(code);

  /// Translated country name; an unknown code (e.g. an unmigrated legacy
  /// free-text origin) is shown verbatim rather than as a raw key.
  static String label(String code) => isKnown(code) ? 'country.$code'.tr() : code;

  /// Accepts a stored code, or — for documents written before origins were
  /// codes — the old free-text English name ("Bangladesh" → `BD`). Unknown
  /// text is returned unchanged so nothing is silently lost.
  static String parse(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final upper = raw.trim().toUpperCase();
    if (isKnown(upper)) return upper;
    return _legacyNames[raw.trim().toLowerCase()] ?? raw.trim();
  }

  static const Map<String, String> _legacyNames = {
    'bangladesh': 'BD',
    'india': 'IN',
    'brazil': 'BR',
    'japan': 'JP',
    'thailand': 'TH',
    'vietnam': 'VN',
    'philippines': 'PH',
    'indonesia': 'ID',
    'nepal': 'NP',
    'sri lanka': 'LK',
    'pakistan': 'PK',
    'china': 'CN',
    'usa': 'US',
    'united states': 'US',
    'australia': 'AU',
  };
}
