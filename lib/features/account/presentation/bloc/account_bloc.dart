import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'account_event.dart';
import 'account_state.dart';

/// Mock-only session state — no real auth exists yet. "Log In"/"Sign Up"
/// flip to a fixed mock signed-in state to preview both views; wire this up
/// to Firebase Auth in the backend-integration phase. Registered
/// `@lazySingleton` (not the usual per-page `@injectable`) so the header
/// greeting and the account sheet always agree on the current state.
@lazySingleton
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc() : super(const AccountState.guest()) {
    on<AccountLoggedIn>((event, emit) => emit(const AccountState(isLoggedIn: true)));
    on<AccountLoggedOut>((event, emit) => emit(const AccountState.guest()));
  }
}
