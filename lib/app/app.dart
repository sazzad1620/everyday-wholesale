import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/di/injection_container.dart';
import '../config/routes/app_router.dart';
import '../core/localization/app_locales.dart';
import '../core/localization/japanese_font.dart';
import '../core/localization/rebuild_on_locale_change.dart';
import '../core/notifications/push_notification_service.dart';
import '../features/auth/presentation/bloc/account_bloc.dart';
import '../features/auth/presentation/bloc/account_state.dart';
import '../features/cart/presentation/bloc/cart_bloc.dart';
import '../features/cart/presentation/bloc/cart_state.dart';
import '../shared/theme/app_theme.dart';
import '../shared/utils/toast.dart';

class EverydayWholesaleApp extends StatelessWidget {
  const EverydayWholesaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilt by EasyLocalization on every language change, so the theme's
    // body font follows the active locale (Noto Sans JP for Japanese).
    final locale = context.locale;
    final bodyFont = AppLocales.bodyFontFor(locale);
    // Fetched only once Japanese is actually in use (at launch for a saved
    // Japanese preference, or on switching) — idempotent, never throws.
    if (locale.languageCode == AppLocales.ja.languageCode) JapaneseFont.ensureLoaded();
    // Push topic follows the app language (idempotent; no-op on web).
    PushNotificationService.syncLanguage(locale.languageCode);

    return BlocListener<AccountBloc, AccountState>(
      bloc: getIt<AccountBloc>(),
      // Only when a *different* account becomes signed in — includes the
      // persisted session restored at launch, but not profile edits or the
      // preference write itself (same uid), which would otherwise loop.
      listenWhen: (previous, current) => current.user != null && previous.user?.uid != current.user!.uid,
      listener: (context, state) {
        final preferred = state.user!.preferredLocale;
        if (preferred == null) return;
        final target = AppLocales.supported.where((l) => l.languageCode == preferred).firstOrNull;
        if (target != null && target != context.locale) context.setLocale(target);
      },
      child: MaterialApp.router(
        // No per-language key here: re-keying the app on every switch destroyed
        // and recreated everything (menu closed, state and data reloaded, a
        // black flash on Android). `RebuildOnLocaleChange` below refreshes the
        // text in place instead.
        debugShowCheckedModeBanner: false,
        title: 'Everyday Wholesale',
        theme: AppTheme.light(bodyFont: bodyFont),
        darkTheme: AppTheme.dark(bodyFont: bodyFont),
        themeMode: ThemeMode.light,
        // The theme only ever changes with the language (its body font). Flutter
        // animates a theme change over 200 ms, but a font family can't be blended:
        // it flips at the halfway point — so the new language's text was drawn in
        // the OLD font for ~100 ms, then jumped. No animation: text and font change
        // together, in one frame.
        themeAnimationDuration: Duration.zero,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        routerConfig: appRouter,
        // Cart changes show instantly and save in the background; if a save
        // fails (e.g. offline) CartBloc restores the real cart — say so,
        // whichever page the customer is on by then.
        builder: (context, child) => RebuildOnLocaleChange(
          child: BlocListener<CartBloc, CartState>(
            bloc: getIt<CartBloc>(),
            listenWhen: (previous, current) =>
                current.syncErrorCount != previous.syncErrorCount && current.syncErrorKey != null,
            listener: (context, state) {
              final overlay = rootNavigatorKey.currentState?.overlay;
              if (overlay != null) AppToast.showInOverlay(overlay, 'cart.sync_failed'.tr(), type: ToastType.error);
            },
            child: child!,
          ),
        ),
      ),
    );
  }
}
