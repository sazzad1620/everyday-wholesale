import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../config/routes/app_router.dart';
import '../shared/theme/app_theme.dart';

class EverydayWholesaleApp extends StatelessWidget {
  const EverydayWholesaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Everyday Wholesale',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: appRouter,
    );
  }
}
