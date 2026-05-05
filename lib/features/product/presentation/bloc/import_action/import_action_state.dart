import 'package:equatable/equatable.dart';
import '../../../data/models/import_model.dart';

enum ImportActionStatus {
  initial,
  loading,
  submitting,
  success,
  loaded,
  templateLoaded,
  failure,
}

enum ImportActionType {
  none,
  create,
  update,
  confirm,
  delete,
  loadDetail,
  loadTemplate,
}

class ImportActionState extends Equatable {
  final ImportActionStatus status;
  final ImportActionType actionType;
  final ImportDetailModel? importDetail;
  final String? templateJson;
  final String? successMessage;
  final String? errorMessage;

  const ImportActionState({
    this.status = ImportActionStatus.initial,
    this.actionType = ImportActionType.none,
    this.importDetail,
    this.templateJson,
    this.successMessage,
    this.errorMessage,
  });

  ImportActionState copyWith({
    ImportActionStatus? status,
    ImportActionType? actionType,
    ImportDetailModel? importDetail,
    String? templateJson,
    String? successMessage,
    String? errorMessage,
  }) {
    return ImportActionState(
      status: status ?? this.status,
      actionType: actionType ?? this.actionType,
      importDetail: importDetail ?? this.importDetail,
      templateJson: templateJson ?? this.templateJson,
      successMessage: successMessage, // deliberate, can be null
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    actionType,
    importDetail,
    templateJson,
    successMessage,
    errorMessage,
  ];
}
