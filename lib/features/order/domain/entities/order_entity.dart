import 'package:equatable/equatable.dart';

import 'order_item_entity.dart';
import 'order_status.dart';
import 'payment_status.dart';

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
    this.addressReceiverName,
    this.paymentStatus = PaymentStatus.unpaid,
    this.stripePaymentIntentId,
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

  /// Split out from [addressLine] so the receiver's name can be shown on its
  /// own line instead of glued onto the front of the address text. Null for
  /// orders placed before this field existed — those keep showing the old
  /// combined [addressLine] as-is (it already had the name baked in).
  final String? addressReceiverName;

  /// Written `unpaid` by the client at order creation; only ever flipped to
  /// `paid`/`failed` server-side (see [PaymentStatus]'s own doc comment).
  final PaymentStatus paymentStatus;

  /// Set by the `createPaymentIntent` Cloud Function once a PaymentIntent
  /// exists for this order — null until then, and for any order placed
  /// before Stripe payments existed.
  final String? stripePaymentIntentId;

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
    addressReceiverName,
    paymentStatus,
    stripePaymentIntentId,
  ];
}
