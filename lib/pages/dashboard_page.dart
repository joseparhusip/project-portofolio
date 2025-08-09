import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/slider_model.dart';
import '../api/api_service.dart';
import './product_detail_page.dart';

class DashboardPage extends StatefulWidget {
  final User user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  Future<List<Product>>? _productsFuture;
  Future<List<SliderModel>>? _slidersFuture;

  final _searchController = TextEditingController();
  Timer? _debounce;

  // Untuk PageView slider
  late PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _pageController.dispose();
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  void _fetchData({String query = ''}) {
    setState(() {
      _slidersFuture = _apiService.getSliders();
      _productsFuture = _apiService.getProducts(query: query);
    });
  }

  void _fetchProducts({String query = ''}) {
    setState(() {
      _productsFuture = _apiService.getProducts(query: query);
    });
  }

  Future<void> _handleRefresh() async {
    _searchController.clear();
    _fetchData();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchProducts(query: _searchController.text);
    });
  }

  void _startAutoSlide(int itemCount) {
    if (itemCount == 0) return;
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      int nextPage = (_currentIndex + 1) % itemCount;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _handleAddToCart(Product product) async {
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
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama produk atau kategori...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
            child: Icon(Icons.search),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildImageSlider(List<SliderModel> sliders) {
    if (sliders.isEmpty) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide(sliders.length);
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 2.7,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: sliders.length,
              itemBuilder: (context, index) {
                final slider = sliders[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      slider.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) => progress ==
                              null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey, size: 40)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              sliders.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? const Color(0xFF667EEA)
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF667EEA);
    return Material(
      color: Colors.grey[100],
      child: Column(
        children: [
          _buildSearchBar(),
          FutureBuilder<List<SliderModel>>(
            future: _slidersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  margin: const EdgeInsets.only(
                      bottom: 16.0, left: 16.0, right: 16.0),
                  child: AspectRatio(
                    aspectRatio: 2.7,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                );
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildImageSlider(snapshot.data!);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _productsFuture != null) {
                    return const Center(
                        child: CircularProgressIndicator(color: accentColor));
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Gagal memuat produk: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text(_searchController.text.isEmpty
                            ? 'Belum ada produk.'
                            : 'Produk tidak ditemukan.'));
                  }
                  final products = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
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
                                  // --- PERUBAHAN DI SINI ---
                                  user: widget.user,
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
                                        tag:
                                            'product_image_${product.productId}',
                                        child: product.imageUrl.isNotEmpty
                                            ? Image.network(
                                                product.imageUrl,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child,
                                                        progress) =>
                                                    progress == null
                                                        ? child
                                                        : const Center(
                                                            child: CircularProgressIndicator(
                                                                color:
                                                                    accentColor)),
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Center(
                                                        child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey,
                                                            size: 40)),
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                    child: Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey,
                                                        size: 40)),
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
                                          onPressed: () =>
                                              _handleAddToCart(product),
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
                                    Text(product.productName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(product.categoryName,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
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
                                          color: product.stock > 0
                                              ? Colors.grey[700]
                                              : Colors.red,
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
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
