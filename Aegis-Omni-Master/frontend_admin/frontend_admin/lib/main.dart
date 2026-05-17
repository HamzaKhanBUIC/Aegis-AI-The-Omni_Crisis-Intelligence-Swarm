import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: AegisCommandCenter()));
}

class AegisCommandCenter extends StatelessWidget {
  const AegisCommandCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aegis-Sovereign Command Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // Pitch Black background
        primaryColor: const Color(0xFF00E5FF), // Cyber Neon Blue
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          surface: Color(0xFF0F172A), // Dark Slate
          error: Color(0xFFFF3366), // Warning Crimson
          secondary: Color(0xFF00FF66), // Safe Emerald
        ),
        // Applying the high-tech terminal font across the entire app
        textTheme: GoogleFonts.firaCodeTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyLarge: const TextStyle(color: Color(0xFF00E5FF)),
          bodyMedium: const TextStyle(color: Colors.white70),
        ),
      ),
      home: const AdminDashboard(),
    );
  }
}
