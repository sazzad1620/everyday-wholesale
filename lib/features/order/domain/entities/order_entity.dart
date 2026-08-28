import 'package:equatable/equatable.dart';

import 'order_item_entity.dart';
import 'order_status.dart';

class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.customerId,
    required this.items,
    required this.itemTotal,
    required this.discount,
    required this.tax,
    required this.shippingFee,
    required this.voucherDeduction,
    required this.subTotal,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.addressLine,
    required this.addressPhone,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final List<OrderItemEntity> items;
  final int itemTotal;
  final int discount;
  final int tax;
  final int shippingFee;
  final int voucherDeduction;
  final int subTotal;
  final int total;
  final OrderStatus status;
  final String paymentMethod;
  final String addressLine;
  final String addressPhone;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    customerId,
    items,
    itemTotal,
    discount,
    tax,
    shippingFee,
    voucherDeduction,
    subTotal,
    total,
    status,
    paymentMethod,
    addressLine,
    addressPhone,
    createdAt,
  ];
}
