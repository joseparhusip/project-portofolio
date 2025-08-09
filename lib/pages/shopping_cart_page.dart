import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart_model.dart';
import '../models/user_model.dart'; // <-- TAMBAHKAN: Import User Model
import 'payment_page.dart';

class ShoppingCartPage extends StatelessWidget {
  final List<CartItem> selectedItems;
  // --- UBAH: Terima objek User, bukan hanya userId ---
  final User user;

  const ShoppingCartPage({
    super.key,
    required this.selectedItems,
    required this.user, // <-- UBAH
  });

  static const double taxAmount = 1500;

  String _formatCurrency(double amount) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  double _calculateSubtotal() {
    return selectedItems.fold(
        0, (total, item) => total + (item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal = _calculateSubtotal();
    final double finalTotal = subtotal + taxAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Summary'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Expanded(
            child: selectedItems.isEmpty
                ? const Center(
                    child: Text(
                      'Your cart is empty.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = selectedItems[index];
                      return _buildCheckoutItemCard(item);
                    },
                  ),
          ),
          _buildSummarySection(subtotal, finalTotal),
        ],
      ),
      bottomNavigationBar:
          _buildBottomCheckoutButton(context, subtotal, finalTotal),
    );
  }

  Widget _buildCheckoutItemCard(CartItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} x ${_formatCurrency(item.price)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatCurrency(item.quantity * item.price),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF667EEA), // Warna aksen
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(double subtotal, double finalTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price (${selectedItems.length} Products)',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              Text(
                _formatCurrency(subtotal),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Fee (Tax)',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              Text(
                _formatCurrency(taxAmount),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Bill',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatCurrency(finalTotal),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667EEA), // Warna aksen
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutButton(
      BuildContext context, double subtotal, double finalTotal) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ElevatedButton(
        onPressed: () {
          if (selectedItems.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentPage(
                  // --- UBAH: Kirim objek 'user' lengkap ---
                  user: user,
                  selectedItems: selectedItems,
                  subtotal: subtotal,
                  total: finalTotal,
                  tax: taxAmount,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot proceed to payment, your cart is empty.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA), // Warna aksen
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: const Text('Pay Now'),
      ),
    );
  }
}
