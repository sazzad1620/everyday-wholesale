import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../order/data/models/order_model.dart';
import '../../../order/domain/entities/order_status.dart';

abstract class AdminOrderRemoteDatasource {
  Future<List<OrderModel>> getAllOrders();

  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}

@LazySingleton(as: AdminOrderRemoteDatasource)
class AdminOrderRemoteDatasourceImpl implements AdminOrderRemoteDatasource {
  AdminOrderRemoteDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  static const _ordersCollection = 'orders';

  @override
  Future<List<OrderModel>> getAllOrders() async {
    // Sorted client-side, matching `OrderRemoteDatasourceImpl.getOrderHistory`
    // — no composite index set up, and the admin list isn't large enough yet
    // to need one.
    final snapshot = await _firestore.collection(_ordersCollection).get();
    final orders = snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), id: doc.id)).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _firestore.collection(_ordersCollection).doc(orderId).update({'status': status.name});
}
