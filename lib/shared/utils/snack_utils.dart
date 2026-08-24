import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

void showComingSoonSnackBar(BuildContext context, String feature) {
  showSnackMessage(context, 'common.coming_soon'.tr(namedArgs: {'feature': feature}));
}

void showSnackMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
