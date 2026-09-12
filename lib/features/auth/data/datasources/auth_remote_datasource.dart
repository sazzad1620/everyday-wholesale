import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/address_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDatasource {
  Stream<UserModel?> get authStateChanges;

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({required String name, required String email, required String password});

  Future<String> sendPhoneOtp(String phoneNumber);

  Future<UserModel> verifyPhoneOtp({required String verificationId, required String smsCode, String? name});

  /// Whether [phoneNumber] already has an account — checked before sending
  /// an OTP for a sign-in attempt, so "no account" can be reported without
  /// spending an SMS. Backed by `phone_index`, a minimal collection mapping
  /// phone → uid (not the full `users` doc), since this needs to be publicly
  /// readable pre-auth without exposing any real profile data.
  Future<bool> isPhoneRegistered(String phoneNumber);

  Future<UserModel> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<void> updateAddress(String uid, AddressModel address);

  Future<void> updateName(String uid, String name);

  Future<void> updatePreferredLocale(String uid, String languageCode);
}

@LazySingleton(as: AuthRemoteDatasource)
class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  AuthRemoteDatasourceImpl(this._firebaseAuth, this._firestore);

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';
  static const _phoneIndexCollection = 'phone_index';

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _fetchUserDoc(user);
    });
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) throw const AuthException();
      return _fetchUserDoc(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_keyForCode(e.code));
    }
  }

  @override
  Future<UserModel> signUp({required String name, required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) throw const AuthException();
      await user.updateDisplayName(name);

      final model = UserModel(uid: user.uid, email: email, name: name);
      await _firestore.collection(_usersCollection).doc(user.uid).set(model.toMap());
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_keyForCode(e.code));
    }
  }

  @override
  Future<String> sendPhoneOtp(String phoneNumber) {
    final completer = Completer<String>();
    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      // Instant device-side auto-verification (mainly Android, occasionally).
      // The app's OTP screen always expects a manually-entered code, so this
      // is deliberately a no-op — `codeSent` below still fires and drives
      // the normal flow either way.
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(AuthException(_keyForCode(e.code)));
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  @override
  Future<UserModel> verifyPhoneOtp({required String verificationId, required String smsCode, String? name}) async {
    try {
      final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw const AuthException();

      // Firebase's phone credential succeeds and silently creates an auth
      // user regardless of whether the caller meant "sign in" or "sign up" —
      // `name` being present is how the dialogs tell us which one this was
      // (only the sign-up form has a name field). We enforce the distinction
      // ourselves: sign-in requires an existing profile, sign-up requires
      // there not be one. Either mismatch signs the just-created auth
      // session back out, so it doesn't leak through `authStateChanges`.
      final docRef = _firestore.collection(_usersCollection).doc(user.uid);
      final snapshot = await docRef.get();
      final isSignUp = name != null;

      if (snapshot.exists) {
        if (isSignUp) {
          await _firebaseAuth.signOut();
          throw const AuthException('errors.auth_phone_exists');
        }
        return UserModel.fromMap(snapshot.data()!, uid: user.uid);
      }

      if (!isSignUp) {
        await _firebaseAuth.signOut();
        throw const AuthException('errors.auth_phone_not_found');
      }

      final model = UserModel(uid: user.uid, email: user.email ?? '', name: name, phone: user.phoneNumber);
      await docRef.set(model.toMap());
      if (user.phoneNumber != null) {
        await _firestore.collection(_phoneIndexCollection).doc(user.phoneNumber).set({'uid': user.uid});
      }
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_keyForCode(e.code));
    }
  }

  @override
  Future<bool> isPhoneRegistered(String phoneNumber) async {
    final doc = await _firestore.collection(_phoneIndexCollection).doc(phoneNumber).get();
    return doc.exists;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_keyForCode(e.code));
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final User? user;

      if (kIsWeb) {
        // The google_sign_in package's web implementation requires its own
        // rendered button widget and throws if `.authenticate()` is called
        // imperatively — Firebase's own popup flow avoids that entirely,
        // and lets the button stay a normal custom-styled one like the rest
        // of the app.
        final userCredential = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
        user = userCredential.user;
      } else {
        final account = await GoogleSignIn.instance.authenticate();
        final credential = GoogleAuthProvider.credential(idToken: account.authentication.idToken);
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        user = userCredential.user;
      }
      if (user == null) throw const AuthException();

      final docRef = _firestore.collection(_usersCollection).doc(user.uid);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, uid: user.uid);
      }

      final model = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        phone: user.phoneNumber,
      );
      await docRef.set(model.toMap());
      return model;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_keyForCode(e.code));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('errors.auth_sign_in_cancelled');
      }
      throw const AuthException('errors.auth_google_failed');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // Also clears the cached Google session, so the next sign-in shows the
    // account picker again instead of silently reusing this one.
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }

  @override
  Future<void> updateAddress(String uid, AddressModel address) =>
      _firestore.collection(_usersCollection).doc(uid).update({'address': address.toMap()});

  @override
  Future<void> updateName(String uid, String name) async {
    await _firestore.collection(_usersCollection).doc(uid).update({'name': name});
    // Keeps the Auth profile's displayName in sync with Firestore's copy,
    // same as `signUp` sets it initially — nothing reads Auth's copy today,
    // but there's no reason to let the two silently drift apart.
    await _firebaseAuth.currentUser?.updateDisplayName(name);
  }

  @override
  Future<void> updatePreferredLocale(String uid, String languageCode) async {
    await _firestore.collection(_usersCollection).doc(uid).update({'preferredLocale': languageCode});
  }

  /// Reads the `users/{uid}` doc for role/name; falls back to the Auth
  /// profile if the doc is somehow missing (shouldn't happen — created on
  /// sign-up — but a doc read failing the app open is worse than a stale
  /// default role).
  Future<UserModel> _fetchUserDoc(User user) async {
    final snapshot = await _firestore.collection(_usersCollection).doc(user.uid).get();
    if (snapshot.exists) {
      return UserModel.fromMap(snapshot.data()!, uid: user.uid);
    }
    return UserModel(uid: user.uid, email: user.email ?? '', name: user.displayName ?? '', phone: user.phoneNumber);
  }

  /// Maps a FirebaseAuth error code to an `errors.*` translation key — the
  /// UI resolves it with `.tr()`, so the copy lives in the JSON files, not
  /// here.
  String _keyForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'errors.auth_invalid_email';
      case 'user-disabled':
        return 'errors.auth_user_disabled';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'errors.auth_wrong_credentials';
      case 'email-already-in-use':
        return 'errors.auth_email_in_use';
      case 'weak-password':
        return 'errors.auth_weak_password';
      case 'network-request-failed':
        return 'errors.auth_network';
      case 'too-many-requests':
      case 'quota-exceeded':
        return 'errors.auth_too_many_requests';
      case 'invalid-phone-number':
        return 'errors.auth_invalid_phone';
      case 'invalid-verification-code':
        return 'errors.auth_invalid_code';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'errors.auth_code_expired';
      default:
        return 'errors.auth_generic';
    }
  }
}
