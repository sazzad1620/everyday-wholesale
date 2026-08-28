import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

@injectable
class SendPasswordResetEmailUseCase extends UseCase<Unit, String> {
  SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String email) => _repository.sendPasswordResetEmail(email);
}
