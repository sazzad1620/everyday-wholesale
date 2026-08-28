import '../../domain/entities/user_entity.dart';
import 'address_model.dart';

/// Mirrors a `users/{uid}` Firestore document. `uid` is the document ID, not
/// a stored field, so it's passed separately to [fromMap] rather than read
/// out of the map.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.name,
    super.phone,
    super.role,
    super.address,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {required String uid}) {
    final rawAddress = map['address'] as Map<String, dynamic>?;
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'customer',
      address: rawAddress == null ? null : AddressModel.fromMap(Map<String, dynamic>.from(rawAddress)),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'phone': phone,
    'role': role,
    'address': address == null
        ? null
        : AddressModel(
            receiverName: address!.receiverName,
            phoneNumber: address!.phoneNumber,
            postalCode: address!.postalCode,
            state: address!.state,
            city: address!.city,
            street: address!.street,
            chomeBanchiGo: address!.chomeBanchiGo,
            buildingName: address!.buildingName,
          ).toMap(),
  };
}
