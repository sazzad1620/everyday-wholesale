// The migration tool's transforms are private static methods on a widget
// state, so this exercises the same rules through the public helpers they
// delegate to — enough to lock in the "legacy → new shape, new shape
// untouched" contract without booting Firebase.
import 'package:everyday_wholesale/core/constants/countries.dart';
import 'package:everyday_wholesale/core/localization/localized_text.dart';
import 'package:everyday_wholesale/features/product/domain/entities/product_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a seeded legacy product round-trips through the parsers to the new shape', () {
    final legacy = {'name': 'Basmati Rice', 'condition': 'Dry / Packaged', 'origin': 'India'};
    expect(LocalizedText.fromFirestore(legacy['name']).toMap(), {'en': 'Basmati Rice', 'ja': ''});
    expect(ProductCondition.parse(legacy['condition']).code, 'dry_packaged');
    expect(Countries.parse(legacy['origin']), 'IN');
  });

  test('an already-migrated product is stable (idempotent)', () {
    expect(ProductCondition.parse('dry_packaged').code, 'dry_packaged');
    expect(Countries.parse('IN'), 'IN');
    final map = {'en': 'Basmati Rice', 'ja': 'バスマティライス'};
    expect(LocalizedText.fromFirestore(map).toMap(), map);
  });
}
