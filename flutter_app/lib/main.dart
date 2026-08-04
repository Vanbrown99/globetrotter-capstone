import 'package:flutter/material.dart';
import 'package:globetrotter_flutter/helpers/routes.dart';
import 'package:globetrotter_flutter/theme/app_theme.dart';

void main() {
  runApp(const GlobeTrotterApp());
}

class GlobeTrotterApp extends StatelessWidget {
  const GlobeTrotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlobeTrotter Yaoundé',
      theme: AppTheme.theme,
      initialRoute: '/login',
      onGenerateRoute: AppRoutes.generate,
      debugShowCheckedModeBanner: false,
    );
  }
}
