import 'package:flutter/material.dart';
import '../pages/splash_screen.dart';
import '../pages/signin_page.dart';
import '../pages/signup_page.dart';
import '../pages/password_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String signin = '/signin';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case signin:
        return MaterialPageRoute(builder: (_) => const SignInPage());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const PasswordPage());
      // case dashboard: // Komentari atau hapus case ini
      //   return MaterialPageRoute(builder: (_) => const DashboardPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
