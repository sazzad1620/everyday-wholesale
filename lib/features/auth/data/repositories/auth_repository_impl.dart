import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDatasource);

  final AuthRemoteDatasource _remoteDatasource;

  @override
  Stream<UserEntity?> get authStateChanges => _remoteDatasource.authStateChanges;

  @override
  Future<Either<Failure, UserEntity>> signIn({required String email, required String password}) async {
    try {
      return Right(await _remoteDatasource.signIn(email: email, password: password));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      return Right(await _remoteDatasource.signUp(name: name, email: email, password: password));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> sendPhoneOtp(String phoneNumber) async {
    try {
      return Right(await _remoteDatasource.sendPhoneOtp(phoneNumber));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    try {
      return Right(await _remoteDatasource.verifyPhoneOtp(verificationId: verificationId, smsCode: smsCode, name: name));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> isPhoneRegistered(String phoneNumber) async {
    try {
      return Right(await _remoteDatasource.isPhoneRegistered(phoneNumber));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remoteDatasource.signOut();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
