import 'package:equatable/equatable.dart';

import 'address_entity.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.role = 'customer',
    this.address,
  });

  final String uid;
  final String email;
  final String name;

  /// Set for phone-signed-up accounts (and optionally for email accounts
  /// later); null otherwise.
  final String? phone;

  /// `'customer'` or `'admin'` — read from the user's Firestore document,
  /// not from Firebase Auth itself (which has no concept of roles).
  final String role;

  /// One saved delivery address, not an address book — null until the user
  /// saves one via Account > Address.
  final AddressEntity? address;

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [uid, email, name, phone, role, address];
}
