import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_products_by_category_usecase.dart';
import 'product_list_event.dart';
import 'product_list_state.dart';

@injectable
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  ProductListBloc(this._getProductsByCategoryUseCase) : super(const ProductListInitial()) {
    on<ProductListStarted>(_onProductListStarted);
  }

  final GetProductsByCategoryUseCase _getProductsByCategoryUseCase;

  Future<void> _onProductListStarted(ProductListStarted event, Emitter<ProductListState> emit) async {
    emit(const ProductListLoading());

    final result = await _getProductsByCategoryUseCase(
      GetProductsByCategoryParams(categoryId: event.categoryId, subcategoryId: event.subcategoryId),
    );

    result.match(
      (failure) => emit(ProductListError(failure.message)),
      (products) => emit(ProductListLoaded(products)),
    );
  }
}
