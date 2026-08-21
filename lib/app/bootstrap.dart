import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../config/di/injection_container.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  configureDependencies();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const EverydayWholesaleApp(),
    ),
  );
}
