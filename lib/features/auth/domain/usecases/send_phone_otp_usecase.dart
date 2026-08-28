import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class SendPhoneOtpUseCase extends UseCase<String, String> {
  SendPhoneOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, String>> call(String phoneNumber) => _repository.sendPhoneOtp(phoneNumber);
}
