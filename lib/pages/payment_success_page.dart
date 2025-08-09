import 'package:flutter/material.dart';
import '../models/user_model.dart';
// --- MODIFICATION HERE ---
// Import MainNavigatorPage as the main destination page
import 'main_navigator_page.dart';

class PaymentSuccessPage extends StatelessWidget {
  final User user;
  const PaymentSuccessPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your order has been received and will be processed shortly after payment confirmation by admin.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // --- MODIFICATION HERE ---
                  // Navigate to MainNavigatorPage with History tab selected (index 2)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => MainNavigatorPage(
                        user: user,
                        initialIndex: 2, // Set to History tab (index 2)
                      ),
                    ),
                    (Route<dynamic> route) => false, // Remove all routes
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text('View Order History'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
