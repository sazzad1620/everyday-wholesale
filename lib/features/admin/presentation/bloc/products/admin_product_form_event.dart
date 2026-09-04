import 'package:equatable/equatable.dart';

import '../../../../product/domain/entities/product_entity.dart';

abstract class AdminProductFormEvent extends Equatable {
  const AdminProductFormEvent();

  @override
  List<Object?> get props => [];
}

class AdminProductFormSubmitted extends AdminProductFormEvent {
  const AdminProductFormSubmitted({required this.product, required this.isEditing});

  final ProductEntity product;
  final bool isEditing;

  @override
  List<Object?> get props => [product, isEditing];
}
