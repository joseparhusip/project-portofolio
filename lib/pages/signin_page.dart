// lib/pages/signin_page.dart (Lengkap & Diperbaiki)

import 'package:flutter/material.dart';
import 'signup_page.dart';
import '../api/api_service.dart';
import '../models/user_model.dart';
import 'main_navigator_page.dart';
import '../routes/app_routes.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _emailErrorText;
  String? _passwordErrorText;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    bool isFormValid = true;

    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
    });

    if (email.isEmpty) {
      _emailErrorText = 'Please enter your email';
      isFormValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _emailErrorText = 'Please enter a valid email';
      isFormValid = false;
    }

    if (password.isEmpty) {
      _passwordErrorText = 'Please enter your password';
      isFormValid = false;
    }

    // This setState call triggers a rebuild to show potential validation errors
    setState(() {});

    if (isFormValid) {
      setState(() {
        _isLoading = true;
      });

      final result = await _apiService.login(email, password);

      if (!mounted) return;

      if (result['status'] == 'success') {
        final user = User.fromJson(result['data']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login berhasil! Selamat datang ${user.name}.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to MainNavigatorPage so footer and AppBar appear
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigatorPage(user: user),
          ),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Terjadi kesalahan.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    const maxLogoSize = 250.0;
    const minLogoSize = 150.0;

    // --- [PERBAIKAN UTAMA DI SINI] ---
    // Menambahkan tanda kurung untuk memastikan urutan kalkulasi benar.
    final finalLogoSize = (screenWidth * 0.5).clamp(minLogoSize, maxLogoSize);

    const primaryColor = Color(0xFF36067e);
    const accentColor = Color(0xFF667EEA);

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08,
              vertical: 24.0,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: finalLogoSize,
                      height: finalLogoSize * 0.7,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/trivo.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey[400],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.white70,
                            ),
                            hintText: 'test@gmail.com',
                            hintStyle: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.white54,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: accentColor,
                              size: screenWidth * 0.05,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: accentColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white
                                .withAlpha(26), // Slightly transparent
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: screenHeight * 0.022,
                            ),
                          ),
                        ),
                        Container(
                          height: 24,
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _emailErrorText ?? '',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: screenWidth * 0.03,
                            ),
                          ),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.white70,
                            ),
                            hintText: 'test123',
                            hintStyle: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.white54,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: accentColor,
                              size: screenWidth * 0.05,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white70,
                                size: screenWidth * 0.05,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: accentColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white.withAlpha(26),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: screenHeight * 0.022,
                            ),
                          ),
                        ),
                        Container(
                          height: 24,
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _passwordErrorText ?? '',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: screenWidth * 0.03,
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value!;
                                    });
                                  },
                                  activeColor: accentColor,
                                  checkColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.forgotPassword);
                            },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: screenWidth * 0.035,
                                decoration: TextDecoration.underline,
                                decorationColor: accentColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: screenWidth * 0.06,
                                height: screenWidth * 0.06,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToSignUp,
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
