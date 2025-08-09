import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../models/user_model.dart'; // <-- TAMBAHKAN
import '../api/api_service.dart';
import './product_detail_page.dart';

class ShopPage extends StatefulWidget {
  final User user; // <-- UBAH
  const ShopPage({super.key, required this.user}); // <-- UBAH

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final ApiService _apiService = ApiService();
  Future<List<Product>>? _productsFuture;
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<String> _selectedCategories = [];
  static const double _minPrice = 0;
  static const double _maxPrice = 5000000;
  RangeValues _currentPriceRange = const RangeValues(_minPrice, _maxPrice);

  Set<int> _wishlistProductIds = {};

  @override
  void initState() {
    super.initState();
    _fetchProductsAndWishlist();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchProductsAndWishlist() async {
    final wishlistIds = await _apiService.getWishlistProductIds(widget.user.userId); // <-- UBAH
    if (mounted) {
      setState(() {
        _wishlistProductIds = wishlistIds;
      });
    }

    final productsFuture = _apiService.getShopProducts(
      query: _searchController.text,
      categories: _selectedCategories,
      minPrice: _currentPriceRange.start,
      maxPrice: _currentPriceRange.end,
    );

    setState(() {
      _productsFuture = productsFuture.then((products) {
        for (var product in products) {
          product.isFavorite = _wishlistProductIds.contains(product.productId);
        }
        return products;
      });
    });
  }

  void _fetchProducts() {
    _fetchProductsAndWishlist();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchProducts();
    });
  }

  Future<void> _handleRefresh() async {
    _searchController.clear();
    setState(() {
      _selectedCategories = [];
      _currentPriceRange = const RangeValues(_minPrice, _maxPrice);
    });
    _fetchProducts();
  }

  Future<void> _handleWishlistToggle(Product product) async {
    final originalIsFavorite = product.isFavorite;
    setState(() {
      product.isFavorite = !product.isFavorite;
      if (product.isFavorite) {
        _wishlistProductIds.add(product.productId);
      } else {
        _wishlistProductIds.remove(product.productId);
      }
    });

    try {
      final response = await _apiService.toggleWishlist(
        userId: widget.user.userId, // <-- UBAH
        productId: product.productId,
      );
      if (response['status'] != 'success' && mounted) {
        setState(() {
          product.isFavorite = originalIsFavorite;
          if (originalIsFavorite) {
            _wishlistProductIds.add(product.productId);
          } else {
            _wishlistProductIds.remove(product.productId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal memperbarui wishlist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          product.isFavorite = originalIsFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFiltersAndDismiss() {
    Navigator.pop(context);
    _fetchProducts();
  }

  void _resetFiltersAndDismiss(StateSetter setModalState) {
    setModalState(() {
      _selectedCategories = [];
      _currentPriceRange = const RangeValues(_minPrice, _maxPrice);
    });
    setState(() {
      _selectedCategories = [];
      _currentPriceRange = const RangeValues(_minPrice, _maxPrice);
    });
    Navigator.pop(context);
    _fetchProducts();
  }

  void _showFilterBottomSheet() {
    List<String> tempCategories = List.from(_selectedCategories);
    RangeValues tempPriceRange = _currentPriceRange;

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final List<String> categories = [
              'Elektronik',
              'Pakaian',
              'Makanan & Minuman',
              'Aksesoris',
              'Peralatan Rumah Tangga'
            ];
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter Produk',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF667EEA))),
                        IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1),
                    Text('Kategori',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: categories.map((category) {
                        final isSelected = tempCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: const Color(0xFF667EEA),
                          labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.w500),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF667EEA)
                                    : Colors.grey[400]!),
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                tempCategories.add(category);
                              } else {
                                tempCategories.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text('Harga',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    RangeSlider(
                      values: tempPriceRange,
                      min: _minPrice, max: _maxPrice,
                      divisions: 50,
                      labels: RangeLabels(
                        currencyFormatter.format(tempPriceRange.start),
                        currencyFormatter.format(tempPriceRange.end),
                      ),
                      activeColor: const Color(0xFF667EEA),
                      onChanged: (RangeValues newValues) {
                        setModalState(() {
                          tempPriceRange = newValues;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(currencyFormatter.format(tempPriceRange.start),
                              style: const TextStyle(fontSize: 14)),
                          Text(currencyFormatter.format(tempPriceRange.end),
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategories = tempCategories;
                            _currentPriceRange = tempPriceRange;
                          });
                          _applyFiltersAndDismiss();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        child: const Text('Terapkan Filter',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _resetFiltersAndDismiss(setModalState),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFF667EEA)),
                        ),
                        child: const Text('Reset Filter',
                            style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF667EEA),
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleAddToCart(Product product) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
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
        userId: widget.user.userId, // <-- UBAH
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

  Widget _buildSearchBarContent() {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama produk atau kategori...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Color(0xFF667EEA)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF667EEA);
    const wishlistColor = Colors.pinkAccent;

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 8.0),
          child: Row(
            children: [
              Expanded(child: _buildSearchBarContent()),
              IconButton(
                icon:
                    const Icon(Icons.filter_list, color: accentColor, size: 28),
                onPressed: _showFilterBottomSheet,
              ),
            ],
          ),
        ),
      ),
      body: Material(
        color: Colors.grey[100],
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: accentColor,
          child: FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: accentColor));
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Gagal memuat produk: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center));
              }

              final products = snapshot.data;
              if (products == null || products.isEmpty) {
                return LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                          child: Text('Produk tidak ditemukan.',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16))),
                    ),
                  );
                });
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        borderRadius: BorderRadius.circular(12)),
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
                            ));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Hero(
                                    tag: 'product_image_${product.productId}',
                                    child: product.imageUrl.isNotEmpty
                                        ? Image.network(
                                            product.imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                    progress) =>
                                                progress == null
                                                    ? child
                                                    : const Center(
                                                        child:
                                                            CircularProgressIndicator(
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
                                                    Icons.image_not_supported,
                                                    color: Colors.grey,
                                                    size: 40)),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Material(
                                    color: Colors.black.withAlpha(100), // <-- UBAH
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: () =>
                                          _handleWishlistToggle(product),
                                      customBorder: const CircleBorder(),
                                      splashColor:
                                          wishlistColor.withAlpha(128), // <-- UBAH
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Icon(
                                          product.isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: product.isFavorite
                                              ? wishlistColor
                                              : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Material(
                                    color: accentColor,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    child: InkWell(
                                      splashColor: Colors.white24,
                                      customBorder: const CircleBorder(),
                                      onTap: () => _handleAddToCart(product),
                                      child: const SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: Icon(Icons.add,
                                            color: Colors.white, size: 20),
                                      ),
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
                                        color: Colors.grey[600], fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormatter.format(product.price),
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
    );
  }
}
