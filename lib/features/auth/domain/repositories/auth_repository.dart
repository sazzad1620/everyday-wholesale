import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/address_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Emits the signed-in user (or `null` when signed out) immediately on
  /// subscription and again on every change — the single source of truth
  /// [AccountBloc] stays synced to, including sign-outs from token expiry.
  Stream<UserEntity?> get authStateChanges;

  Future<Either<Failure, UserEntity>> signIn({required String email, required String password});

  Future<Either<Failure, UserEntity>> signUp({required String name, required String email, required String password});

  /// Sends an SMS verification code to [phoneNumber] (E.164 format, e.g.
  /// `+8801XXXXXXXXX`). Returns Firebase's `verificationId`, which must be
  /// passed to [verifyPhoneOtp] along with the code the user receives.
  Future<Either<Failure, String>> sendPhoneOtp(String phoneNumber);

  /// Completes a phone sign-in/sign-up. [name] is only used the first time a
  /// given phone number signs in (creating its `users/{uid}` doc); ignored
  /// on later sign-ins where the doc already exists.
  Future<Either<Failure, UserEntity>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  });

  Future<Either<Failure, bool>> isPhoneRegistered(String phoneNumber);

  /// One unified flow — signs in if the Google account already has a
  /// `users/{uid}` doc, creates it (name/email from the Google profile)
  /// otherwise. No separate sign-in/sign-up split, matching how every app
  /// using Google Sign-In behaves.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Firebase sends the reset email and hosts the "enter a new password"
  /// page itself once the user clicks the link — nothing else to build.
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  Future<Either<Failure, Unit>> signOut();

  /// Overwrites the signed-in user's one saved delivery address.
  Future<Either<Failure, Unit>> updateAddress({required String uid, required AddressEntity address});

  /// Updates the signed-in user's display name — the only profile field
  /// that's actually editable (email/phone are tied to the sign-in
  /// credential itself and shown read-only instead).
  Future<Either<Failure, Unit>> updateName({required String uid, required String name});
}
