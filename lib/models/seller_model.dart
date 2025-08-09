class SellerModel {
  final int sellerId;
  final String shopName;
  final String city;
  final String shopLogoUrl;

  SellerModel({
    required this.sellerId,
    required this.shopName,
    required this.city,
    required this.shopLogoUrl,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      sellerId: int.tryParse(json['seller_id'].toString()) ?? 0,
      shopName: json['shop_name'] ?? 'Nama Toko Tidak Tersedia',
      city: json['city'] ?? 'Kota Tidak Tersedia',
      shopLogoUrl: json['shop_logo_url'] ?? '',
    );
  }
}
