import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:everyday_wholesale/shared/theme/app_theme.dart';

void main() {
  test('AppTheme exposes a light and dark Material 3 theme', () {
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.useMaterial3, isTrue);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });
}
