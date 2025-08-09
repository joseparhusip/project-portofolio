import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/cart_model.dart';
import '../models/user_model.dart'; // <-- ADDED: Import User Model
import '../api/api_service.dart';
import 'payment_success_page.dart';

class PaymentPage extends StatefulWidget {
  // --- CHANGED: Accept User object, not just userId ---
  final User user;
  final List<CartItem> selectedItems;
  final double subtotal;
  final double total;
  final double tax;

  const PaymentPage({
    super.key,
    required this.user, // <-- CHANGED
    required this.selectedItems,
    required this.subtotal,
    required this.total,
    required this.tax,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  File? _paymentProofImage;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _paymentProofImage = File(pickedFile.path);
      });
    }
  }

  String _formatCurrency(double amount) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  void _submitOrder() async {
    // Add 'mounted' check before using context
    if (!mounted) return;

    if (_paymentProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload payment proof first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _apiService.createOrder(
      // --- CHANGED: Use userId from user object ---
      userId: widget.user.userId,
      items: widget.selectedItems,
      subtotal: widget.subtotal,
      tax: widget.tax,
      total: widget.total,
      paymentProof: _paymentProofImage!,
    );

    // --- ADDED: 'mounted' check after await ---
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      Navigator.of(context).pushAndRemoveUntil(
        // --- CHANGED: Provide required 'user' argument ---
        MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(user: widget.user)),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: ${result['message']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Bill:',
                            style: TextStyle(fontSize: 18)),
                        Text(
                          _formatCurrency(widget.total),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667EEA)), // Accent color
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Please transfer to the following account:',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'BCA: 123-456-7890\na.n. Trivo',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Payment Proof',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
                child: _paymentProofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            Image.file(_paymentProofImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to select image'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA), // Accent color
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                    )
                  : const Text('Send and Complete Order',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
