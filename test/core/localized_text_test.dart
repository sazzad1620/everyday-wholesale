import 'dart:ui';

import 'package:everyday_wholesale/core/localization/localized_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const en = Locale('en');
  const ja = Locale('ja');

  group('fromFirestore', () {
    test('reads the {en, ja} map shape', () {
      final t = LocalizedText.fromFirestore({'en': 'Rice', 'ja': '米'});
      expect(t.en, 'Rice');
      expect(t.ja, '米');
    });

    test('reads a legacy plain string as English', () {
      final t = LocalizedText.fromFirestore('Rice');
      expect(t, const LocalizedText(en: 'Rice'));
    });

    test('tolerates a map with only en, and null', () {
      expect(LocalizedText.fromFirestore({'en': 'Rice'}), const LocalizedText(en: 'Rice'));
      expect(LocalizedText.fromFirestore(null), LocalizedText.empty);
    });
  });

  group('resolve', () {
    test('returns Japanese when present and requested', () {
      const t = LocalizedText(en: 'Rice', ja: '米');
      expect(t.resolve(ja), '米');
      expect(t.resolve(en), 'Rice');
    });

    test('falls back to English when Japanese is blank', () {
      expect(const LocalizedText(en: 'Rice').resolve(ja), 'Rice');
      expect(const LocalizedText(en: 'Rice', ja: '   ').resolve(ja), 'Rice');
    });
  });

  test('toMap round-trips', () {
    const t = LocalizedText(en: 'Rice', ja: '米');
    expect(LocalizedText.fromFirestore(t.toMap()), t);
  });

  test('values lists every non-empty language for search', () {
    expect(const LocalizedText(en: 'Rice', ja: '米').values, ['Rice', '米']);
    expect(const LocalizedText(en: 'Rice').values, ['Rice']);
  });
}
