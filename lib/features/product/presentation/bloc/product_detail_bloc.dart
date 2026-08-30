import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../review/domain/entities/review_entity.dart';
import '../../../review/domain/usecases/get_product_reviews_usecase.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

@injectable
class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc(this._getProductByIdUseCase, this._getProductReviewsUseCase) : super(const ProductDetailInitial()) {
    on<ProductDetailStarted>(_onProductDetailStarted);
  }

  final GetProductByIdUseCase _getProductByIdUseCase;
  final GetProductReviewsUseCase _getProductReviewsUseCase;

  Future<void> _onProductDetailStarted(ProductDetailStarted event, Emitter<ProductDetailState> emit) async {
    emit(const ProductDetailLoading());

    final result = await _getProductByIdUseCase(event.productId);

    await result.match((failure) async => emit(ProductDetailError(failure.message)), (product) async {
      // A failed reviews fetch shouldn't block showing the product itself —
      // the Review tab just falls back to an empty list.
      final reviewsResult = await _getProductReviewsUseCase(event.productId);
      final reviews = reviewsResult.match((_) => const <ReviewEntity>[], (value) => value);
      emit(ProductDetailLoaded(product, reviews: reviews));
    });
  }
}
