import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../home/domain/usecases/create_category_usecase.dart';
import '../../../../home/domain/usecases/update_category_usecase.dart';
import 'category_form_event.dart';
import 'category_form_state.dart';

/// One per form visit (`@injectable`, not shared) — mirrors [CheckoutBloc].
@injectable
class CategoryFormBloc extends Bloc<CategoryFormEvent, CategoryFormState> {
  CategoryFormBloc(this._createCategoryUseCase, this._updateCategoryUseCase) : super(const CategoryFormState()) {
    on<CategoryFormSubmitted>(_onSubmitted);
  }

  final CreateCategoryUseCase _createCategoryUseCase;
  final UpdateCategoryUseCase _updateCategoryUseCase;

  Future<void> _onSubmitted(CategoryFormSubmitted event, Emitter<CategoryFormState> emit) async {
    emit(const CategoryFormState(isSubmitting: true));
    final result = event.isEditing
        ? await _updateCategoryUseCase(event.category)
        : await _createCategoryUseCase(event.category);
    result.match(
      (failure) => emit(CategoryFormState(errorMessage: failure.message)),
      (_) => emit(const CategoryFormState(success: true)),
    );
  }
}
