import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/cart_totals.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

class PlaceOrderParams extends Equatable {
  const PlaceOrderParams({
    required this.cartItems,
    required this.totals,
    required this.paymentMethod,
    required this.addressLine,
    required this.addressPhone,
    required this.addressReceiverName,
  });

  final List<CartItemEntity> cartItems;
  final CartTotals totals;
  final String paymentMethod;
  final String addressLine;
  final String addressPhone;
  final String addressReceiverName;

  @override
  List<Object?> get props => [cartItems, totals, paymentMethod, addressLine, addressPhone, addressReceiverName];
}

@injectable
class PlaceOrderUseCase extends UseCase<OrderEntity, PlaceOrderParams> {
  PlaceOrderUseCase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Either<Failure, OrderEntity>> call(PlaceOrderParams params) {
    return _repository.placeOrder(
      cartItems: params.cartItems,
      totals: params.totals,
      paymentMethod: params.paymentMethod,
      addressLine: params.addressLine,
      addressPhone: params.addressPhone,
      addressReceiverName: params.addressReceiverName,
    );
  }
}
