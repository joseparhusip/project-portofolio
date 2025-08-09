import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'welcome_page.dart'; // PASTIKAN: File ini ada di proyek Anda.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Deklarasi semua controller dan animasi tidak berubah.
  late AnimationController _scaleController;
  late AnimationController _flipController;
  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late AnimationController _loadingController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _backgroundAnimation;
  // DIHAPUS: _loadingRotation tidak lagi diperlukan
  // late Animation<double> _loadingRotation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  bool _showLoading = false;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();

    // Inisialisasi semua controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Definisi semua animasi
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _flipAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _backgroundAnimation = ColorTween(
      begin: Colors.white,
      end: const Color(0xFFF8F9FF),
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    // DIHAPUS: Animasi rotasi tidak lagi digunakan
    // _loadingRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
    //   CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    // );
    _particleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    _backgroundController.forward();
    _pulseController.repeat(reverse: true);
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _fadeController.forward();
    setState(() {
      _showParticles = true;
    });
    _particleController.repeat();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _flipController.forward().then((_) {
      if (mounted) {
        _flipController.reverse();
      }
    });

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() {
      _showLoading = true;
    });
    _loadingController
        .repeat(); // Controller ini sekarang menggerakkan loader baru

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    _navigateToNextPage();
  }

  void _navigateToNextPage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _flipController.dispose();
    _fadeController.dispose();
    _backgroundController.dispose();
    _loadingController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildParticle(double delay, double size, Color color) {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        final adjustedAnimation = (_particleAnimation.value + delay) % 1.0;
        return Positioned(
          left: 50 +
              (MediaQuery.of(context).size.width - 100) *
                  (math.sin(adjustedAnimation * 2 * math.pi + delay * 4) + 1) /
                  2,
          top: 100 +
              (MediaQuery.of(context).size.height - 200) *
                  (math.cos(adjustedAnimation * 2 * math.pi + delay * 3) + 1) /
                  2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withAlpha(
                  ((0.3 + 0.4 * math.sin(adjustedAnimation * math.pi)) * 255)
                      .round()),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(77),
                  blurRadius: size / 2,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // [BARU] Widget untuk animasi pemuatan titik berdenyut (pulsing dots)
  Widget _buildPulsingDotLoader() {
    // Helper widget untuk satu titik
    Widget buildDot(double delay) {
      return AnimatedBuilder(
        animation: _loadingController,
        builder: (context, child) {
          // Menggunakan sin untuk membuat osilasi yang mulus
          final scale = 0.6 +
              (math.sin((_loadingController.value * 2 * math.pi) + delay) + 1) /
                  5;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: const CircleAvatar(
          radius: 8,
          backgroundColor: Color(0xFF3F51B5),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildDot(0),
        const SizedBox(width: 16),
        buildDot(math.pi / 2),
        const SizedBox(width: 16),
        buildDot(math.pi),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundAnimation.value ?? Colors.white,
                  Colors.white,
                  const Color(0xFFF0F2FF),
                ],
              ),
            ),
            child: Stack(
              children: [
                if (_showParticles) ...[
                  _buildParticle(0.0, 6, const Color(0xFF3F51B5)),
                  _buildParticle(0.2, 8, const Color(0xFF9C27B0)),
                  _buildParticle(0.4, 4, const Color(0xFF00BCD4)),
                  _buildParticle(0.6, 10, const Color(0xFF3F51B5)),
                  _buildParticle(0.8, 5, const Color(0xFF9C27B0)),
                ],
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _scaleAnimation,
                          _flipAnimation,
                          _pulseAnimation,
                        ]),
                        builder: (context, child) {
                          final combinedScale =
                              _scaleAnimation.value * _pulseAnimation.value;

                          return Transform.scale(
                            scale: combinedScale,
                            child: Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(_flipAnimation.value),
                              alignment: Alignment.center,
                              child: child,
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 280,
                          height: 120,
                          child: Image.asset(
                            'assets/trivo.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _showLoading
                            ? Column(
                                children: [
                                  // [DIGANTI] Memanggil loader baru
                                  _buildPulsingDotLoader(),
                                  const SizedBox(height: 20),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Text(
                                      'Preparing your experience...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF3F51B5)
                                            .withAlpha(153),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox(
                                height: 88), // Sesuaikan tinggi agar konsisten
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
