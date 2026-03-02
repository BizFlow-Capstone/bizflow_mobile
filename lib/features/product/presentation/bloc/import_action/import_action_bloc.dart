import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/import_repository.dart';
import '../../../data/models/import_model.dart';
import 'import_action_event.dart';
import 'import_action_state.dart';

class ImportActionBloc extends Bloc<ImportActionEvent, ImportActionState> {
  final ImportRepository _repository;

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
    emit(state.copyWith(status: ImportActionStatus.submitting));
    try {
      final response = await _repository.createImport(event.request);
      final importData = ImportDetailModel.fromJson(response['data']);
      emit(
        state.copyWith(
          status: ImportActionStatus.success,
          importDetail: importData,
          successMessage: response['message'],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateImport(
    UpdateImportEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(state.copyWith(status: ImportActionStatus.submitting));
    try {
      final response = await _repository.updateImport(
        event.importId,
        event.request,
      );
      final importData = ImportDetailModel.fromJson(response['data']);
      emit(
        state.copyWith(
          status: ImportActionStatus.success,
          importDetail: importData,
          successMessage: response['message'],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onConfirmImport(
    ConfirmImportEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(state.copyWith(status: ImportActionStatus.submitting));
    try {
      final response = await _repository.confirmImport(
        event.importId,
        event.request,
      );
      final importData = ImportDetailModel.fromJson(response['data']);
      emit(
        state.copyWith(
          status: ImportActionStatus.success,
          importDetail: importData,
          successMessage: response['message'],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteImport(
    DeleteImportEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(state.copyWith(status: ImportActionStatus.submitting));
    try {
      final response = await _repository.deleteImport(event.importId);
      emit(
        state.copyWith(
          status: ImportActionStatus.success,
          successMessage: response['message'],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetImportDetail(
    GetImportDetailEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(state.copyWith(status: ImportActionStatus.loading));
    try {
      final response = await _repository.getImportDetail(event.importId);
      final importData = ImportDetailModel.fromJson(response['data']);
      emit(
        state.copyWith(
          status: ImportActionStatus.loaded,
          importDetail: importData,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetImportTemplate(
    GetImportTemplateEvent event,
    Emitter<ImportActionState> emit,
  ) async {
    emit(state.copyWith(status: ImportActionStatus.loading));
    try {
      final response = await _repository.getImportTemplate();
      final schemaJson = response['data']['schemaJson'] as String;
      emit(
        state.copyWith(
          status: ImportActionStatus.templateLoaded,
          templateJson: schemaJson,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportActionStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
