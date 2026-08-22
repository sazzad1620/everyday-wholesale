import 'package:equatable/equatable.dart';

class AccountState extends Equatable {
  const AccountState({required this.isLoggedIn});

  const AccountState.guest() : this(isLoggedIn: false);

  final bool isLoggedIn;

  @override
  List<Object?> get props => [isLoggedIn];
}
