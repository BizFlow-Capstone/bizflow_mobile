import 'package:equatable/equatable.dart';
import '../../../data/models/import_model.dart';

abstract class ImportActionEvent extends Equatable {
  const ImportActionEvent();

  @override
  List<Object?> get props => [];
}

class CreateImportEvent extends ImportActionEvent {
  final CreateImportRequest request;

  const CreateImportEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class UpdateImportEvent extends ImportActionEvent {
  final int importId;
  final UpdateImportRequest request;

  const UpdateImportEvent(this.importId, this.request);

  @override
  List<Object?> get props => [importId, request];
}

class ConfirmImportEvent extends ImportActionEvent {
  final int importId;
  final ConfirmImportRequest request;

  const ConfirmImportEvent(this.importId, this.request);

  @override
  List<Object?> get props => [importId, request];
}

class DeleteImportEvent extends ImportActionEvent {
  final int importId;

  const DeleteImportEvent(this.importId);

  @override
  List<Object?> get props => [importId];
}

class GetImportDetailEvent extends ImportActionEvent {
  final int importId;

  const GetImportDetailEvent(this.importId);

  @override
  List<Object?> get props => [importId];
}

class GetImportTemplateEvent extends ImportActionEvent {
  const GetImportTemplateEvent();
}
