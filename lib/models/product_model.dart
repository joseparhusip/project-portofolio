// lib/models/product_model.dart

class Product {
  final int wishlistId; // ID unik dari tabel wishlist
  final int productId;
  final int sellerId;
  final String productName;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final String categoryName;
  final String shopName;
  final String shopLogoUrl;
  bool isFavorite; // Untuk status 'love' di UI

  Product({
    required this.wishlistId,
    required this.productId,
    required this.sellerId,
    required this.productName,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.categoryName,
    required this.shopName,
    required this.shopLogoUrl,
    this.isFavorite = true, // Item di wishlist selalu jadi favorit
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      // Pastikan key JSON SAMA PERSIS dengan respons dari get_wishlist.php
      wishlistId: int.tryParse(json['wishlist_id'].toString()) ?? 0,
      productId: int.tryParse(json['product_id'].toString()) ?? 0,
      sellerId: int.tryParse(json['seller_id'].toString()) ?? 0,
      productName: json['product_name'] ?? 'Nama Produk Tidak Tersedia',
      description: json['description'] ?? 'Tidak ada deskripsi.',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      imageUrl: json['image_url'] ?? '',
      categoryName: json['category_name'] ?? 'Lainnya',
      shopName: json['shop_name'] ?? 'Toko Tidak Tersedia',
      shopLogoUrl: json['shop_logo_url'] ?? '',
    );
  }
}
