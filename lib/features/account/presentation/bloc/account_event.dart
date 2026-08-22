import 'package:equatable/equatable.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class AccountLoggedIn extends AccountEvent {
  const AccountLoggedIn();
}

class AccountLoggedOut extends AccountEvent {
  const AccountLoggedOut();
}
