import 'package:flutter/material.dart';
import '../api/api_service.dart'; // <-- Impor ApiService

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  // Controller diubah sesuai permintaan
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Variabel error text diubah
  String? _nameErrorText;
  String? _usernameErrorText;
  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confirmPasswordErrorText;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Inisialisasi ApiService
  final ApiService _apiService = ApiService(); // <-- Buat instance ApiService

  // Warna konsisten dengan halaman lain
  static const primaryColor = Color(0xFF36067e);
  static const accentColor = Color(0xFF667EEA);

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
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    final name = _nameController.text;
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    bool isFormValid = true;

    setState(() {
      _nameErrorText = null;
      _usernameErrorText = null;
      _emailErrorText = null;
      _passwordErrorText = null;
      _confirmPasswordErrorText = null;
    });

    if (name.isEmpty) {
      _nameErrorText = 'Please enter your name';
      isFormValid = false;
    }
    if (username.isEmpty) {
      _usernameErrorText = 'Please enter your username';
      isFormValid = false;
    }
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
    } else if (password.length < 6) {
      _passwordErrorText = 'Password must be at least 6 characters';
      isFormValid = false;
    }
    if (confirmPassword.isEmpty) {
      _confirmPasswordErrorText = 'Please confirm your password';
      isFormValid = false;
    } else if (password != confirmPassword) {
      _confirmPasswordErrorText = 'Passwords do not match';
      isFormValid = false;
    }

    setState(() {});

    if (isFormValid) {
      setState(() {
        _isLoading = true;
      });

      // --- Panggil API untuk registrasi ---
      final result =
          await _apiService.register(name, username, email, password);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Tampilkan pesan berdasarkan respons dari API
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Kembali ke halaman sign in
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'An unknown error occurred.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- Sisa kode build dan _buildTextField tetap sama ---
  // (Tidak perlu diubah, jadi saya tidak menuliskannya lagi di sini untuk keringkasan)

  @override
  Widget build(BuildContext context) {
    // ... kode build yang ada di file Anda
    // Salin dan tempel semua yang ada di dalam fungsi build() dari file asli Anda ke sini
    // Tidak ada yang perlu diubah di dalamnya
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

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
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Sign Up',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.08,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Name',
                      hintText: 'Jose Elio Parhusip',
                      icon: Icons.person_outline,
                      errorText: _nameErrorText,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTextField(
                      controller: _usernameController,
                      labelText: 'Username',
                      hintText: 'joseelio123',
                      icon: Icons.person_pin_outlined,
                      errorText: _usernameErrorText,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'johndoe@xyz.com',
                      icon: Icons.email_outlined,
                      errorText: _emailErrorText,
                      keyboardType: TextInputType.emailAddress,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: '••••••••••••••••',
                      icon: Icons.lock_outline,
                      errorText: _passwordErrorText,
                      obscureText: _obscurePassword,
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
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: '••••••••••••••••',
                      icon: Icons.lock_outline,
                      errorText: _confirmPasswordErrorText,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                          size: screenWidth * 0.05,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
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
                                'Sign Up',
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
                          "Already have an account? ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Sign In',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required String? errorText,
    required double screenWidth,
    required double screenHeight,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    // ... kode _buildTextField yang ada di file Anda
    // Salin dan tempel semua yang ada di dalam fungsi _buildTextField() dari file asli Anda ke sini
    // Tidak ada yang perlu diubah di dalamnya
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.white),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.white70,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.white54,
            ),
            prefixIcon: Icon(
              icon,
              color: accentColor,
              size: screenWidth * 0.05,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentColor, width: 2),
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
            errorText ?? '',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: screenWidth * 0.03,
            ),
          ),
        )
      ],
    );
  }
}
