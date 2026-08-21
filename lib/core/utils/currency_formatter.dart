import 'package:intl/intl.dart';

final NumberFormat _yenFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0);

String formatYen(int amount) => _yenFormat.format(amount);
