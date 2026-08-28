import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

class AccountState extends Equatable {
  const AccountState({this.user, this.isSubmitting = false, this.errorMessage});

  const AccountState.guest() : this();

  final UserEntity? user;

  /// True while a sign-in/sign-up/sign-out call is in flight — drives the
  /// loading spinner on the dialogs' submit button.
  final bool isSubmitting;

  /// Set on a failed sign-in/sign-up attempt; cleared on the next attempt or
  /// once it succeeds. Not persisted across [AccountAuthStateChanged].
  final String? errorMessage;

  bool get isLoggedIn => user != null;

  @override
  List<Object?> get props => [user, isSubmitting, errorMessage];
}
