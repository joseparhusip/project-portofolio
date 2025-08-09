import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import '../models/product_review_model.dart'; // <-- TAMBAHKAN IMPORT
import '../models/user_model.dart';
import 'seller_detail_page.dart';
import 'shopping_cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final User user;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.user,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<Product> _productDetailFuture;
  late Future<List<ProductReview>>
      _reviewsFuture; // <-- TAMBAHKAN STATE UNTUK REVIEWS
  Future<List<Product>>? _relatedProductsFuture;

  static const Color primaryColor = Color(0xFF667EEA);
  static const Color accentColor = Color(0xFF667EEA);
  static const Color textColor = Color(0xFF333333);
  static const Color subtitleColor = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _productDetailFuture = _apiService.getProductDetail(widget.productId);
      _reviewsFuture = _apiService
          .getProductReviews(widget.productId); // <-- PANGGIL API REVIEWS
      _relatedProductsFuture = _apiService.getShopProducts();
    });
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  Future<void> _handleAddToCart(Product product) async {
    // ... (kode handleAddToCart tidak berubah)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(width: 16),
            Text('Menambahkan ke keranjang...'),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.blueGrey,
      ),
    );

    try {
      final response = await _apiService.addToCart(
        userId: widget.user.userId,
        productId: product.productId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Terjadi kesalahan.'),
          duration: const Duration(seconds: 2),
          backgroundColor:
              response['status'] == 'success' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async => _fetchData(),
        color: primaryColor,
        child: FutureBuilder<Product>(
          future: _productDetailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: primaryColor));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text(
                      'Gagal memuat detail produk.\nError: ${snapshot.error}',
                      textAlign: TextAlign.center));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Produk tidak ditemukan.'));
            }

            final product = snapshot.data!;
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, product),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildProductHeader(product),
                    _buildSellerInfoCard(context, product),
                    _buildDescription(product),
                    const SizedBox(height: 24),
                    _buildProductReviews(), // <-- WIDGET BARU UNTUK MENAMPILKAN ULASAN
                    const SizedBox(height: 24),
                    _buildRelatedProducts(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<Product>(
        future: _productDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final product = snapshot.data!;
            return _buildBottomAppBar(product.stock > 0, product);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ... (widget _buildSliverAppBar, _buildProductHeader, _buildStockStatusChip, _buildSellerInfoCard, _buildDescription TIDAK BERUBAH)
  SliverAppBar _buildSliverAppBar(BuildContext context, Product product) {
    return SliverAppBar(
      expandedHeight: 350.0,
      pinned: true,
      stretch: true,
      backgroundColor: primaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          product.productName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        background: Hero(
          tag: 'product_image_${product.productId}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300]),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.black87
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(Product product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.categoryName,
            style: const TextStyle(
                color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            product.productName,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: textColor,
                height: 1.2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatCurrency(product.price),
                style: const TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
              _buildStockStatusChip(product),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusChip(Product product) {
    bool inStock = product.stock > 0;
    return Chip(
      avatar: Icon(
        inStock ? Icons.check_circle_outline : Icons.error_outline,
        color: inStock ? Colors.green[800] : Colors.red[800],
        size: 18,
      ),
      label: Text(
        inStock ? 'Stok: ${product.stock}' : 'Stok Habis',
        style: TextStyle(
          color: inStock ? Colors.green[800] : Colors.red[800],
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: (inStock ? Colors.green : Colors.red).withAlpha(31),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.transparent),
      ),
    );
  }

  Widget _buildSellerInfoCard(BuildContext context, Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: primaryColor.withAlpha(26),
            backgroundImage: product.shopLogoUrl.isNotEmpty
                ? NetworkImage(product.shopLogoUrl)
                : null,
            child: product.shopLogoUrl.isEmpty
                ? const Icon(Icons.storefront, color: primaryColor, size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.shopName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text('Official Store',
                    style: TextStyle(color: subtitleColor, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SellerDetailPage(
                    sellerId: product.sellerId,
                    user: widget.user,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Kunjungi'),
          )
        ],
      ),
    );
  }

  Widget _buildDescription(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi Produk',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: const TextStyle(
                fontSize: 15, color: subtitleColor, height: 1.6),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BARU UNTUK MENAMPILKAN ULASAN ---
  Widget _buildProductReviews() {
    return FutureBuilder<List<ProductReview>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: primaryColor));
        }

        // Jika tidak ada data atau data kosong (karena API bisa mengembalikan list kosong)
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // <-- PERBAIKAN 1: Menambahkan `const` pada widget dan propertinya
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ulasan Produk',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'Belum ada ulasan untuk produk ini.',
                    style: TextStyle(
                        color: subtitleColor, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        }

        final reviews = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ulasan Produk',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              const SizedBox(height: 16),
              // Gunakan Column karena sudah berada dalam SliverList
              Column(
                children:
                    reviews.map((review) => _buildReviewItem(review)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET BARU UNTUK SATU ITEM ULASAN ---
  Widget _buildReviewItem(ProductReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            // <-- PERBAIKAN 2: Mengganti `withOpacity` yang deprecated menjadi `withAlpha`
            backgroundColor: primaryColor.withAlpha(26),
            backgroundImage: review.userImageUrl.isNotEmpty
                ? NetworkImage(review.userImageUrl)
                : null,
            child: review.userImageUrl.isEmpty
                ? const Icon(Icons.person, size: 24, color: primaryColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                      5,
                      (index) => Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 18,
                          )),
                ),
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.comment!,
                    style: const TextStyle(color: subtitleColor, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (widget _buildRelatedProducts, _buildRelatedProductCard, _buildBottomAppBar TIDAK BERUBAH)
  Widget _buildRelatedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Anda Mungkin Suka',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: FutureBuilder<List<Product>>(
            future: _relatedProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: primaryColor));
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Center(child: Text('Tidak ada produk lain.'));
              }
              final relatedProducts = snapshot.data!
                  .where((p) => p.productId != widget.productId)
                  .toList();
              if (relatedProducts.isEmpty) {
                return const Center(child: Text('Tidak ada produk sejenis.'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 4),
                itemCount: relatedProducts.length,
                itemBuilder: (context, index) {
                  final product = relatedProducts[index];
                  return _buildRelatedProductCard(product);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductCard(Product product) {
    return SizedBox(
      width: 160,
      child: Card(
        margin: const EdgeInsets.only(right: 16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: Colors.black.withAlpha(13),
        child: InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(
                  productId: product.productId,
                  user: widget.user,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatCurrency(product.price),
                        style: const TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar(bool isAvailable, Product product) {
    return BottomAppBar(
      elevation: 0,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Keranjang'),
                onPressed: isAvailable ? () => _handleAddToCart(product) : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(
                      color: isAvailable ? primaryColor : Colors.grey[300]!,
                      width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isAvailable
                    ? () {
                        final buyNowItem = CartItem(
                          cartItemId: -1,
                          productId: product.productId,
                          productName: product.productName,
                          price: product.price,
                          quantity: 1,
                          imageUrl: product.imageUrl,
                          shopName: product.shopName,
                          sellerId: product.sellerId,
                          stock: product.stock,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShoppingCartPage(
                              selectedItems: [buyNowItem],
                              user: widget.user,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: const Text('Beli Sekarang',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
