import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/di/injection_container.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
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
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const EverydayWholesaleApp(),
    ),
  );
}
