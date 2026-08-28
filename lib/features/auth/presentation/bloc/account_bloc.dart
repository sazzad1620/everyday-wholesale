import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/is_phone_registered_usecase.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';
import 'account_event.dart';
import 'account_state.dart';

/// Registered `@lazySingleton` (not the usual per-page `@injectable`) so the
/// header greeting and every dialog/page agree on the same session state.
/// Stays in sync with Firebase Auth via [AuthRepository.authStateChanges],
/// which also catches external sign-outs (e.g. token expiry) — not just
/// ones this bloc itself triggered.
@lazySingleton
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc(
    this._authRepository,
    this._signInUseCase,
    this._signUpUseCase,
    this._signOutUseCase,
    this._sendPhoneOtpUseCase,
    this._verifyPhoneOtpUseCase,
    this._isPhoneRegisteredUseCase,
    this._signInWithGoogleUseCase,
  ) : super(const AccountState.guest()) {
    on<AccountAuthStateChanged>((event, emit) => emit(AccountState(user: event.user)));
    on<AccountSignInRequested>(_onSignInRequested);
    on<AccountSignUpRequested>(_onSignUpRequested);
    on<AccountSignOutRequested>(_onSignOutRequested);
    on<AccountPhoneOtpRequested>(_onPhoneOtpRequested);
    on<AccountPhoneOtpVerifyRequested>(_onPhoneOtpVerifyRequested);
    on<AccountGoogleSignInRequested>(_onGoogleSignInRequested);

    _authSubscription = _authRepository.authStateChanges.listen((user) => add(AccountAuthStateChanged(user)));
  }

  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final SendPhoneOtpUseCase _sendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase _verifyPhoneOtpUseCase;
  final IsPhoneRegisteredUseCase _isPhoneRegisteredUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;

  late final StreamSubscription<UserEntity?> _authSubscription;

  Future<void> _onSignInRequested(AccountSignInRequested event, Emitter<AccountState> emit) async {
    emit(AccountState(user: state.user, isSubmitting: true));
    final result = await _signInUseCase(SignInParams(email: event.email, password: event.password));
    result.match(
      (failure) => emit(AccountState(user: state.user, errorMessage: failure.message)),
      (user) => emit(AccountState(user: user)),
    );
  }

  Future<void> _onSignUpRequested(AccountSignUpRequested event, Emitter<AccountState> emit) async {
    emit(AccountState(user: state.user, isSubmitting: true));
    final result = await _signUpUseCase(
      SignUpParams(name: event.name, email: event.email, password: event.password),
    );
    result.match(
      (failure) => emit(AccountState(user: state.user, errorMessage: failure.message)),
      (user) => emit(AccountState(user: user)),
    );
  }

  Future<void> _onSignOutRequested(AccountSignOutRequested event, Emitter<AccountState> emit) async {
    emit(AccountState(user: state.user, isSubmitting: true));
    final result = await _signOutUseCase(const NoParams());
    result.match(
      (failure) => emit(AccountState(user: state.user, errorMessage: failure.message)),
      (_) => emit(const AccountState.guest()),
    );
  }

  Future<void> _onPhoneOtpRequested(AccountPhoneOtpRequested event, Emitter<AccountState> emit) async {
    emit(AccountState(user: state.user, isSubmitting: true));

    if (!event.isSignUp) {
      final registeredResult = await _isPhoneRegisteredUseCase(event.phoneNumber);
      // If the check itself fails (e.g. network), fail open — still attempt
      // the send rather than blocking sign-in on an unrelated hiccup; the
      // datasource's post-verify check is the authoritative backstop either
      // way, so a real "no account" case is never missed even if this
      // pre-check silently fails.
      final isRegistered = registeredResult.getOrElse((_) => true);
      if (!isRegistered) {
        emit(
          AccountState(
            user: state.user,
            errorMessage: 'No account found for this number. Please sign up first.',
          ),
        );
        return;
      }
    }

    final result = await _sendPhoneOtpUseCase(event.phoneNumber);
    result.match(
      (failure) => emit(AccountState(user: state.user, errorMessage: failure.message)),
      (verificationId) => emit(AccountState(user: state.user, phoneVerificationId: verificationId)),
    );
  }

  Future<void> _onPhoneOtpVerifyRequested(AccountPhoneOtpVerifyRequested event, Emitter<AccountState> emit) async {
    emit(AccountState(user: state.user, isSubmitting: true, phoneVerificationId: state.phoneVerificationId));
    final result = await _verifyPhoneOtpUseCase(
      VerifyPhoneOtpParams(verificationId: event.verificationId, smsCode: event.smsCode, name: event.name),
    );
    result.match(
      (failure) => emit(
        AccountState(user: state.user, errorMessage: failure.message, phoneVerificationId: state.phoneVerificationId),
      ),
      (user) => emit(AccountState(user: user)),
    );
  }

  Future<void> _onGoogleSignInRequested(AccountGoogleSignInRequested event, Emitter<AccountState> emit) async {
    emit(AccountState(user: state.user, isSubmitting: true));
    final result = await _signInWithGoogleUseCase(const NoParams());
    result.match(
      (failure) => emit(AccountState(user: state.user, errorMessage: failure.message)),
      (user) => emit(AccountState(user: user)),
    );
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
