import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../network/api_error_message_parser.dart';
import '../../data/reference_repository.dart';
import 'reference_event.dart';
import 'reference_state.dart';

class ReferenceBloc extends Bloc<ReferenceEvent, ReferenceState> {
  final ReferenceRepository repository;

  ReferenceBloc({required this.repository}) : super(ReferenceInitial()) {
    on<LoadAllReferencesRequested>(_onLoadAllReferencesRequested);
    on<ForceReloadAllReferencesRequested>(_onForceReloadAllReferencesRequested);
  }

  Future<void> _onLoadAllReferencesRequested(
    LoadAllReferencesRequested event,
    Emitter<ReferenceState> emit,
  ) async {
    emit(ReferenceLoading());
    await repository.getAllReferences(
      onData: (data, isFromCache) {
        emit(ReferenceLoaded(data, isFromCache: isFromCache));
      },
      onError: (e) {
        emit(ReferenceError(ApiErrorMessageParser.parse(e)));
      },
    );
  }

  Future<void> _onForceReloadAllReferencesRequested(
    ForceReloadAllReferencesRequested event,
    Emitter<ReferenceState> emit,
  ) async {
    // Chỉ reset timer, không xóa cache — nếu mất mạng thì data cũ vẫn được giữ
    repository.scheduleForceRevalidate();
    await repository.getAllReferences(
      onData: (data, isFromCache) {
        emit(ReferenceLoaded(data, isFromCache: isFromCache));
      },
      onError: (e) {
        // Không emit error nếu đang có data cũ — tránh UI trống khi offline
        if (state is! ReferenceLoaded) {
          emit(ReferenceError(ApiErrorMessageParser.parse(e)));
        }
      },
    );
  }
}
