import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Emits the signed-in user (or `null` when signed out) immediately on
  /// subscription and again on every change — the single source of truth
  /// [AccountBloc] stays synced to, including sign-outs from token expiry.
  Stream<UserEntity?> get authStateChanges;

  Future<Either<Failure, UserEntity>> signIn({required String email, required String password});

  Future<Either<Failure, UserEntity>> signUp({required String name, required String email, required String password});

  Future<Either<Failure, Unit>> signOut();
}
