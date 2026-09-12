import 'dart:ui' show Locale;

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show BuildContext;

/// Admin-entered text stored in every supported language at once — product
/// and category names, descriptions, and the order/review snapshots taken
/// from them. Stored in Firestore as `{ "en": "...", "ja": "..." }`.
///
/// English is the required source language (client decision); Japanese is
/// optional and falls back to English when empty, so a product the admin
/// hasn't translated yet still displays rather than showing a blank.
class LocalizedText extends Equatable {
  const LocalizedText({required this.en, this.ja = ''});

  static const LocalizedText empty = LocalizedText(en: '');

  final String en;
  final String ja;

  /// Reads either shape a document can carry:
  /// - the new map `{en, ja}`;
  /// - a plain string written before this change (treated as English).
  /// Keeping both readable means the app never breaks on a document that
  /// hasn't been through `migrate_localized_fields.dart` yet.
  factory LocalizedText.fromFirestore(Object? raw) {
    if (raw is Map) {
      return LocalizedText(
        en: raw['en'] as String? ?? '',
        ja: raw['ja'] as String? ?? '',
      );
    }
    if (raw is String) return LocalizedText(en: raw);
    return empty;
  }

  Map<String, String> toMap() => {'en': en, 'ja': ja};

  /// The text to show for [locale] — Japanese when requested and present,
  /// otherwise English.
  String resolve(Locale locale) {
    if (locale.languageCode == 'ja' && ja.trim().isNotEmpty) return ja;
    return en;
  }

  bool get hasJa => ja.trim().isNotEmpty;
  bool get isEmpty => en.trim().isEmpty && !hasJa;

  /// Every stored language, for search — a query should match a product
  /// whichever language it was typed in.
  Iterable<String> get values => [en, ja].where((v) => v.isNotEmpty);

  LocalizedText copyWith({String? en, String? ja}) => LocalizedText(en: en ?? this.en, ja: ja ?? this.ja);

  @override
  List<Object?> get props => [en, ja];

  @override
  String toString() => 'LocalizedText(en: $en, ja: $ja)';
}

extension LocalizedTextContext on BuildContext {
  /// `context.localized(product.name)` — resolves against the app's current
  /// language, which is what every screen wants.
  String localized(LocalizedText text) => text.resolve(locale);
}
