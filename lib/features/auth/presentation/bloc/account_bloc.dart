import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import 'account_event.dart';
import 'account_state.dart';

/// Registered `@lazySingleton` (not the usual per-page `@injectable`) so the
/// header greeting and every dialog/page agree on the same session state.
/// Stays in sync with Firebase Auth via [AuthRepository.authStateChanges],
/// which also catches external sign-outs (e.g. token expiry) — not just
/// ones this bloc itself triggered.
@lazySingleton
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc(this._authRepository, this._signInUseCase, this._signUpUseCase, this._signOutUseCase)
    : super(const AccountState.guest()) {
    on<AccountAuthStateChanged>((event, emit) => emit(AccountState(user: event.user)));
    on<AccountSignInRequested>(_onSignInRequested);
    on<AccountSignUpRequested>(_onSignUpRequested);
    on<AccountSignOutRequested>(_onSignOutRequested);

    _authSubscription = _authRepository.authStateChanges.listen((user) => add(AccountAuthStateChanged(user)));
  }

  final AuthRepository _authRepository;
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;

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

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
