import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../home/domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import 'category_list_event.dart';
import 'category_list_state.dart';

@injectable
class CategoryListBloc extends Bloc<CategoryListEvent, CategoryListState> {
  CategoryListBloc(this._getCategoriesUseCase, this._deleteCategoryUseCase) : super(const CategoryListState()) {
    on<CategoryListRequested>(_onRequested);
    on<CategoryDeleteRequested>(_onDeleteRequested);
  }

  final GetCategoriesUseCase _getCategoriesUseCase;
  final DeleteCategoryUseCase _deleteCategoryUseCase;

  Future<void> _onRequested(CategoryListRequested event, Emitter<CategoryListState> emit) async {
    emit(const CategoryListState(isLoading: true));
    final result = await _getCategoriesUseCase(const NoParams());
    result.match(
      (failure) => emit(CategoryListState(errorMessage: failure.message)),
      (categories) => emit(CategoryListState(categories: categories)),
    );
  }

  Future<void> _onDeleteRequested(CategoryDeleteRequested event, Emitter<CategoryListState> emit) async {
    emit(CategoryListState(categories: state.categories, isDeleting: true));
    final result = await _deleteCategoryUseCase(event.categoryId);
    await result.match(
      (failure) async => emit(CategoryListState(categories: state.categories, errorMessage: failure.message)),
      (_) async => _onRequested(const CategoryListRequested(), emit),
    );
  }
}
