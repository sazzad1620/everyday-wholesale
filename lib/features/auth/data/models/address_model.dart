import '../../domain/entities/address_entity.dart';

/// Mirrors the `address` map embedded in a `users/{uid}` Firestore document
/// — not its own collection/doc, since it's a one-address-per-user field.
class AddressModel extends AddressEntity {
  const AddressModel({
    required super.receiverName,
    required super.phoneNumber,
    required super.postalCode,
    required super.state,
    required super.city,
    required super.street,
    required super.chomeBanchiGo,
    super.buildingName,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      receiverName: map['receiverName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
      state: map['state'] as String? ?? '',
      city: map['city'] as String? ?? '',
      street: map['street'] as String? ?? '',
      chomeBanchiGo: map['chomeBanchiGo'] as String? ?? '',
      buildingName: map['buildingName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'receiverName': receiverName,
    'phoneNumber': phoneNumber,
    'postalCode': postalCode,
    'state': state,
    'city': city,
    'street': street,
    'chomeBanchiGo': chomeBanchiGo,
    'buildingName': buildingName,
  };
}
