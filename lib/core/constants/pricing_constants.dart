/// Shared mock pricing rules — referenced by both the product detail page's
/// "Free Delivery" promo and the cart's shipping-charge calculation, so the
/// two stay in sync.
abstract final class PricingConstants {
  static const int freeDeliveryThresholdYen = 10000;
  static const int flatShippingFeeYen = 1200;
  static const double taxRate = 0.08;
}
