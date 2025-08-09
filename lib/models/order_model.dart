class Order {
  final int orderId;
  final int userId;
  final double totalAmount;
  final double subtotalAmount;
  final double taxAmount;
  final String paymentProofImageUrl;
  final String orderStatus;
  final DateTime orderDate;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.userId,
    required this.totalAmount,
    required this.subtotalAmount,
    required this.taxAmount,
    required this.paymentProofImageUrl,
    required this.orderStatus,
    required this.orderDate,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<OrderItem> orderItems =
        itemsList.map((i) => OrderItem.fromJson(i)).toList();

    return Order(
      orderId: int.parse(json['order_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      subtotalAmount: double.parse(json['subtotal_amount'].toString()),
      taxAmount: double.parse(json['tax_amount'].toString()),
      paymentProofImageUrl: json['payment_proof_image_url'] ?? '',
      orderStatus: json['order_status'] ?? 'Pending',
      orderDate: DateTime.parse(json['order_date']),
      items: orderItems,
    );
  }
}

class OrderItem {
  final int orderItemId;
  final int orderId;
  final int productId;
  final int quantity;
  final double priceAtPurchase;
  final String productName;
  final String productImageUrl;

  OrderItem({
    required this.orderItemId,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
    required this.productName,
    required this.productImageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderItemId: int.parse(json['order_item_id'].toString()),
      orderId: int.parse(json['order_id'].toString()),
      productId: int.parse(json['product_id'].toString()),
      quantity: int.parse(json['quantity'].toString()),
      priceAtPurchase: double.parse(json['price_at_purchase'].toString()),
      productName: json['product_name'] ?? 'Produk tidak diketahui',
      productImageUrl: json['product_image_url'] ?? '',
    );
  }
}
