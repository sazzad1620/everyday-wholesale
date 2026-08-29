import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

class AccountState extends Equatable {
  const AccountState({
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
    this.phoneVerificationId,
    this.passwordResetEmailSent = false,
    this.addressUpdated = false,
    this.nameUpdated = false,
    this.isInitializing = false,
  });

  const AccountState.guest() : this();

  /// The bloc's actual startup state — [isInitializing] starts true here and
  /// nowhere else, since this is the only state that exists before Firebase
  /// Auth has had a chance to say whether a session is already persisted.
  const AccountState.initial() : this(isInitializing: true);

  final UserEntity? user;

  /// True only for the app's very first [AccountState], before Firebase
  /// Auth's persisted session (if any) has been checked — flips to false
  /// permanently on the first [AccountAuthStateChanged], whether that
  /// resolves to a signed-in user or confirms there's none. Lets a one-time
  /// startup decision (the splash screen routing an already-signed-in admin
  /// straight to `/admin`) tell "haven't checked yet" apart from "checked,
  /// and it's a guest" — [user] being null alone can't distinguish those.
  final bool isInitializing;

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

  /// True for one state right after [AccountPasswordResetRequested] succeeds
  /// — the dialog shows a confirmation toast on this, same as it does for
  /// [phoneVerificationId] becoming non-null. Every other action constructs
  /// a fresh [AccountState] without passing this, so it resets to false on
  /// its own once anything else happens.
  final bool passwordResetEmailSent;

  /// True for one state right after [AccountAddressUpdateRequested]
  /// succeeds — same reset-on-next-action pattern as [passwordResetEmailSent].
  final bool addressUpdated;

  /// True for one state right after [AccountNameUpdateRequested] succeeds —
  /// same reset-on-next-action pattern as [addressUpdated].
  final bool nameUpdated;

  bool get isLoggedIn => user != null;

  @override
  List<Object?> get props => [
    user,
    isSubmitting,
    errorMessage,
    phoneVerificationId,
    passwordResetEmailSent,
    addressUpdated,
    nameUpdated,
    isInitializing,
  ];
}
