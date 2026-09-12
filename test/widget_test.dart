import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyday_wholesale/shared/theme/app_theme.dart';

void main() {
  test('AppTheme exposes a light and dark Material 3 theme', () {
    expect(AppTheme.light().useMaterial3, isTrue);
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().useMaterial3, isTrue);
    expect(AppTheme.dark().brightness, Brightness.dark);
  });

  test('AppTheme applies the locale body font when given one', () {
    const jp = TextStyle(fontFamily: 'NotoSansJP', fontFamilyFallback: ['sans-serif']);
    expect(AppTheme.light().textTheme.bodyMedium?.fontFamily, isNot('NotoSansJP'));
    expect(AppTheme.light(bodyFont: jp).textTheme.bodyMedium?.fontFamily, 'NotoSansJP');
    expect(AppTheme.light(bodyFont: jp).textTheme.bodyMedium?.fontFamilyFallback, ['sans-serif']);
  });
}
