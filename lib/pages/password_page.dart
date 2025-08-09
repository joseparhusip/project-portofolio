// lib/pages/password_page.dart (Diperbarui)

import 'package:flutter/material.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _emailErrorText;
  String? _newPasswordErrorText;
  String? _confirmPasswordErrorText;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Warna konsisten dengan halaman lain
  static const primaryColor = Color(0xFF36067e);
  static const accentColor = Color(0xFF667EEA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    final email = _emailController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    bool isFormValid = true;

    setState(() {
      _emailErrorText = null;
      _newPasswordErrorText = null;
      _confirmPasswordErrorText = null;
    });

    if (email.isEmpty) {
      _emailErrorText = 'Please enter your email';
      isFormValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _emailErrorText = 'Please enter a valid email';
      isFormValid = false;
    }

    if (newPassword.isEmpty) {
      _newPasswordErrorText = 'Please enter a new password';
      isFormValid = false;
    } else if (newPassword.length < 6) {
      _newPasswordErrorText = 'Password must be at least 6 characters';
      isFormValid = false;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordErrorText = 'Please confirm your password';
      isFormValid = false;
    } else if (newPassword != confirmPassword) {
      _confirmPasswordErrorText = 'Passwords do not match';
      isFormValid = false;
    }

    setState(() {});

    if (isFormValid) {
      setState(() {
        _isLoading = true;
      });

      // Simulasi panggilan API
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman sebelumnya setelah beberapa saat
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title:
            const Text('Reset Password', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
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
                    // Title
                    Text(
                      'Create New Password',
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Subtitle
                    Text(
                      "Your new password must be different from previous used passwords.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // Email Field
                    _buildTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'johndoe@xyz.com',
                        icon: Icons.email_outlined,
                        errorText: _emailErrorText,
                        keyboardType: TextInputType.emailAddress,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight),

                    // New Password Field
                    _buildTextField(
                      controller: _newPasswordController,
                      labelText: 'New Password',
                      hintText: '••••••••••••••••',
                      icon: Icons.lock_outline,
                      errorText: _newPasswordErrorText,
                      obscureText: _obscureNewPassword,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                          size: screenWidth * 0.05,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),

                    // Confirm Password Field
                    _buildTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: '••••••••••••••••',
                      icon: Icons.lock_outline,
                      errorText: _confirmPasswordErrorText,
                      obscureText: _obscureConfirmPassword,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
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
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Reset Password Button
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
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
                                'Reset Password', // <<< PERUBAHAN DI SINI
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
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

  // Helper widget untuk membangun text field yang konsisten
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
