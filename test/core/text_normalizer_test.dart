import 'package:everyday_wholesale/core/utils/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lowercases and collapses whitespace', () {
    expect(normalizeForSearch('  Basmati   Rice '), 'basmati rice');
  });

  test('folds full-width ASCII and ideographic space', () {
    expect(normalizeForSearch('ＡＢＣ１２３　ｘ'), 'abc123 x');
  });

  test('folds katakana to hiragana so either script matches', () {
    expect(normalizeForSearch('ライス'), 'らいす');
    expect(normalizeForSearch('らいす'), normalizeForSearch('ライス'));
  });

  test('folds half-width katakana too', () {
    expect(normalizeForSearch('ﾗｲｽ'), 'らいす');
  });

  test('leaves kanji and the prolonged sound mark alone', () {
    expect(normalizeForSearch('米'), '米');
    expect(normalizeForSearch('カレー'), 'かれー');
    expect(normalizeForSearch('ｶﾚｰ'), 'かれー');
  });

  test('a mixed query matches a bilingual name in either language', () {
    const en = 'Basmati Rice 1kg';
    const ja = 'バスマティライス 1kg';
    bool matches(String q) => [en, ja].any((n) => normalizeForSearch(n).contains(normalizeForSearch(q)));
    expect(matches('basmati'), isTrue);
    expect(matches('ばすまてぃ'), isTrue);
    expect(matches('ＢＡＳＭＡＴＩ'), isTrue);
    expect(matches('１ｋｇ'), isTrue);
    expect(matches('quinoa'), isFalse);
  });
}
