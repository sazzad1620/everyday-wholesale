import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Locale-aware date formatting — `DateFormat` defaults to English unless
/// told otherwise, so every date the user sees goes through here and picks
/// up the active app language ("September 12, 2026" / "2026年9月12日").
/// The Japanese symbols are loaded in `bootstrap.dart`.

/// Full month name: order dates, "Purchased on", "Reviewed on".
String formatLongDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMMd(context.locale.toString()).format(date);

/// Abbreviated month: dense admin lists.
String formatShortDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(context.locale.toString()).format(date);
