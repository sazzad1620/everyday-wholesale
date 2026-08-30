import 'package:equatable/equatable.dart';

/// One product from one of the customer's completed orders that they
/// haven't reviewed yet — shown under My Reviews > To Be Reviewed. Carries
/// [orderDate] (not just the product) since the same product can appear more
/// than once here if it was bought in several completed orders — a customer
/// can leave one rating per completed order, not just one per product ever.
class ReviewableItemEntity extends Equatable {
  const ReviewableItemEntity({
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.orderDate,
    this.productImageUrl,
  });

  final String orderId;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final DateTime orderDate;

  @override
  List<Object?> get props => [orderId, productId, productName, productImageUrl, orderDate];
}
