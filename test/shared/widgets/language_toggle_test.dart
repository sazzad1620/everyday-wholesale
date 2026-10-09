import 'package:easy_localization/easy_localization.dart';
import 'package:everyday_wholesale/config/di/injection_container.dart';
import 'package:everyday_wholesale/core/localization/app_locales.dart';
import 'package:everyday_wholesale/features/auth/domain/entities/user_entity.dart';
import 'package:everyday_wholesale/features/auth/domain/repositories/auth_repository.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/is_phone_registered_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/update_address_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/update_name_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/update_preferred_locale_usecase.dart';
import 'package:everyday_wholesale/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:everyday_wholesale/features/auth/presentation/bloc/account_bloc.dart';
import 'package:everyday_wholesale/shared/widgets/language/language_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoAuth implements AuthRepository {
  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app({double textScale = 1}) => EasyLocalization(
  supportedLocales: AppLocales.supported,
  path: 'assets/translations',
  fallbackLocale: AppLocales.fallback,
  startLocale: AppLocales.en,
  useOnlyLangCode: true,
  saveLocale: false,
  child: Builder(
    builder: (context) => MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const Scaffold(body: Center(child: LanguageToggle())),
    ),
  ),
);

/// The language switch is a small, quiet control: a ~120 px × 30 px track
/// showing the full names "English" and "日本語"; the active half is a little
/// wider and the track never changes size while it animates.
/// One test with one mounted app (easy_localization's translation load only
/// completes in the first test's fake-async zone).
void main() {
  setUpAll(() {
    final repo = _NoAuth();
    getIt.registerSingleton<AccountBloc>(
      AccountBloc(
        repo,
        SignInUseCase(repo),
        SignUpUseCase(repo),
        SignOutUseCase(repo),
        SendPhoneOtpUseCase(repo),
        VerifyPhoneOtpUseCase(repo),
        IsPhoneRegisteredUseCase(repo),
        SignInWithGoogleUseCase(repo),
        SendPasswordResetEmailUseCase(repo),
        UpdateAddressUseCase(repo),
        UpdateNameUseCase(repo),
        UpdatePreferredLocaleUseCase(repo),
      ),
    );
  });

  testWidgets('compact, morphing halves, no overflow at any text size, and a tap on the other half switches language', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 300);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    for (var i = 0; i < 100 && find.text('English').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(find.text('English'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Small: the whole control (track + invisible touch padding) is under
    // 120 × 48, and the visible track is the 30-px-high part.
    final size = tester.getSize(find.byType(LanguageToggle));
    expect(size.width, lessThanOrEqualTo(120));
    expect(size.height, lessThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(44), reason: 'comfortable touch target');

    final box = tester.getRect(find.byType(LanguageToggle));

    // The active half is the wider one; the track as a whole never resizes.
    final segments = find.descendant(of: find.byType(LanguageToggle), matching: find.byType(AnimatedContainer));
    expect(segments, findsNWidgets(2));
    double width(int i) => tester.getSize(segments.at(i)).width;
    expect(width(0), greaterThan(width(1)), reason: 'English is active, so its half is the wider one');
    final totalWidth = width(0) + width(1);

    // Tap the right half (even on the invisible padding above the track).
    final context = tester.element(find.byType(LanguageToggle));
    expect(context.locale, AppLocales.en);
    await tester.tapAt(Offset(box.right - 12, box.top + 3));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.element(find.byType(LanguageToggle)).locale, AppLocales.ja);
    // The wide half moved to 日本語 — and the two halves still add up to the same width.
    expect(width(1), greaterThan(width(0)));
    expect(width(0) + width(1), closeTo(totalWidth, 0.5));

    // And back with the left half.
    await tester.tapAt(Offset(box.left + 12, box.center.dy));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.element(find.byType(LanguageToggle)).locale, AppLocales.en);

    // Largest accessibility text: labels shrink, nothing overflows or wraps.
    await tester.pumpWidget(_app(textScale: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(LanguageToggle)).width, lessThanOrEqualTo(120));
  });
}
