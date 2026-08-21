import 'package:injectable/injectable.dart';

abstract class AppReadinessLocalDatasource {
  Future<bool> checkAppReady();
}

@LazySingleton(as: AppReadinessLocalDatasource)
class AppReadinessLocalDatasourceImpl implements AppReadinessLocalDatasource {
  @override
  Future<bool> checkAppReady() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return true;
  }
}
