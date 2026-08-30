import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/cart_totals.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_model.dart';

@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._datasource, this._firebaseAuth);

  final OrderRemoteDatasource _datasource;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<Either<Failure, OrderEntity>> placeOrder({
    required List<CartItemEntity> cartItems,
    required CartTotals totals,
    required String paymentMethod,
    required String addressLine,
    required String addressPhone,
    required String addressReceiverName,
  }) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return const Left(AuthFailure('Please sign in to place an order.'));

    try {
      final order = OrderModel(
        id: '',
        customerId: uid,
        items: cartItems
            .map(
              (item) => OrderItemEntity(
                productId: item.product.id,
                name: item.product.name,
                price: item.product.price,
                unit: item.product.unit,
                quantity: item.quantity,
                imageUrl: item.product.imageUrl,
              ),
            )
            .toList(),
        itemTotal: totals.productTotal,
        discount: totals.discount,
        tax: totals.tax,
        shippingFee: totals.shippingFee,
        voucherDeduction: totals.voucherDeduction,
        subTotal: totals.subTotal,
        total: totals.total,
        status: OrderStatus.pending,
        paymentMethod: paymentMethod,
        addressLine: addressLine,
        addressPhone: addressPhone,
        addressReceiverName: addressReceiverName,
        createdAt: DateTime.now(),
      );
      return Right(await _datasource.placeOrder(order));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrderHistory() async {
    try {
      return Right(await _datasource.getOrderHistory());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }
}
