import 'package:equatable/equatable.dart';
import '../../domain/entities/invoice_template_entity.dart';

abstract class InvoiceTemplateState extends Equatable {
  const InvoiceTemplateState();

  @override
  List<Object?> get props => [];
}

class InvoiceTemplateInitial extends InvoiceTemplateState {
  const InvoiceTemplateInitial();
}

class InvoiceTemplateLoading extends InvoiceTemplateState {
  const InvoiceTemplateLoading();
}

class InvoiceTemplateLoaded extends InvoiceTemplateState {
  final InvoiceTemplateEntity template;

  const InvoiceTemplateLoaded({required this.template});

  @override
  List<Object?> get props => [template];
}

class InvoiceTemplateSaveInProgress extends InvoiceTemplateState {
  const InvoiceTemplateSaveInProgress();
}

class InvoiceTemplateSaveSuccess extends InvoiceTemplateState {
  const InvoiceTemplateSaveSuccess();
}

class InvoiceTemplateFailure extends InvoiceTemplateState {
  final String message;

  const InvoiceTemplateFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
