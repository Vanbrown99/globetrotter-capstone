import 'package:flutter/material.dart';
import 'package:globetrotter_flutter/helpers/routes.dart';

void main() {
  runApp(const GlobeTrotterApp());
}

class GlobeTrotterApp extends StatelessWidget {
  const GlobeTrotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    return MaterialApp(
      title: 'GlobeTrotter Yaoundé',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surfaceContainerHighest,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          iconTheme: IconThemeData(color: colorScheme.onPrimary),
          surfaceTintColor: colorScheme.primary,
          titleTextStyle: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ),
      initialRoute: '/login',
      onGenerateRoute: AppRoutes.generate,
      debugShowCheckedModeBanner: false,
    );
  }
}
