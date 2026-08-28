import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({required this.uid, required this.email, required this.name, this.role = 'customer'});

  final String uid;
  final String email;
  final String name;

  /// `'customer'` or `'admin'` — read from the user's Firestore document,
  /// not from Firebase Auth itself (which has no concept of roles).
  final String role;

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [uid, email, name, role];
}
