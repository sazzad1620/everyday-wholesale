import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class IsPhoneRegisteredUseCase extends UseCase<bool, String> {
  IsPhoneRegisteredUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, bool>> call(String phoneNumber) => _repository.isPhoneRegistered(phoneNumber);
}
