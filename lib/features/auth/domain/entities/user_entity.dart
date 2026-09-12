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
    this.preferredLocale,
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

  /// Language code (`en` / `ja`) the user last picked while signed in — null
  /// until they switch language once. Applied on sign-in so the choice
  /// follows them to a new device; the device-level setting easy_localization
  /// persists covers the signed-out case.
  final String? preferredLocale;

  bool get isAdmin => role == 'admin';

  /// Only the fields the app ever edits locally after a successful write —
  /// keeps `AccountBloc` from having to re-list every field (and silently
  /// dropping a new one) each time it updates its copy of the user.
  UserEntity copyWith({String? name, AddressEntity? address, String? preferredLocale}) => UserEntity(
    uid: uid,
    email: email,
    name: name ?? this.name,
    phone: phone,
    role: role,
    address: address ?? this.address,
    preferredLocale: preferredLocale ?? this.preferredLocale,
  );

  @override
  List<Object?> get props => [uid, email, name, phone, role, address, preferredLocale];
}
