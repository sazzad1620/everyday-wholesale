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

/// The admin typed in (or cleared) the search box above the product list.
class AdminProductSearchChanged extends AdminProductListEvent {
  const AdminProductSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
