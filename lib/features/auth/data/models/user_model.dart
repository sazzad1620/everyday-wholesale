import '../../domain/entities/user_entity.dart';

/// Mirrors a `users/{uid}` Firestore document. `uid` is the document ID, not
/// a stored field, so it's passed separately to [fromMap] rather than read
/// out of the map.
class UserModel extends UserEntity {
  const UserModel({required super.uid, required super.email, required super.name, super.phone, super.role});

  factory UserModel.fromMap(Map<String, dynamic> map, {required String uid}) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'customer',
    );
  }

  Map<String, dynamic> toMap() => {'email': email, 'name': name, 'phone': phone, 'role': role};
}
