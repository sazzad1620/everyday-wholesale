import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneOtpParams extends Equatable {
  const VerifyPhoneOtpParams({required this.verificationId, required this.smsCode, this.name});

  final String verificationId;
  final String smsCode;

  /// Only used the first time this phone number signs in (new account).
  final String? name;

  @override
  List<Object?> get props => [verificationId, smsCode, name];
}

@injectable
class VerifyPhoneOtpUseCase extends UseCase<UserEntity, VerifyPhoneOtpParams> {
  VerifyPhoneOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(VerifyPhoneOtpParams params) {
    return _repository.verifyPhoneOtp(verificationId: params.verificationId, smsCode: params.smsCode, name: params.name);
  }
}
