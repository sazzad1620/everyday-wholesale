import 'package:equatable/equatable.dart';

import '../../../../home/domain/entities/category_entity.dart';

abstract class CategoryFormEvent extends Equatable {
  const CategoryFormEvent();

  @override
  List<Object?> get props => [];
}

class CategoryFormSubmitted extends CategoryFormEvent {
  const CategoryFormSubmitted({required this.category, required this.isEditing});

  final CategoryEntity category;
  final bool isEditing;

  @override
  List<Object?> get props => [category, isEditing];
}
