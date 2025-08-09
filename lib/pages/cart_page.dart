import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/cart_model.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';

// Import product detail page, seller page, and new checkout page
import 'product_detail_page.dart';
import 'seller_detail_page.dart';
import 'shopping_cart_page.dart';

class CartPage extends StatefulWidget {
  final User user;
  const CartPage({super.key, required this.user});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ApiService _apiService = ApiService();

  // --- State Management ---
  Cart? _cart;
  Map<String, List<CartItem>> _groupedItems = {};
  final Set<int> _selectedItems = {};
  bool _isLoading = true;
  String? _error;

  // --- Theme Color Palette ---
  static const Color primaryColor = Color(0xFF667EEA);
  static const Color accentColor = Color(0xFF667EEA);

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final cartData = await _apiService.getCart(widget.user.userId);
      _groupCartItems(cartData.items);
      setState(() {
        _cart = cartData;
        _isLoading = false;
        _selectedItems.removeWhere((itemId) =>
            !_cart!.items.any((cartItem) => cartItem.cartItemId == itemId));
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to load cart. Please try again.";
      });
    }
  }

  void _groupCartItems(List<CartItem> items) {
    setState(() {
      _groupedItems = groupBy(items, (CartItem item) => item.shopName);
    });
  }

  // --- Cart Logic Functions ---
  void _onItemSelect(bool? isSelected, CartItem item) {
    setState(() {
      if (isSelected == true) {
        _selectedItems.add(item.cartItemId);
      } else {
        _selectedItems.remove(item.cartItemId);
      }
    });
  }

  void _onSelectAll(bool? isSelected) {
    setState(() {
      if (isSelected == true && _cart != null) {
        _selectedItems.addAll(_cart!.items.map((item) => item.cartItemId));
      } else {
        _selectedItems.clear();
      }
    });
  }

  Future<void> _updateQuantity(int cartItemId, String type) async {
    try {
      await _apiService.updateCartQuantity(cartItemId: cartItemId, type: type);
      await _fetchCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update quantity: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeItem(int cartItemId, String productName) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content:
            Text('Are you sure you want to remove "$productName" from cart?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _selectedItems.remove(cartItemId);
      });
      try {
        await _apiService.removeFromCart(cartItemId: cartItemId);
        await _fetchCart();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item successfully removed.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to remove item: ${e.toString()}'),
                backgroundColor: Colors.red),
          );
          await _fetchCart();
        }
      }
    }
  }

  double _calculateSelectedTotal() {
    if (_cart == null) return 0;
    return _cart!.items
        .where((item) => _selectedItems.contains(item.cartItemId))
        .fold(0, (total, item) => total + (item.price * item.quantity));
  }

  String _formatCurrency(double amount) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final bool areAllItemsSelected = _cart != null &&
        _cart!.items.isNotEmpty &&
        _selectedItems.length == _cart!.items.length;
    final double selectedTotal = _calculateSelectedTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart (${_cart?.items.length ?? 0})'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_cart != null && _cart!.items.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: areAllItemsSelected,
                  onChanged: _onSelectAll,
                  activeColor: primaryColor,
                  checkColor: Colors.white,
                ),
                const Text(
                  "All",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
                const SizedBox(width: 8),
              ],
            ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: _buildBody(),
      bottomNavigationBar: _buildBottomSummaryAndCheckout(selectedTotal),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryColor));
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_cart == null || _cart!.items.isEmpty) {
      return _buildEmptyCartView();
    }
    final shopNames = _groupedItems.keys.toList();

    return RefreshIndicator(
      onRefresh: _fetchCart,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: shopNames.length,
        itemBuilder: (context, index) {
          final shopName = shopNames[index];
          final itemsInShop = _groupedItems[shopName]!;
          return _buildSellerGroupCard(shopName, itemsInShop);
        },
      ),
    );
  }

  Widget _buildSellerGroupCard(String shopName, List<CartItem> items) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSellerHeader(shopName, items.first.sellerId),
          Column(
            children: items.map((item) => _buildCartItemCard(item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerHeader(String shopName, int sellerId) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellerDetailPage(
              sellerId: sellerId,
              user: widget.user, // <-- FIX
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined,
                color: Colors.black54, size: 20),
            const SizedBox(width: 8),
            Text(
              shopName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCartView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Your cart is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Come on, fill it with your dream items!',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final bool isSelected = _selectedItems.contains(item.cartItemId);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productId: item.productId,
              user: widget.user,
            ),
          ),
        );
      },
      child: Container(
        color: isSelected ? accentColor.withAlpha(13) : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (bool? value) => _onItemSelect(value, item),
              activeColor: accentColor,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.productName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatCurrency(item.price),
                      style: const TextStyle(
                          color: accentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildQuantityController(item),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () =>
                              _removeItem(item.cartItemId, item.productName),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityController(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () => _updateQuantity(item.cartItemId, 'decrease'),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('${item.quantity}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => _updateQuantity(item.cartItemId, 'increase'),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummaryAndCheckout(double selectedTotal) {
    if (_isLoading || _cart == null || _cart!.items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total ', style: TextStyle(fontSize: 16)),
                    Flexible(
                      child: Text(
                        _formatCurrency(selectedTotal),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                if (_selectedItems.isNotEmpty)
                  Text(
                    '${_selectedItems.length} products selected',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _selectedItems.isEmpty
                ? null
                : () {
                    final List<CartItem> selectedCartItems = _cart!.items
                        .where(
                            (item) => _selectedItems.contains(item.cartItemId))
                        .toList();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShoppingCartPage(
                          selectedItems: selectedCartItems,
                          user: widget.user,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text('Checkout (${_selectedItems.length})'),
          ),
        ],
      ),
    );
  }
}
