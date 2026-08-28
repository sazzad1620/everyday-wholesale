import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDatasource {
  Stream<UserModel?> get authStateChanges;

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({required String name, required String email, required String password});

  Future<void> signOut();
}

@LazySingleton(as: AuthRemoteDatasource)
class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  AuthRemoteDatasourceImpl(this._firebaseAuth, this._firestore);

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';

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
      throw AuthException(_messageForCode(e.code));
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
      throw AuthException(_messageForCode(e.code));
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  /// Reads the `users/{uid}` doc for role/name; falls back to the Auth
  /// profile if the doc is somehow missing (shouldn't happen — created on
  /// sign-up — but a doc read failing the app open is worse than a stale
  /// default role).
  Future<UserModel> _fetchUserDoc(User user) async {
    final snapshot = await _firestore.collection(_usersCollection).doc(user.uid).get();
    if (snapshot.exists) {
      return UserModel.fromMap(snapshot.data()!, uid: user.uid);
    }
    return UserModel(uid: user.uid, email: user.email ?? '', name: user.displayName ?? '');
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'network-request-failed':
        return 'Network error — please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts — please wait a moment and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
