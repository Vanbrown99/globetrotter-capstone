import 'package:flutter/material.dart';
import 'package:globetrotter_flutter/screens/home_screen.dart';
import 'package:globetrotter_flutter/screens/login_screen.dart';
import 'package:globetrotter_flutter/screens/register_screen.dart';

class AppRoutes {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/login':
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
