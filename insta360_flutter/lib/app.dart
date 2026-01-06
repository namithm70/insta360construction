import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/home/presentation/pages/insta360_home_page.dart';

class Insta360App extends StatelessWidget {
  const Insta360App({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0C8B7D),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Insta360 Connect',
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme),
        scaffoldBackgroundColor: const Color(0xFFF6F3EE),
        cardTheme: CardThemeData(
          color: const Color(0xFFFDFBF7),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE4DED5)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1EEE8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0DAD0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0DAD0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const Insta360Home(),
    );
  }
}
