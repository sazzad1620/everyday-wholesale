import 'package:equatable/equatable.dart';

abstract class AdminReviewListEvent extends Equatable {
  const AdminReviewListEvent();

  @override
  List<Object?> get props => [];
}

class AdminReviewListRequested extends AdminReviewListEvent {
  const AdminReviewListRequested();
}
