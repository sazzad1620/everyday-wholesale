import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  const DashboardStatsEntity({
    required this.totalProducts,
    required this.totalCategories,
    required this.totalOrders,
    required this.pendingOrders,
  });

  final int totalProducts;
  final int totalCategories;
  final int totalOrders;
  final int pendingOrders;

  @override
  List<Object?> get props => [totalProducts, totalCategories, totalOrders, pendingOrders];
}
