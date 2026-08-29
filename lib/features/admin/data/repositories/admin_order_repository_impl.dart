import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/entities/order_status.dart';
import '../../domain/repositories/admin_order_repository.dart';
import '../datasources/admin_order_remote_datasource.dart';

@LazySingleton(as: AdminOrderRepository)
class AdminOrderRepositoryImpl implements AdminOrderRepository {
  AdminOrderRepositoryImpl(this._datasource);

  final AdminOrderRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<OrderEntity>>> getAllOrders() async {
    try {
      return Right(await _datasource.getAllOrders());
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _datasource.updateOrderStatus(orderId, status);
      return const Right(null);
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
