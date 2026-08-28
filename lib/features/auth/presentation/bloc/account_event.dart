import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

/// Fired internally by the [AuthRepository.authStateChanges] subscription —
/// not dispatched directly by UI code. Keeps the bloc in sync with Firebase
/// Auth's own state (including sign-outs from token expiry), not just with
/// actions this bloc itself triggered.
class AccountAuthStateChanged extends AccountEvent {
  const AccountAuthStateChanged(this.user);

  final UserEntity? user;

  @override
  List<Object?> get props => [user];
}

class AccountSignInRequested extends AccountEvent {
  const AccountSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AccountSignUpRequested extends AccountEvent {
  const AccountSignUpRequested({required this.name, required this.email, required this.password});

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

class AccountSignOutRequested extends AccountEvent {
  const AccountSignOutRequested();
}
