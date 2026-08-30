import 'package:equatable/equatable.dart';

/// One saved delivery address per account — not an address book. Fields
/// follow the Japanese addressing convention (prefecture/city/chome-banchi-go)
/// since every customer-facing address in the app so far (mock checkout data)
/// has been a Japanese one.
class AddressEntity extends Equatable {
  const AddressEntity({
    required this.receiverName,
    required this.phoneNumber,
    required this.postalCode,
    required this.state,
    required this.city,
    required this.street,
    required this.chomeBanchiGo,
    this.buildingName,
  });

  /// Who the delivery is addressed to — not necessarily the account holder
  /// (e.g. a gift, or ordering on behalf of someone else).
  final String receiverName;
  final String phoneNumber;
  final String postalCode;

  /// Prefecture, e.g. "Saitama-ken".
  final String state;

  /// e.g. "Hanyu-shi".
  final String city;

  /// e.g. "Chuo".
  final String street;

  /// Block/lot/house number, e.g. "3-Chome 3-19".
  final String chomeBanchiGo;

  /// e.g. "Amenite Plaza B101". Optional — not every address has one.
  final String? buildingName;

  /// Single display line for the checkout card / order history, smallest
  /// region to largest (building → block/house number → street → city →
  /// state/prefecture) — the standard order for a written-out address, e.g.
  /// "Amenite Plaza B101, 3-Chome 3-19, Chuo, Hanyu-shi, Saitama-ken".
  String get formattedLine {
    final parts = [
      if (buildingName != null && buildingName!.trim().isNotEmpty) buildingName!.trim(),
      chomeBanchiGo,
      street,
      city,
      state,
    ];
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
    receiverName,
    phoneNumber,
    postalCode,
    state,
    city,
    street,
    chomeBanchiGo,
    buildingName,
  ];
}
