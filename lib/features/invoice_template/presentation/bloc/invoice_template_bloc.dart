import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/invoice_template_repository.dart';
import '../../domain/entities/invoice_template_entity.dart';
import 'invoice_template_event.dart';
import 'invoice_template_state.dart';
import '../../../../shared/cache/cache_manager.dart';

class InvoiceTemplateBloc extends Bloc<InvoiceTemplateEvent, InvoiceTemplateState> {
  final InvoiceTemplateRepository repository;

  // In-memory cache
  InvoiceTemplateEntity? _templateCache;

  InvoiceTemplateBloc({required this.repository}) : super(const InvoiceTemplateInitial()) {
    on<LoadInvoiceTemplateRequested>(_onLoadInvoiceTemplateRequested);
    on<SaveInvoiceTemplateRequested>(_onSaveInvoiceTemplateRequested);
  }

  Future<InvoiceTemplateEntity> _refreshInvoiceTemplate() async {
    final template = await repository.getInvoiceTemplate();
    _templateCache = template;
    return template;
  }

  Future<void> _onLoadInvoiceTemplateRequested(
    LoadInvoiceTemplateRequested event,
    Emitter<InvoiceTemplateState> emit,
  ) async {
    emit(const InvoiceTemplateLoading());

    await CacheManager().fetchWithSWR<InvoiceTemplateEntity>(
      key: 'my_invoice_template',
      fetcher: ({cancelToken}) => _refreshInvoiceTemplate(),
      fromJson: (json) {
        return InvoiceTemplateEntity.fromMap(json['data'] as Map<String, dynamic>);
      },
      toJson: (data) {
        return {'data': data.toMap()};
      },
      onData: (data, isFromCache) {
        _templateCache = data;
        emit(InvoiceTemplateLoaded(template: data));
      },
      onError: (error) {
        emit(InvoiceTemplateFailure(message: error.toString()));
      },
    );
  }

  Future<void> _onSaveInvoiceTemplateRequested(
    SaveInvoiceTemplateRequested event,
    Emitter<InvoiceTemplateState> emit,
  ) async {
    emit(const InvoiceTemplateSaveInProgress());
    try {
      final updatedTemplate = await repository.updateInvoiceTemplate(event.request);
      
      _templateCache = updatedTemplate;
      
      // Update cache storage
      await CacheManager().set('my_invoice_template', {
        'data': _templateCache!.toMap(),
      });

      emit(const InvoiceTemplateSaveSuccess());
      emit(InvoiceTemplateLoaded(template: _templateCache!));
    } catch (e) {
      emit(InvoiceTemplateFailure(message: e.toString()));
    }
  }
}
