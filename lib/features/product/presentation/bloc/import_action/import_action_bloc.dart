import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/import_repository.dart';
import '../../../data/models/import_model.dart';
import '../../../../../shared/cache/local_api_cache_store.dart';
import 'import_action_event.dart';
import 'import_action_state.dart';
import '../../../../../core/network/api_error_message_parser.dart';

class ImportActionBloc extends Bloc<ImportActionEvent, ImportActionState> {
  final ImportRepository _repository;
  final LocalApiCacheStore _localApiCache = LocalApiCacheStore();

  ImportActionBloc({required ImportRepository repository})
    : _repository = repository,
      super(const ImportActionState()) {
    on<CreateImportEvent>(_onCreateImport);
    on<UpdateImportEvent>(_onUpdateImport);
    on<ConfirmImportEvent>(_onConfirmImport);
    on<DeleteImportEvent>(_onDeleteImport);
    on<GetImportDetailEvent>(_onGetImportDetail);
    on<GetImportTemplateEvent>(_onGetImportTemplate);
  }

  Future<void> _onCreateImport(
    CreateImportEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ImportActionStatus.submitting,
        actionType: ImportActionType.create,
      ),
    );
    try {
      final response = await _repository.createImport(event.request);
      final importData = ImportDetailModel.fromJson(response['data']);
      await _invalidateImportHistoryCache();
      emit(
        state.copyWith(
          status: ImportActionStatus.success,
          actionType: ImportActionType.create,
          importDetail: importData,
          successMessage: response['message'],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          actionType: ImportActionType.create,
          errorMessage: ApiErrorMessageParser.parse(e),
        ),
      );
    }
  }

  Future<void> _onUpdateImport(
    UpdateImportEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ImportActionStatus.submitting,
        actionType: ImportActionType.update,
      ),
    );
    try {
      final response = await _repository.updateImport(
        event.importId,
        event.request,
      );
      final importData = ImportDetailModel.fromJson(response['data']);
      await _invalidateImportHistoryCache();
      emit(
        state.copyWith(
          status: ImportActionStatus.success,
          actionType: ImportActionType.update,
          importDetail: importData,
          successMessage: response['message'],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          actionType: ImportActionType.update,
          errorMessage: ApiErrorMessageParser.parse(e),
        ),
      );
    }
  }

  Future<void> _onConfirmImport(
    ConfirmImportEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ImportActionStatus.submitting,
        actionType: ImportActionType.confirm,
      ),
    );
    try {
      final response = await _repository.confirmImport(
        event.importId,
        event.request,
      );
      await _invalidateImportHistoryCache();
      emit(
        state.copyWith(
          status: ImportActionStatus.success,
          actionType: ImportActionType.confirm,
          importDetail: state.importDetail,
          successMessage: response['message'],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          actionType: ImportActionType.confirm,
          errorMessage: ApiErrorMessageParser.parse(e),
        ),
      );
    }
  }

  Future<void> _onDeleteImport(
    DeleteImportEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ImportActionStatus.submitting,
        actionType: ImportActionType.delete,
      ),
    );
    try {
      final response = await _repository.deleteImport(event.importId);
      await _invalidateImportHistoryCache();
      emit(
        state.copyWith(
          status: ImportActionStatus.success,
          actionType: ImportActionType.delete,
          successMessage: response['message'],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          actionType: ImportActionType.delete,
          errorMessage: ApiErrorMessageParser.parse(e),
        ),
      );
    }
  }

  Future<void> _onGetImportDetail(
    GetImportDetailEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ImportActionStatus.loading,
        actionType: ImportActionType.loadDetail,
      ),
    );
    try {
      final response = await _repository.getImportDetail(event.importId);
      final importData = ImportDetailModel.fromJson(response);
      emit(
        state.copyWith(
          status: ImportActionStatus.loaded,
          actionType: ImportActionType.loadDetail,
          importDetail: importData,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          actionType: ImportActionType.loadDetail,
          errorMessage: ApiErrorMessageParser.parse(e),
        ),
      );
    }
  }

  Future<void> _onGetImportTemplate(
    GetImportTemplateEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ImportActionStatus.loading,
        actionType: ImportActionType.loadTemplate,
      ),
    );
    try {
      final response = await _repository.getImportTemplate();
      final schemaJson = response['data']['schemaJson'] as String;
      emit(
        state.copyWith(
          status: ImportActionStatus.templateLoaded,
          actionType: ImportActionType.loadTemplate,
          templateJson: schemaJson,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          actionType: ImportActionType.loadTemplate,
          errorMessage: ApiErrorMessageParser.parse(e),
        ),
      );
    }
  }

  Future<void> _invalidateImportHistoryCache() {
    return _localApiCache.removeByGroup('imports');
  }
}
