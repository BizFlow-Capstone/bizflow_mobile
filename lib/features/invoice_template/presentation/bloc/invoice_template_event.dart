import 'package:equatable/equatable.dart';
import '../../data/models/invoice_template_dto.dart';

abstract class InvoiceTemplateEvent extends Equatable {
  const InvoiceTemplateEvent();

  @override
  List<Object?> get props => [];
}

class LoadInvoiceTemplateRequested extends InvoiceTemplateEvent {
  const LoadInvoiceTemplateRequested();
}

class SaveInvoiceTemplateRequested extends InvoiceTemplateEvent {
  final UpdateInvoiceTemplateRequestDto request;

  const SaveInvoiceTemplateRequested({required this.request});

  @override
  List<Object?> get props => [request];
}
