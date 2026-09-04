import 'package:equatable/equatable.dart';

/// Mirrors [CategoryFormState]'s shape — this bloc only tracks the progress
/// of a single status-change submission, it doesn't hold the order itself
/// (the page already has it, passed in via the route).
class AdminOrderDetailState extends Equatable {
  const AdminOrderDetailState({this.isUpdating = false, this.errorMessage, this.success = false});

  final bool isUpdating;
  final String? errorMessage;
  final bool success;

  @override
  List<Object?> get props => [isUpdating, errorMessage, success];
}
