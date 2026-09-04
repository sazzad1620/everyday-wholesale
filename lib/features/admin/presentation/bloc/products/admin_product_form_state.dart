import 'package:equatable/equatable.dart';

class AdminProductFormState extends Equatable {
  const AdminProductFormState({this.isSubmitting = false, this.errorMessage, this.success = false});

  final bool isSubmitting;
  final String? errorMessage;

  /// Set once create/update succeeds — the form page pops on this.
  final bool success;

  @override
  List<Object?> get props => [isSubmitting, errorMessage, success];
}
