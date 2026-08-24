import '../constants/pricing_constants.dart';

/// The cart/checkout totals breakdown, derived from a single item total so
/// the cart page and the checkout page always agree on the numbers.
class CartTotals {
  const CartTotals({
    required this.productTotal,
    required this.discount,
    required this.tax,
    required this.shippingFee,
    required this.subTotal,
    required this.voucherDeduction,
    required this.total,
  });

  /// Discount and the voucher deduction are fixed at ¥0 for now — neither
  /// is wired up to actually apply anything yet.
  factory CartTotals.compute(int itemTotal) {
    const discount = 0;
    const voucherDeduction = 0;
    final tax = (itemTotal * PricingConstants.taxRate).round();
    final shippingFee = itemTotal >= PricingConstants.freeDeliveryThresholdYen ? 0 : PricingConstants.flatShippingFeeYen;
    final subTotal = itemTotal - discount + tax + shippingFee;
    final total = subTotal - voucherDeduction;

    return CartTotals(
      productTotal: itemTotal,
      discount: discount,
      tax: tax,
      shippingFee: shippingFee,
      subTotal: subTotal,
      voucherDeduction: voucherDeduction,
      total: total,
    );
  }

  final int productTotal;
  final int discount;
  final int tax;
  final int shippingFee;
  final int subTotal;
  final int voucherDeduction;
  final int total;
}
