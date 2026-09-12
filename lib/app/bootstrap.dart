import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../config/di/injection_container.dart';
import '../core/constants/stripe_config.dart';
import '../core/localization/app_locales.dart';
import '../firebase_options.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // `DateFormat` only knows English out of the box — every other locale's
  // month/day names have to be loaded first, and easy_localization doesn't
  // do it for us. Without this, a Japanese-locale `DateFormat` throws.
  await initializeDateFormatting(AppLocales.ja.languageCode);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Stripe.publishableKey = StripeConfig.publishableKey;
  await Stripe.instance.applySettings();

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

  // Fetch+cache the header wordmark's font weights before the first frame,
  // not on first use — otherwise that text paints in the fallback system
  // font and visibly snaps to Oswald (a width change, since Oswald is
  // condensed) once the async download finishes.
  GoogleFonts.oswald(fontWeight: FontWeight.w600);
  GoogleFonts.oswald(fontWeight: FontWeight.w300);
  await GoogleFonts.pendingFonts();

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
