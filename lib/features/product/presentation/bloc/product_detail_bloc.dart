import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_product_by_id_usecase.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

@injectable
class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc(this._getProductByIdUseCase) : super(const ProductDetailInitial()) {
    on<ProductDetailStarted>(_onProductDetailStarted);
  }

  final GetProductByIdUseCase _getProductByIdUseCase;

  Future<void> _onProductDetailStarted(ProductDetailStarted event, Emitter<ProductDetailState> emit) async {
    emit(const ProductDetailLoading());

    final result = await _getProductByIdUseCase(event.productId);

    result.match(
      (failure) => emit(ProductDetailError(failure.message)),
      (product) => emit(ProductDetailLoaded(product)),
    );
  }
}
