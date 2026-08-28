import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

/// Exposes the already-initialized Firebase SDK singletons (see
/// `Firebase.initializeApp()` in `app/bootstrap.dart`, which runs before
/// `configureDependencies()`) to the DI graph, so features depend on
/// injected instances rather than calling `.instance` directly.
@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseFirestore get firebaseFirestore => FirebaseFirestore.instance;

  @lazySingleton
  FirebaseStorage get firebaseStorage => FirebaseStorage.instance;
}
