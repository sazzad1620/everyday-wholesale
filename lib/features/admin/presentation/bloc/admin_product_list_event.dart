import 'package:equatable/equatable.dart';

abstract class AdminProductListEvent extends Equatable {
  const AdminProductListEvent();

  @override
  List<Object?> get props => [];
}

class AdminProductListRequested extends AdminProductListEvent {
  const AdminProductListRequested();
}

class AdminProductDeleteRequested extends AdminProductListEvent {
  const AdminProductDeleteRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}
