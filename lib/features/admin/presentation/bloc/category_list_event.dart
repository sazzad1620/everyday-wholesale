import 'package:equatable/equatable.dart';

abstract class CategoryListEvent extends Equatable {
  const CategoryListEvent();

  @override
  List<Object?> get props => [];
}

class CategoryListRequested extends CategoryListEvent {
  const CategoryListRequested();
}

class CategoryDeleteRequested extends CategoryListEvent {
  const CategoryDeleteRequested(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}
