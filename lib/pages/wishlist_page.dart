import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frondend_application_new/pages/product_detail_page.dart';
import '../models/product_model.dart';
import '../models/user_model.dart'; // <-- TAMBAHKAN
import '../api/api_service.dart';

class WishlistPage extends StatefulWidget {
  final User user; // <-- UBAH
  const WishlistPage({super.key, required this.user}); // <-- UBAH

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  void _fetchWishlist() {
    setState(() {
      _wishlistFuture = _apiService.getWishlist(widget.user.userId); // <-- UBAH
    });
  }

  void _removeItem(Product item) async {
    // Tampilkan notifikasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.productName} dihapus dari wishlist.'),
        backgroundColor: Colors.red[400],
        duration: const Duration(seconds: 2),
      ),
    );

    // Panggil API untuk menghapus item.
    await _apiService.toggleWishlist(
      userId: widget.user.userId, // <-- UBAH
      productId: item.productId,
    );

    // Refresh halaman
    _fetchWishlist();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF667EEA);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // AppBar kustom untuk tampilan yang lebih bersih
      appBar: AppBar(
        title: const Text(
          'Wishlist Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchWishlist(),
        color: primaryColor,
        child: FutureBuilder<List<Product>>(
          future: _wishlistFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: primaryColor));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Gagal memuat data.\nError: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyWishlistBody();
            }

            final wishlistItems = snapshot.data!;
            // Menggunakan GridView untuk layout yang lebih fleksibel
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 produk per baris
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.7, // Aspek rasio kartu produk
              ),
              itemCount: wishlistItems.length,
              itemBuilder: (context, index) {
                final item = wishlistItems[index];
                return WishlistItemCard(
                  item: item,
                  user: widget.user, // <-- UBAH
                  onRemove: () => _removeItem(item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- KARTU WISHLIST DENGAN DESAIN BARU ---
class WishlistItemCard extends StatelessWidget {
  final Product item;
  final User user; // <-- UBAH
  final VoidCallback onRemove;

  const WishlistItemCard({
    super.key,
    required this.item,
    required this.user, // <-- UBAH
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productId: item.productId,
              user: user, // <-- UBAH
            ),
          ),
        ).then((_) {
          // Aksi refresh bisa ditambahkan di sini jika diperlukan
        });
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withAlpha(26), // <-- UBAH
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GAMBAR PRODUK
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    ),
                  ),
                  // Tombol Hapus
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withAlpha(128), // <-- UBAH
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onRemove,
                        customBorder: const CircleBorder(),
                        splashColor: Colors.red.withAlpha(102), // <-- UBAH
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // DETAIL PRODUK
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(item.price),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.shopName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// --- TAMPILAN WISHLIST KOSONG DENGAN DESAIN BARU ---
class EmptyWishlistBody extends StatelessWidget {
  const EmptyWishlistBody({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF667EEA);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'Wishlist Anda Masih Kosong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ayo, tambahkan produk impianmu ke sini dengan menekan tombol hati di halaman toko!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Silakan pindah ke tab "Shop" untuk berbelanja.'),
                    backgroundColor: primaryColor,
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Mulai Belanja'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
