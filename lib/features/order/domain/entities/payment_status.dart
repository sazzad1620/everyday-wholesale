/// Separate from [OrderStatus] on purpose — fulfillment ("has this been
/// packed/delivered?") and payment ("has this actually been charged?") are
/// independent concerns and shouldn't be conflated (see
/// docs/PAYMENTS_PLAN.md §4). Every order starts `unpaid`; only the
/// `stripeWebhook`/`reconcilePendingPayments` Cloud Functions ever flip it
/// to `paid`/`failed` — the client never sets anything but `unpaid` at
/// creation (enforced by `firestore.rules`).
enum PaymentStatus { unpaid, paid, failed }

extension PaymentStatusX on PaymentStatus {
  static PaymentStatus parse(String value) {
    return PaymentStatus.values.firstWhere((status) => status.name == value, orElse: () => PaymentStatus.unpaid);
  }
}
