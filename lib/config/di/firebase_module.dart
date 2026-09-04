import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  // `instanceFor(region:)`, not the plain `.instance` default (`us-central1`)
  // — the Cloud Functions themselves are deployed to `asia-northeast1` (see
  // docs/PAYMENTS_PLAN.md), and a mismatched region here would make every
  // callable lookup fail as "not found".
  @lazySingleton
  FirebaseFunctions get firebaseFunctions => FirebaseFunctions.instanceFor(region: 'asia-northeast1');
}
