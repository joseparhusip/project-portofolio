// lib/intro_page.dart

import 'package:flutter/material.dart';
import 'signin_page.dart'; // Impor halaman sign-in

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  // Fungsi untuk navigasi ke SignInPage
  void _navigateToSignIn(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignInPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan skema warna yang konsisten dengan welcome_page.dart
    const Color primaryColor = Color(0xFF36067e);
    const Color gradientEndColor = Color(0xFF5b2a9d);

    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang utama putih
      body: Column(
        children: [
          // Bagian atas dengan gambar
          Expanded(
            flex: 5, // Memberi lebih banyak ruang untuk gambar
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.75, // Ukuran gambar sedikit lebih besar
                  child: Image.asset(
                    'assets/logo-2.png', // Path gambar diperbarui sesuai permintaan
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Pengganti jika aset gambar gagal dimuat
                      return const Icon(
                        Icons.shopping_bag_outlined,
                        size: 150,
                        color: primaryColor,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Bagian bawah dengan teks dan tombol, menggunakan gradien ungu
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, gradientEndColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Konten Teks
                  const Text(
                    'Discover & Shop on Trivo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Find everything you need, from electronics to fashion, all in one place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Tombol Navigasi
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end, // DIUBAH: Tombol ke kanan
                    children: [
                      // Tombol Lanjutkan
                      ElevatedButton(
                        onPressed: () => _navigateToSignIn(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // Tombol putih
                          foregroundColor: primaryColor, // Ikon ungu
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          elevation: 5,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
