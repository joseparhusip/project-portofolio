import 'product_model.dart'; // Kita akan gunakan lagi model Produk

// Model untuk data detail penjual
class Seller {
  final int sellerId;
  final String shopName;
  final String? shopDescription;
  final String? city;
  final String shopLogoUrl;

  Seller({
    required this.sellerId,
    required this.shopName,
    this.shopDescription,
    this.city,
    required this.shopLogoUrl,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      sellerId: int.tryParse(json['seller_id'].toString()) ?? 0,
      shopName: json['shop_name'] ?? 'Nama Toko Tidak Tersedia',
      shopDescription: json['shop_description'],
      city: json['city'],
      shopLogoUrl: json['shop_logo_url'] ?? '',
    );
  }
}

// Model untuk menggabungkan detail penjual dan daftar produknya
class SellerDetail {
  final Seller sellerDetails;
  final List<Product> sellerProducts;

  SellerDetail({
    required this.sellerDetails,
    required this.sellerProducts,
  });

  factory SellerDetail.fromJson(Map<String, dynamic> json) {
    // Ambil list produk dan ubah menjadi List<Product>
    final productData = json['seller_products'] as List<dynamic>? ?? [];
    final products = productData
        .map((productJson) => Product.fromJson(productJson))
        .toList();

    return SellerDetail(
      sellerDetails: Seller.fromJson(json['seller_details'] ?? {}),
      sellerProducts: products,
    );
  }
}
