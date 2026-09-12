import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../config/routes/app_router.dart';
import '../core/localization/app_locales.dart';
import '../shared/theme/app_theme.dart';

class EverydayWholesaleApp extends StatelessWidget {
  const EverydayWholesaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilt by EasyLocalization on every language change, so the theme's
    // body font follows the active locale (Noto Sans JP for Japanese).
    final locale = context.locale;
    final bodyFont = AppLocales.bodyFontFor(locale);

    return MaterialApp.router(
      // Keyed on the locale so a language switch remounts the whole tree.
      // Screens read their strings with a context-free `'key'.tr()`, which
      // registers no inherited dependency — so the many `const` widgets
      // below the router would otherwise keep showing the old language
      // until something else happened to rebuild them. Remounting is safe:
      // `appRouter` is a global and keeps the current location, and app
      // state lives in `getIt` singletons rather than in widget state.
      key: ValueKey(locale.languageCode),
      debugShowCheckedModeBanner: false,
      title: 'Everyday Wholesale',
      theme: AppTheme.light(bodyFont: bodyFont),
      darkTheme: AppTheme.dark(bodyFont: bodyFont),
      themeMode: ThemeMode.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: appRouter,
    );
  }
}
