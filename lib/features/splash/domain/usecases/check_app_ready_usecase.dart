import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/app_readiness_repository.dart';

@injectable
class CheckAppReadyUseCase extends UseCase<bool, NoParams> {
  CheckAppReadyUseCase(this._repository);

  final AppReadinessRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return _repository.checkAppReady();
  }
}
