import 'dart:convert';
import 'dart:io';

import 'package:everyday_wholesale/features/home/data/datasources/home_initial_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test between the `ssr` Cloud Function (functions/src/seo/
/// render.ts, which embeds the home data) and the app, which parses it.
/// The fixture is real renderer output, trimmed to a few documents.
void main() {
  final raw = File('test/fixtures/initial_home_data.json').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;

  test('parses categories, banners and popular products from renderer output', () {
    final data = parseInitialHomeData(raw);

    expect(data, isNotNull);
    expect(data!.categories.map((c) => c.id), (json['categories'] as List).map((c) => c['id']));
    expect(data.banners.single.imageUrl, (json['banners'] as List).single['imageUrl']);

    final product = data.popular.single;
    final source = (json['popular'] as List).single as Map<String, dynamic>;
    expect(product.id, source['id']);
    expect(product.price, (source['price'] as num).toInt());
    expect(product.isMostPopular, isTrue);
    expect(product.name.en, isNotEmpty);
  });

  test('keeps subcategories and reads legacy plain-string names', () {
    final category = parseInitialHomeData(raw)!.categories.first;
    final source = (json['categories'] as List).first as Map<String, dynamic>;

    expect(category.subcategories.length, (source['subcategories'] as List).length);
    expect(category.name.en, isNotEmpty);
  });

  test('returns null for malformed input instead of throwing', () {
    expect(parseInitialHomeData('not json'), isNull);
    expect(parseInitialHomeData('{"categories": "oops"}'), isNull);
  });
}
