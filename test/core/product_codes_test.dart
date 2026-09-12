import 'package:everyday_wholesale/core/constants/countries.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductCondition.parse', () {
    test('accepts stored codes', () {
      for (final c in ProductCondition.values) {
        expect(ProductCondition.parse(c.code), c);
      }
    });

    test('maps the legacy free-text labels from seed data', () {
      expect(ProductCondition.parse('Fresh'), ProductCondition.fresh);
      expect(ProductCondition.parse('Frozen'), ProductCondition.frozen);
      expect(ProductCondition.parse('Dry / Packaged'), ProductCondition.dryPackaged);
      expect(ProductCondition.parse('Ambient'), ProductCondition.ambient);
      expect(ProductCondition.parse('Freshly Prepared'), ProductCondition.freshlyPrepared);
    });

    test('falls back to dryPackaged for unknown/null', () {
      expect(ProductCondition.parse(null), ProductCondition.dryPackaged);
      expect(ProductCondition.parse('???'), ProductCondition.dryPackaged);
    });

    test('every code has a label key under product.condition', () {
      expect(ProductCondition.frozen.labelKey, 'product.condition.frozen');
    });
  });

  group('Countries.parse', () {
    test('keeps known codes (case-insensitive)', () {
      expect(Countries.parse('BD'), 'BD');
      expect(Countries.parse('jp'), 'JP');
    });

    test('maps the legacy English names from seed data', () {
      expect(Countries.parse('Bangladesh'), 'BD');
      expect(Countries.parse('India'), 'IN');
      expect(Countries.parse('Brazil'), 'BR');
    });

    test('returns unknown text unchanged and empty for null', () {
      expect(Countries.parse('Atlantis'), 'Atlantis');
      expect(Countries.parse(null), '');
    });
  });
}
