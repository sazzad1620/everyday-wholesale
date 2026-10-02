import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Web switches pages instantly, like any website; Flutter's default here
/// was the phone-style "zoom in" transition on every navigation.
class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

abstract final class AppTheme {
  /// Web: no page animation. Android/iOS apps: each platform's native
  /// transition (Flutter's defaults), which is what phone users expect.
  static const PageTransitionsTheme _pageTransitions = kIsWeb
      ? PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoPageTransitionsBuilder(),
            TargetPlatform.iOS: _NoPageTransitionsBuilder(),
            TargetPlatform.macOS: _NoPageTransitionsBuilder(),
            TargetPlatform.windows: _NoPageTransitionsBuilder(),
            TargetPlatform.linux: _NoPageTransitionsBuilder(),
            TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
          },
        )
      : PageTransitionsTheme();

  /// Web: no Material "ripple" (a touch-screen effect that looks odd under a
  /// mouse) — buttons and tiles keep their hover highlight, hand cursor and
  /// a brief press shade instead, like a normal website. The apps keep the
  /// ripple, the standard touch feedback on phones.
  static final InteractiveInkFeatureFactory? _splashFactory = kIsWeb ? NoSplash.splashFactory : null;

  /// [bodyFont] is the locale's body face (see `AppLocales.bodyFontFor`) —
  /// `null` keeps the platform default. Applied through `ThemeData.fontFamily`
  /// rather than baked into [AppTextStyles], so every `const` style below and
  /// every `AppTextStyles.x.copyWith(...)` at call sites inherits it via
  /// `DefaultTextStyle` without touching a single widget.
  static ThemeData light({TextStyle? bodyFont}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: bodyFont?.fontFamily,
        fontFamilyFallback: bodyFont?.fontFamilyFallback,
        pageTransitionsTheme: _pageTransitions,
        splashFactory: _splashFactory,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineSmall: AppTextStyles.headline,
          titleMedium: AppTextStyles.title,
          // `bodyLarge` is what TextField/TextFormField actually use for
          // their input/hint text when no explicit `style:` is set — left
          // at Material's own default before, so every plain text field in
          // the app rendered a couple points larger than the app's own
          // 14sp `AppTextStyles.body` by accident, not by design.
          bodyLarge: AppTextStyles.body,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
        ),
      );

  static ThemeData dark({TextStyle? bodyFont}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: bodyFont?.fontFamily,
        fontFamilyFallback: bodyFont?.fontFamilyFallback,
        pageTransitionsTheme: _pageTransitions,
        splashFactory: _splashFactory,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineSmall: AppTextStyles.headline,
          titleMedium: AppTextStyles.title,
          bodyLarge: AppTextStyles.body,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
        ),
      );
}
