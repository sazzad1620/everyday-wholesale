/// Every order starts `pending` — nothing currently moves it to `completed`
/// (that's the admin/Stripe phases). `.name` (`pending`/`completed`/
/// `cancelled`) is the stored Firestore string; see `OrderStatusX.parse`.
enum OrderStatus { pending, completed, cancelled }

extension OrderStatusX on OrderStatus {
  static OrderStatus parse(String value) {
    return OrderStatus.values.firstWhere((status) => status.name == value, orElse: () => OrderStatus.pending);
  }
}
