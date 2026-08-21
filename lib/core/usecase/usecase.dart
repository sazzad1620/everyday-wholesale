import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';

abstract class UseCase<ReturnType, Params> {
  const UseCase();

  Future<Either<Failure, ReturnType>> call(Params params);
}

class NoParams {
  const NoParams();
}
