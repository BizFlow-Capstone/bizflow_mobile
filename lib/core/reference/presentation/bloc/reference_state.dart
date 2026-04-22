import 'package:equatable/equatable.dart';
import '../../../reference/data/reference_item.dart';

export '../../../reference/data/reference_item.dart';

abstract class ReferenceState extends Equatable {
  const ReferenceState();

  @override
  List<Object?> get props => [];
}

class ReferenceInitial extends ReferenceState {}

class ReferenceLoading extends ReferenceState {}

class ReferenceLoaded extends ReferenceState {
  final Map<String, List<ReferenceItem>> references;
  final bool isFromCache;

  const ReferenceLoaded(
    this.references, {
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [references, isFromCache];
}

class ReferenceError extends ReferenceState {
  final String message;

  const ReferenceError(this.message);

  @override
  List<Object?> get props => [message];
}
