import 'package:equatable/equatable.dart';

import '../../domain/entities/address_entity.dart';
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

class AccountPhoneOtpRequested extends AccountEvent {
  const AccountPhoneOtpRequested(this.phoneNumber, {required this.isSignUp});

  final String phoneNumber;

  /// True from the sign-up dialog, false from sign-in — only sign-in
  /// pre-checks whether the number is registered before sending an OTP.
  final bool isSignUp;

  @override
  List<Object?> get props => [phoneNumber, isSignUp];
}

class AccountPhoneOtpVerifyRequested extends AccountEvent {
  const AccountPhoneOtpVerifyRequested({required this.verificationId, required this.smsCode, this.name});

  final String verificationId;
  final String smsCode;

  /// Only passed by the sign-up dialog's phone tab.
  final String? name;

  @override
  List<Object?> get props => [verificationId, smsCode, name];
}

class AccountGoogleSignInRequested extends AccountEvent {
  const AccountGoogleSignInRequested();
}

class AccountPasswordResetRequested extends AccountEvent {
  const AccountPasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AccountAddressUpdateRequested extends AccountEvent {
  const AccountAddressUpdateRequested(this.address);

  final AddressEntity address;

  @override
  List<Object?> get props => [address];
}

class AccountNameUpdateRequested extends AccountEvent {
  const AccountNameUpdateRequested(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}
