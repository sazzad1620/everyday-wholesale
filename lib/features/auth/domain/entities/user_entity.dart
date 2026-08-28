import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({required this.uid, required this.email, required this.name, this.phone, this.role = 'customer'});

  final String uid;
  final String email;
  final String name;

  /// Set for phone-signed-up accounts (and optionally for email accounts
  /// later); null otherwise.
  final String? phone;

  /// `'customer'` or `'admin'` — read from the user's Firestore document,
  /// not from Firebase Auth itself (which has no concept of roles).
  final String role;

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [uid, email, name, phone, role];
}
