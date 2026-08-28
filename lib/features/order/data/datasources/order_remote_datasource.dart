import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDatasource {
  Future<OrderModel> placeOrder(OrderModel order);

  Future<List<OrderModel>> getOrderHistory();
}

@LazySingleton(as: OrderRemoteDatasource)
class OrderRemoteDatasourceImpl implements OrderRemoteDatasource {
  OrderRemoteDatasourceImpl(this._firestore, this._firebaseAuth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  static const _ordersCollection = 'orders';

  @override
  Future<OrderModel> placeOrder(OrderModel order) async {
    final docRef = await _firestore
        .collection(_ordersCollection)
        .add({...order.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    // `createdAt` resolves to "now" here (see OrderModel.fromMap) rather than
    // re-reading the doc for the exact server value — not worth a second
    // round-trip just for the confirmation screen's immediate display.
    return OrderModel.fromMap(order.toMap(), id: docRef.id);
  }

  @override
  Future<List<OrderModel>> getOrderHistory() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw const AuthException('Please sign in to view your orders.');
    // Sorted client-side rather than via `.orderBy('createdAt')` — combining
    // that with the `customerId` equality filter would need a composite
    // index set up in the Firebase console first; not worth that setup step
    // for what's realistically a short, per-customer list.
    final snapshot = await _firestore.collection(_ordersCollection).where('customerId', isEqualTo: uid).get();
    final orders = snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), id: doc.id)).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }
}
