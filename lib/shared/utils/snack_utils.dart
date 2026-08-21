import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

void showComingSoonSnackBar(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('common.coming_soon'.tr(namedArgs: {'feature': feature})),
      ),
    );
}
