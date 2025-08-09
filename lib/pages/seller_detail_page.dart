import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/product_model.dart';
import '../models/seller_detail_model.dart';
import '../models/user_model.dart'; // <-- TAMBAHKAN
import 'product_detail_page.dart';

class SellerDetailPage extends StatefulWidget {
  final int sellerId;
  final User user; // <-- UBAH

  const SellerDetailPage({
    super.key,
    required this.sellerId,
    required this.user, // <-- UBAH
  });

  @override
  State<SellerDetailPage> createState() => _SellerDetailPageState();
}

class _SellerDetailPageState extends State<SellerDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<SellerDetail> _sellerDetailFuture;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _sellerDetailFuture = _apiService.getSellerDetail(widget.sellerId);
  }

  Future<void> _handleAddToCart(Product product) async {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    // Show loading snackbar
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
      final result = await _apiService.addToCart(
        userId: widget.user.userId, // <-- UBAH
        productId: product.productId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final message = result['message'] ?? 'Terjadi kesalahan.';
        final isSuccess = result['status'] == 'success';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            backgroundColor: isSuccess ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF667EEA);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<SellerDetail>(
        future: _sellerDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text('Penjual tidak ditemukan.'),
            );
          }

          final sellerData = snapshot.data!;
          final seller = sellerData.sellerDetails;
          final inStockProducts =
              sellerData.sellerProducts.where((p) => p.stock > 0).toList();

          return CustomScrollView(
            slivers: [
              _buildSellerAppBar(seller, inStockProducts.length),
              _buildSectionTitle('Etalase Toko'),
              if (inStockProducts.isEmpty)
                _buildEmptyProductPlaceholder()
              else
                _buildProductGrid(inStockProducts),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSellerAppBar(Seller seller, int productCount) {
    const appBarColor = Color(0xFF667EEA);
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: appBarColor,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          seller.shopName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                // FIX: Replaced deprecated withOpacity
                appBarColor.withAlpha(230),
                appBarColor.withAlpha(179),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (seller.shopLogoUrl.isNotEmpty)
                Image.network(
                  seller.shopLogoUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withAlpha(77),
                  colorBlendMode: BlendMode.darken,
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white.withAlpha(230),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: seller.shopLogoUrl.isNotEmpty
                            ? NetworkImage(seller.shopLogoUrl)
                            : null,
                        child: seller.shopLogoUrl.isEmpty
                            ? const Icon(Icons.storefront,
                                size: 45, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      seller.shopName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (seller.city != null && seller.city!.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            seller.city!,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: Container(
          color: Colors.white,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    Icons.inventory_2_outlined, '$productCount', 'Produk'),
                _buildStatItem(Icons.star_border, '4.8', 'Rating'),
                _buildStatItem(
                    Icons.chat_bubble_outline, '98%', 'Chat Dibalas'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  SliverToBoxAdapter _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildEmptyProductPlaceholder() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Saat ini tidak ada produk yang tersedia.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverPadding _buildProductGrid(List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.6,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    const accentColor = Color(0xFF667EEA);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(51),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                productId: product.productId,
                user: widget.user, // <-- UBAH
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'product_seller_${product.productId}',
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                      ? child
                                      : const Center(
                                          child: CircularProgressIndicator(
                                              color: accentColor)),
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey, size: 40)),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                  child: Icon(Icons.image_not_supported,
                                      color: Colors.grey, size: 40)),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                        onPressed: _isAddingToCart
                            ? null
                            : () => _handleAddToCart(product),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.categoryName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: const TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stok: ${product.stock}',
                    style: TextStyle(
                        color:
                            product.stock > 0 ? Colors.grey[700] : Colors.red,
                        fontSize: 13,
                        fontWeight: product.stock > 0
                            ? FontWeight.normal
                            : FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
