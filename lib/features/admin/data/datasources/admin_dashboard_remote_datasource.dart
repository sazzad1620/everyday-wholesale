import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/dashboard_stats_entity.dart';

abstract class AdminDashboardRemoteDatasource {
  Future<DashboardStatsEntity> getDashboardStats();
}

@LazySingleton(as: AdminDashboardRemoteDatasource)
class AdminDashboardRemoteDatasourceImpl implements AdminDashboardRemoteDatasource {
  AdminDashboardRemoteDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<DashboardStatsEntity> getDashboardStats() async {
    // Aggregate `.count()` queries — cheap, don't fetch/scan full documents.
    final results = await Future.wait([
      _firestore.collection('products').count().get(),
      _firestore.collection('categories').count().get(),
      _firestore.collection('orders').count().get(),
      _firestore.collection('orders').where('status', isEqualTo: 'pending').count().get(),
    ]);

    return DashboardStatsEntity(
      totalProducts: results[0].count ?? 0,
      totalCategories: results[1].count ?? 0,
      totalOrders: results[2].count ?? 0,
      pendingOrders: results[3].count ?? 0,
    );
  }
}
