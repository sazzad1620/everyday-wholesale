import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_status.dart';
import 'order_item_model.dart';

/// Mirrors an `orders/{orderId}` Firestore document. `id` is the document
/// ID, not a stored field.
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.customerId,
    required super.items,
    required super.itemTotal,
    required super.discount,
    required super.tax,
    required super.shippingFee,
    required super.voucherDeduction,
    required super.subTotal,
    required super.total,
    required super.status,
    required super.paymentMethod,
    required super.addressLine,
    required super.addressPhone,
    required super.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, {required String id}) {
    final rawItems = map['items'] as List<dynamic>? ?? const [];
    final createdAtValue = map['createdAt'];
    return OrderModel(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      items: rawItems.map((raw) => OrderItemModel.fromMap(Map<String, dynamic>.from(raw as Map))).toList(),
      itemTotal: (map['itemTotal'] as num?)?.toInt() ?? 0,
      discount: (map['discount'] as num?)?.toInt() ?? 0,
      tax: (map['tax'] as num?)?.toInt() ?? 0,
      shippingFee: (map['shippingFee'] as num?)?.toInt() ?? 0,
      voucherDeduction: (map['voucherDeduction'] as num?)?.toInt() ?? 0,
      subTotal: (map['subTotal'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      status: OrderStatusX.parse(map['status'] as String? ?? 'pending'),
      paymentMethod: map['paymentMethod'] as String? ?? '',
      addressLine: map['addressLine'] as String? ?? '',
      addressPhone: map['addressPhone'] as String? ?? '',
      // `createdAt` is only a real Timestamp once Firestore has resolved the
      // server-side value on a subsequent read; immediately after `add()` it
      // may still be null, so fall back to "now" for that first return.
      createdAt: createdAtValue is Timestamp ? createdAtValue.toDate() : DateTime.now(),
    );
  }

  /// `createdAt` deliberately isn't included — set via `FieldValue.serverTimestamp()`
  /// at write time instead, so it's added directly in the datasource's write call.
  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'items': items
        .map((i) => OrderItemModel(productId: i.productId, name: i.name, price: i.price, unit: i.unit, quantity: i.quantity, imageUrl: i.imageUrl).toMap())
        .toList(),
    'itemTotal': itemTotal,
    'discount': discount,
    'tax': tax,
    'shippingFee': shippingFee,
    'voucherDeduction': voucherDeduction,
    'subTotal': subTotal,
    'total': total,
    'status': status.name,
    'paymentMethod': paymentMethod,
    'addressLine': addressLine,
    'addressPhone': addressPhone,
  };
}
