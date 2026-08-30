import 'package:equatable/equatable.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class CheckoutOrderPlaceRequested extends CheckoutEvent {
  const CheckoutOrderPlaceRequested({
    required this.paymentMethod,
    required this.addressLine,
    required this.addressPhone,
    required this.addressReceiverName,
  });

  final String paymentMethod;
  final String addressLine;
  final String addressPhone;
  final String addressReceiverName;

  @override
  List<Object?> get props => [paymentMethod, addressLine, addressPhone, addressReceiverName];
}
