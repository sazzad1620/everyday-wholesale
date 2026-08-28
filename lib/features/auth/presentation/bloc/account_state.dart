import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

class AccountState extends Equatable {
  const AccountState({this.user, this.isSubmitting = false, this.errorMessage, this.phoneVerificationId});

  const AccountState.guest() : this();

  final UserEntity? user;

  /// True while a sign-in/sign-up/sign-out/phone-otp call is in flight —
  /// drives the loading spinner on the dialogs' submit/send/verify buttons.
  final bool isSubmitting;

  /// Set on a failed sign-in/sign-up/OTP attempt; cleared on the next
  /// attempt or once it succeeds. Not persisted across
  /// [AccountAuthStateChanged].
  final String? errorMessage;

  /// Firebase's verification ID from the most recent [AccountPhoneOtpRequested]
  /// — the dialogs read this to know an OTP was actually sent (moving from
  /// the phone-number step to the code-entry step) and to pass along with
  /// the user-entered code in [AccountPhoneOtpVerifyRequested].
  final String? phoneVerificationId;

  bool get isLoggedIn => user != null;

  @override
  List<Object?> get props => [user, isSubmitting, errorMessage, phoneVerificationId];
}
