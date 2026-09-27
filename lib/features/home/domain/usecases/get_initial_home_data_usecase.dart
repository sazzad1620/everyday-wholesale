import 'package:injectable/injectable.dart';

import '../entities/initial_home_data.dart';
import '../repositories/home_repository.dart';

/// The home data embedded in the server-rendered page (web only), or null.
/// Synchronous on purpose — the whole point is painting it on the first
/// frame, before any request. Callers still refresh from Firestore.
@injectable
class GetInitialHomeDataUseCase {
  GetInitialHomeDataUseCase(this._repository);

  final HomeRepository _repository;

  InitialHomeData? call() => _repository.initialHomeData();
}
