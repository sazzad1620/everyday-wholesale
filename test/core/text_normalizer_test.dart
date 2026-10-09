import 'package:everyday_wholesale/core/utils/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  searchMatchingTests();
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

void searchMatchingTests() {
  group('word-wise product search', () {
    const names = ['Indian Basmati Rice 5kg', 'インディアン バスマティライス'];

    test('matches the beginning of any word, in any order', () {
      for (final query in ['indi', 'ind', 'ric', 'rice', 'bas', 'bas ric', 'rice indian', 'INDIAN rice', '5k']) {
        expect(matchesSearch(query, names), isTrue, reason: query);
      }
    });

    test('does not match the middle or end of a word', () {
      for (final query in ['ndi', 'ic', 'asmati', 'ice', 'ian', 'ati']) {
        expect(matchesSearch(query, names), isFalse, reason: query);
      }
    });

    test('every typed word has to match', () {
      expect(matchesSearch('indian wheat', names), isFalse);
    });

    test('punctuation and hyphens separate words', () {
      expect(matchesSearch('rice', ['Long-grain (rice) & dal']), isTrue);
      expect(matchesSearch('grain', ['Long-grain (rice) & dal']), isTrue);
      expect(matchesSearch('rain', ['Long-grain (rice) & dal']), isFalse);
    });

    test('Japanese has no word boundaries, so it matches anywhere (any kana script)', () {
      expect(matchesSearch('ライス', names), isTrue);
      expect(matchesSearch('らいす', names), isTrue);
      expect(matchesSearch('ティ', names), isTrue);
      expect(matchesSearch('ミルク', names), isFalse);
    });

    test('an empty query matches everything', () {
      expect(matchesSearch('', names), isTrue);
      expect(matchesSearch('   ', names), isTrue);
    });

    test('filterBySearch drops non-matches and ranks closer matches first', () {
      const items = ['Basmati Rice', 'Rice Flour', 'Brown Rice', 'Wheat Flour'];
      final result = filterBySearch<String>(items, 'rice', (n) => [n]);
      // "rice" is the first word of Rice Flour; the other two match their 2nd word, shorter name first.
      expect(result, ['Rice Flour', 'Brown Rice', 'Basmati Rice']);
      expect(filterBySearch<String>(items, '', (n) => [n]), items);
      expect(filterBySearch<String>(items, 'xyz', (n) => [n]), isEmpty);
    });
  });
}
