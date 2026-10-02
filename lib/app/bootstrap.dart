import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../config/di/injection_container.dart';
import '../core/localization/app_locales.dart';
import '../core/utils/google_sign_in_setup.dart';
import '../core/utils/stripe_setup.dart';
import '../firebase_options.dart';
import 'app.dart';

Future<void> bootstrap() async {
  // Real paths (`/home/category/…`) instead of Flutter's default `/#/home/…`:
  // search engines treat everything after `#` as the same page, so no
  // category or product could ever be indexed on its own. Hosting already
  // rewrites every path to index.html; old `#/` links are converted by a
  // small script in web/index.html. No-op on mobile.
  usePathUrlStrategy();
  // The app navigates with `context.push` (category → product …), which
  // go_router doesn't write to the address bar by default — the URL would
  // stay `/home`, so a product page couldn't be copied, shared or
  // bookmarked. Must be set before `appRouter` is created.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  WidgetsFlutterBinding.ensureInitialized();
  // Independent of each other, so they run concurrently — on web
  // `Firebase.initializeApp` is a network round-trip (it loads the Firebase
  // JS SDK), and nothing else here should queue behind it.
  await Future.wait([
    EasyLocalization.ensureInitialized(),
    // `DateFormat` only knows English out of the box — every other locale's
    // month/day names have to be loaded first, and easy_localization doesn't
    // do it for us. Without this, a Japanese-locale `DateFormat` throws.
    initializeDateFormatting(AppLocales.ja.languageCode),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  // Stripe and Google Sign-In are only needed at checkout / on "Continue
  // with Google", so neither holds up the first frame any more: they start
  // in the background and the payment / sign-in code awaits
  // `StripeSetup.ensureReady()` / `GoogleSignInSetup.ensureReady()` first.
  // On web Stripe waits a few seconds so Stripe.js (a network download)
  // doesn't compete with the app's own startup requests; web signs in via
  // Firebase's popup, so Google Sign-In isn't initialized there at all.
  if (kIsWeb) {
    unawaited(
      Future<void>.delayed(const Duration(seconds: 4), StripeSetup.ensureReady).catchError((_) {}),
    );
  } else {
    unawaited(StripeSetup.ensureReady().catchError((_) {}));
    unawaited(GoogleSignInSetup.ensureReady().catchError((_) {}));
  }

  configureDependencies();

  // Edge-to-edge on every Android version, not just 15+ (where targetSdk 36
  // forces it and ignores `systemNavigationBarColor`), so gesture navigation
  // and the 2/3-button bar look the same on all phones: both system bars are
  // transparent, drawn over the app's own white background, and every page,
  // sheet and dialog keeps its content clear of them with SafeArea.
  // `...ContrastEnforced: false` stops Android from painting its own grey
  // translucent band behind the 3-button bar (and the status bar). No-op on
  // iOS, where the app already draws under the status bar/home indicator.
  if (!kIsWeb) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      // Only applies when nothing has been saved yet — once the user picks a
      // language, easy_localization persists it and that wins on next launch.
      startLocale: AppLocales.start,
      fallbackLocale: AppLocales.fallback,
      child: const EverydayWholesaleApp(),
    ),
  );
}
