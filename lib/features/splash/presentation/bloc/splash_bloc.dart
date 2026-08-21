import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/check_app_ready_usecase.dart';
import 'splash_event.dart';
import 'splash_state.dart';

@injectable
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc(this._checkAppReadyUseCase) : super(const SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
  }

  final CheckAppReadyUseCase _checkAppReadyUseCase;

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashInProgress());

    final result = await _checkAppReadyUseCase(const NoParams());

    result.match(
      (failure) => emit(SplashFailure(failure.message)),
      (_) => emit(const SplashReady()),
    );
  }
}
