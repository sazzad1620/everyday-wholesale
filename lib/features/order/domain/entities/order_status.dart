/// Every order starts `pending` (placed, not yet acted on) — only the admin
/// moves it forward: `processing` (accepted, being prepared) then
/// `completed`, or `cancelled` from either `pending` or `processing`. `.name`
/// is the stored Firestore string; see `OrderStatusX.parse`.
enum OrderStatus { pending, processing, completed, cancelled }

extension OrderStatusX on OrderStatus {
  static OrderStatus parse(String value) {
    return OrderStatus.values.firstWhere((status) => status.name == value, orElse: () => OrderStatus.pending);
  }
}
