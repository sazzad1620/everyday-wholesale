import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_test/flutter_test.dart';

// Guards the assumption behind `date_formatter.dart`: once `bootstrap.dart`
// has loaded the Japanese symbols, the same `DateFormat` patterns produce
// native-looking output for both supported locales.
void main() {
  setUpAll(() => initializeDateFormatting('ja'));

  final date = DateTime(2026, 9, 12);

  test('long date renders per locale', () {
    expect(DateFormat.yMMMMd('en').format(date), 'September 12, 2026');
    expect(DateFormat.yMMMMd('ja').format(date), '2026年9月12日');
  });

  test('short date renders per locale', () {
    expect(DateFormat.yMMMd('en').format(date), 'Sep 12, 2026');
    expect(DateFormat.yMMMd('ja').format(date), '2026年9月12日');
  });
}
