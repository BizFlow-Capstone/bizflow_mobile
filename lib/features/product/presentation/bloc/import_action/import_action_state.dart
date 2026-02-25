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

class ImportActionState extends Equatable {
  final ImportActionStatus status;
  final ImportDetailModel? importDetail;
  final String? templateJson;
  final String? successMessage;
  final String? errorMessage;

  const ImportActionState({
    this.status = ImportActionStatus.initial,
    this.importDetail,
    this.templateJson,
    this.successMessage,
    this.errorMessage,
  });

  ImportActionState copyWith({
    ImportActionStatus? status,
    ImportDetailModel? importDetail,
    String? templateJson,
    String? successMessage,
    String? errorMessage,
  }) {
    return ImportActionState(
      status: status ?? this.status,
      importDetail: importDetail ?? this.importDetail,
      templateJson: templateJson ?? this.templateJson,
      successMessage: successMessage, // deliberate, can be null
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    importDetail,
    templateJson,
    successMessage,
    errorMessage,
  ];
}
