import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

abstract class AppReadinessRepository {
  Future<Either<Failure, bool>> checkAppReady();
}
