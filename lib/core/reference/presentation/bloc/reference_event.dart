import 'package:equatable/equatable.dart';

abstract class ReferenceEvent extends Equatable {
  const ReferenceEvent();

  @override
  List<Object> get props => [];
}

class LoadAllReferencesRequested extends ReferenceEvent {}
