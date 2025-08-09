// lib/welcome_page.dart

import 'package:flutter/material.dart';
import 'intro_page.dart'; // DIUBAH: Impor halaman intro baru

// Dikonversi menjadi StatefulWidget untuk mendukung animasi
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // DIUBAH: Navigasi ke IntroPage dengan transisi geser
  void _navigateToIntro(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const IntroPage(), // DIUBAH: Arahkan ke IntroPage
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Transisi geser dari kanan ke kiri
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
    // Definisikan warna utama baru untuk digunakan kembali
    const Color primaryColor = Color(0xFF36067e);
    const Color gradientEndColor = Color(0xFF5b2a9d);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Bagian atas untuk gambar
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.7, // Sesuaikan ukuran gambar
                  child: Image.asset(
                    'assets/logo-1.png', // Aset gambar Anda
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Pengganti jika aset gambar gagal dimuat
                      return const Icon(
                        Icons.school,
                        size: 100,
                        color: primaryColor,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Bagian bawah dengan detail dan tombol lanjutkan
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
              child: Stack(
                children: [
                  // Elemen dekoratif
                  Positioned(
                    top: -50,
                    left: -50,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white.withAlpha(13),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    right: -60,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withAlpha(20),
                    ),
                  ),
                  // Konten utama
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Welcome to Trivo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black26,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'The ultimate e-commerce platform for all your student needs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      // Tombol Lanjutkan
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _navigateToIntro(
                              context), // DIUBAH: Panggil navigasi ke intro
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black.withAlpha(102),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
