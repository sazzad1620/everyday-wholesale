import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../config/di/injection_container.dart';
import '../core/localization/app_locales.dart';
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

  // Native Stripe setup is local and fast, so mobile keeps doing it up
  // front. On web it downloads Stripe.js, which only checkout needs — warm
  // it up in the background once the app is showing instead of delaying
  // the first frame (payment still awaits it via `StripeSetup.ensureReady`).
  if (kIsWeb) {
    unawaited(
      Future<void>.delayed(const Duration(seconds: 4), StripeSetup.ensureReady).catchError((_) {}),
    );
  } else {
    await StripeSetup.ensureReady();
  }

  // Must be called exactly once, before any other GoogleSignIn method, for
  // the app's whole lifetime — this is the one correct place for that.
  // Skipped on web: web signs in via FirebaseAuth.signInWithPopup instead
  // (the google_sign_in package's web implementation requires its own
  // rendered button widget and doesn't support the imperative flow used on
  // Android/iOS), so initializing it there is unnecessary.
  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }

  configureDependencies();

  // Without this, Android applies its own contrast scrim to the status bar,
  // which reads as a faint grey band against our all-white header — this
  // makes both system bars transparent and matches their icons to the app's
  // light theme instead.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
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
