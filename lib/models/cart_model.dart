class Cart {
  final List<CartItem> items;
  final double totalPrice;

  Cart({
    required this.items,
    required this.totalPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemData = json['items'] as List<dynamic>? ?? [];
    List<CartItem> itemsList =
        itemData.map((i) => CartItem.fromJson(i)).toList();

    return Cart(
      items: itemsList,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
    );
  }
}

class CartItem {
  final int cartItemId;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final int stock;
  final String imageUrl;
  final int sellerId; // [TAMBAHAN]
  final String shopName; // [TAMBAHAN]

  CartItem({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.sellerId, // [TAMBAHAN]
    required this.shopName, // [TAMBAHAN]
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: int.tryParse(json['cart_item_id'].toString()) ?? 0,
      productId: int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] ?? 'Nama Produk Tidak Tersedia',
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      price: double.tryParse(json['price_at_add'].toString()) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      imageUrl: json['image_url'] ?? '',
      // [TAMBAHAN] Parsing data baru dari JSON
      sellerId: int.tryParse(json['seller_id'].toString()) ?? 0,
      shopName: json['shop_name'] ?? 'Nama Toko Tidak Tersedia',
    );
  }
}
