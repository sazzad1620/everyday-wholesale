import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/search_products_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';

@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._searchProductsUseCase) : super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
  }

  final SearchProductsUseCase _searchProductsUseCase;

  /// Bumped on every keystroke so a slow, superseded request can't overwrite
  /// the state with stale results once a newer one has already landed —
  /// simple debounce without a separate `EventTransformer` dependency.
  int _requestId = 0;

  Future<void> _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      _requestId++;
      emit(const SearchState());
      return;
    }

    final requestId = ++_requestId;
    emit(SearchState(query: query, isLoading: true));

    await Future.delayed(const Duration(milliseconds: 350));
    if (requestId != _requestId || emit.isDone) return;

    final result = await _searchProductsUseCase(query);
    if (requestId != _requestId || emit.isDone) return;

    result.match(
      (failure) => emit(SearchState(query: query, errorMessage: failure.message)),
      (products) => emit(SearchState(query: query, results: products)),
    );
  }
}
